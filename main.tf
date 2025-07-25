data "aws_availability_zones" "available" {
state = "available"
}

# Networking/VPC
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 5.1"

  name = var.vpc_name
  cidr = var.cidr_block

  azs             = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  private_subnets = [cidrsubnet(var.cidr_block, 8, 1), cidrsubnet(var.cidr_block, 8, 2)]
  public_subnets  = [cidrsubnet(var.cidr_block, 8, 10), cidrsubnet(var.cidr_block, 8, 20)]

  enable_nat_gateway = true
  create_igw         = true

  private_subnet_tags = {
    "kubernetes.io/cluster/my-cluster" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/my-cluster" = "shared"
    "kubernetes.io/role/elb"           = "1"
  }

  tags = var.tags
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

# IAM Roles/Policies
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

# Create Mongo DB VM
resource "aws_instance" "mongo" {
  ami                    = "ami-0150ccaf51ab55a51" # Ubuntu 20.04 (adjust for your region)
  instance_type          = "t2.micro"
  subnet_id              = module.vpc.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.mongo.id]
  iam_instance_profile   = aws_iam_instance_profile.mongo_ssm.name

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

# Kubernetes 
module "eks" {
source  = "terraform-aws-modules/eks/aws"
version = "~> 20.0"

cluster_name    = var.cluster_name
cluster_version = var.eks_version

vpc_id = module.vpc.vpc_id

create_iam_role = true # Default is true
attach_cluster_encryption_policy = false  # Default is true

cluster_endpoint_private_access = true
cluster_endpoint_public_access = true

control_plane_subnet_ids = concat(module.vpc.public_subnets, module.vpc.private_subnets)

create_cluster_security_group = true
cluster_security_group_description = "EKS cluster security group"

bootstrap_self_managed_addons = true

authentication_mode = "API"
enable_cluster_creator_admin_permissions = true

dataplane_wait_duration = "40s"

# some defaults
enable_security_groups_for_pods = true

#override defaults

create_cloudwatch_log_group = false
create_kms_key = false
enable_kms_key_rotation = false
kms_key_enable_default_policy = false
enable_irsa = false 
cluster_encryption_config = {}
enable_auto_mode_custom_tags = false

# EKS Managed Node Group(s)
create_node_security_group = true
node_security_group_enable_recommended_rules = true
node_security_group_description = "EKS node group security group - used by nodes to communicate with the cluster API Server"

node_security_group_use_name_prefix = true

subnet_ids = module.vpc.private_subnets
eks_managed_node_groups = {
    group1 = {
    name         = "wiz-node-group"
    ami_type       = "AL2023_x86_64_STANDARD"
    instance_types = ["t3.medium"]
    capacity_type = "SPOT"
    min_size     = 2
    max_size     = 4
    desired_size = 2
    }
  }
}

# ECR Repo
resource "aws_ecr_repository" "registry" {
  name                 = "ej-registry"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}








