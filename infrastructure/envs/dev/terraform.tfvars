# envs/dev/terraform.tfvars
# Dev environment variable values
# NEVER commit sensitive values — use environment variables or AWS Secrets Manager

aws_region       = "us-east-1"
project_name     = "cicd-demo"
environment      = "dev"
owner            = "your-name"           # CHANGE ME
instance_type    = "t3.micro"
vpc_id           = "vpc-CHANGEME"        # CHANGE ME — find in AWS console > VPC
subnet_id        = "subnet-CHANGEME"     # CHANGE ME — use a public subnet
allowed_ssh_cidr = "YOUR.IP.HERE/32"     # CHANGE ME — curl ifconfig.me to find your IP
github_repo      = "your-username/my-cicd-project"  # CHANGE ME
github_branch    = "main"
alert_email      = "your@email.com"      # CHANGE ME
