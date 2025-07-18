module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "test-module-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a"]
  private_subnets = ["10.0.1.0/24"]
  public_subnets  = ["10.0.2.0/24"]

  enable_nat_gateway = true
  create_igw         = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# Create a Security Group for Mongo VM
resource "aws_security_group" "mongo" {
  name        = "mongo"
  description = "Allow internal access to mongo"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "mongodb"
  }
}

resource "aws_vpc_security_group_ingress_rule" "mongo" {
  security_group_id = aws_security_group.mongo.id
  cidr_ipv4         = module.vpc.vpc_cidr_block
  from_port         = 27017
  ip_protocol       = "tcp"
  to_port           = 27017
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.mongo.id
  cidr_ipv4         = module.vpc.vpc_cidr_block
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "mongo" {
  security_group_id = aws_security_group.mongo.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# Create an EC2 Role and Attach Policy
resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Create Role Policy Attachment
resource "aws_iam_role_policy_attachment" "AmazonSSM_Managed_Instance_Core" {

  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore" # Example policy
}

resource "aws_iam_role_policy_attachment" "s3_read_only_policy" {

  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess" # Example policy
}

# Create IAM Instance Profile
resource "aws_iam_instance_profile" "mongo_ssm" {
  name = "mongo"
  role = aws_iam_role.ec2_role.name
}

# Create Key Pair
resource "aws_key_pair" "mongo_key" {
  key_name   = "mongo-key"
  public_key = file("~/.ssh/id_ed25519.pub") # path to your public key
}

output "ssh_key_name" {
  value = aws_key_pair.mongo_key.key_name
}

# Create Mongo DB VM
resource "aws_instance" "mongo" {
  ami                    = "ami-0150ccaf51ab55a51"  # Ubuntu 20.04 (adjust for your region)
  instance_type          = "t2.micro"
  subnet_id              = module.vpc.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.mongo.id]
  iam_instance_profile   = aws_iam_instance_profile.mongo_ssm.name
  key_name               = aws_key_pair.mongo_key.key_name
  associate_public_ip_address = false
  
  # Bash Script for Mongo DB Install
  user_data = file("${path.module}/mongodb.sh")
  
  tags = {
    Name = "mongo_instance" # Optional: Add tags for easier identification
  }
}

output "mongo_private_ip" {
  value = aws_instance.mongo.private_ip
}








