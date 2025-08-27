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
- Get Private IP Address Of MongoDB VM and Update MONGODB_URI

```
echo -n 'mongodb://(mongodb_private_ip):27017' | base64  
```
- Replace new Encoded Secret to MONGODB_URI

## Load Balancer Controller Installation

### Create IAM OIDC Provider
```
eksctl utils associate-iam-oidc-provider \
    --region <region-code> \
    --cluster <your-cluster-name> \
    --approve
```
### Create IAM policy for the AWS Load Balancer Controller
```
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam-policy.json
```

### Create a IAM role and ServiceAccount for the AWS Load Balancer controller, use the ARN from the step above
```
eksctl create iamserviceaccount \
--cluster=<cluster-name> \
--namespace=kube-system \
--name=aws-load-balancer-controller \
--attach-policy-arn=arn:aws:iam::<AWS_ACCOUNT_ID>:policy/AWSLoadBalancerControllerIAMPolicy \
--override-existing-serviceaccounts \
--approve
```
## Add Controller to Cluster

### Add the EKS chart repo to helm
```
helm repo add eks https://aws.github.io/eks-charts
```
### Install the helm chart
```
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=<cluster-name> --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller
```
### Deploy Load Balancer Controllers onto EKS
```
kubectl apply -f ./k8s/ingress.yaml
```
### Deploy The Application
```
kubectl apply -f ./k8s
```




















