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


