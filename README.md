###

This project is a simple project to test the 2 Tier Architecture with Terraform, Docker, ECR, MongoDB, IAM and AWS EKS, Github Actions.

## Architecture

### Install Prerequisites

- Terraform - [Install Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- Docker - [Install Docker](https://docs.docker.com/engine/install/)
- AWSCLI - [Install AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- Kubectl - [Install K8s CLI](https://kubernetes.io/docs/tasks/tools/)


- An AWS account and credentials configured (via ~/.aws/credentials, environment variables, or IAM roles)

## Get Started

```
git clone https://github.com/DJENJNY/Wiz-Project.git
cd your-github-repo
```
## Intialize Terraform
```
terraform init
```
## Preview the plan
```
terraform plan
```
## Apply the configuration
```
terraform apply
```
## Configure Local Host to Talk to EKS Cluster
```
aws eks --region us-east-1 update-kubeconfig --name my-cluster;
```
## Update Secrets
- Get IP Address Of MongoDB VM and Update MONGODB_URI

```
echo -n 'mongodb://(private_ip):27017' | base64  
```
- Place Encoded Secret in MONGODB_URI
















