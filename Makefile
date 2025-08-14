SHELL=/bin/zsh

launch-controller:
	eksctl utils associate-iam-oidc-provider --region $(REGION) --cluster $(CLUSTER) --approve
	eksctl create iamserviceaccount --cluster=$(CLUSTER) --namespace=kube-system --name=aws-load-balancer-controller --attach-policy-arn=arn:aws:iam::712739085074:policy/AWSLoadBalancerControllerIAMPolicy --override-existing-serviceaccounts --approve
	helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=$(CLUSTER) --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller1




