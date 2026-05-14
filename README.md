# CI/CD Pipeline — AWS Portfolio Project

A production-style CI/CD pipeline on AWS, fully provisioned with Terraform.

## Architecture

```
GitHub Push
    │
    ▼
AWS CodePipeline
    │
    ├─── CodeBuild (build + test)
    │         │
    │         └── S3 (artifacts)
    │
    └─── CodeDeploy ──► EC2 (Node.js app)
                              │
                         CloudWatch + SNS
                         (monitoring & alerts)
```

## AWS Services Used

| Service | Purpose |
|---|---|
| CodePipeline | Orchestrates the pipeline |
| CodeBuild | Runs build & tests |
| CodeDeploy | Deploys to EC2 |
| EC2 | Hosts the application |
| S3 | Stores build artifacts |
| IAM | Least-privilege roles for each service |
| CloudWatch | Logs, dashboards, alarms |
| SNS | Email alerts on failure |
| SSM Parameter Store | Secrets management |
| CodeStar Connections | GitHub integration |

## Real-World Practices Applied

- **Infrastructure as Code** — every AWS resource created by Terraform, zero console clicking
- **Remote Terraform state** — S3 backend with DynamoDB locking for team safety
- **Terraform modules** — reusable, composable infrastructure units
- **Least-privilege IAM** — each service role has only the permissions it needs
- **No hardcoded values** — all config via variables and tfvars
- **Secrets via SSM** — no secrets in code or environment variables
- **Auto-rollback** — CodeDeploy rolls back automatically on failed deployment
- **Health check validation** — deployment only succeeds if `/health` returns 200
- **PR validation** — GitHub Actions runs `terraform validate` on every PR
- **Full tagging strategy** — every resource tagged with Project, Environment, Owner, ManagedBy

## Prerequisites

- AWS CLI configured (`aws configure`)
- Terraform >= 1.5 installed
- Node.js 18+ installed locally
- A GitHub account and repository

## Bootstrap (One-Time Setup)

Before running Terraform, manually create the S3 bucket and DynamoDB table for remote state:

```bash
# Create state bucket (must be globally unique)
aws s3api create-bucket \
  --bucket your-tf-state-bucket-CHANGEME \
  --region us-east-1

# Enable versioning on state bucket
aws s3api put-bucket-versioning \
  --bucket your-tf-state-bucket-CHANGEME \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

Then update `infrastructure/backend.tf` with your bucket name.

## Deploy

```bash
# 1. Fill in your values
cp infrastructure/envs/dev/terraform.tfvars infrastructure/envs/dev/terraform.tfvars.local
# Edit terraform.tfvars.local with your VPC ID, subnet, IP, GitHub repo, etc.

# 2. Initialize Terraform
cd infrastructure
terraform init

# 3. Preview changes
terraform plan -var-file=envs/dev/terraform.tfvars

# 4. Apply
terraform apply -var-file=envs/dev/terraform.tfvars

# 5. Note the outputs
# ec2_public_ip, pipeline_name, app_url
```

After applying, go to **AWS Console → CodeConnections** and authorize the GitHub connection (one-time manual step).

## Triggering the Pipeline

```bash
# Any push to main triggers the pipeline automatically
git add .
git commit -m "feat: trigger pipeline"
git push origin main
```

Watch the pipeline at: **AWS Console → CodePipeline → cicd-demo-dev-pipeline**

## Testing a Rollback

```bash
# Push a deliberately broken change to see auto-rollback
echo "this will break" > app/src/index.js
git add . && git commit -m "break: test rollback" && git push
# Watch CodeDeploy roll back to the last good version
```

## Tear Down

```bash
# Destroys all AWS resources — avoids surprise bills
cd infrastructure
terraform destroy -var-file=envs/dev/terraform.tfvars
```

## Cost Estimate

Running this 24/7 costs approximately **$8–12/month** (mostly EC2 t3.micro). Tear down when not demoing to keep costs near zero.

## Extending This Project

- Add a staging environment using Terraform workspaces
- Replace EC2 with ECS Fargate for containerized deployments
- Add SAST scanning (Checkov or tfsec) to the GitHub Actions workflow
- Implement blue/green deployments with CodeDeploy
- Add an Application Load Balancer in front of EC2
