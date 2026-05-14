# main.tf
# Root module — composes all child modules together
# Think of this as the "director" — it calls the modules and passes data between them

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    # All resources get these tags automatically — real-world best practice
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = var.owner
    }
  }
}

# ─── IAM Module ────────────────────────────────────────────────────────────────
# Creates all IAM roles and policies needed by the pipeline services
module "iam" {
  source = "./modules/iam"

  project_name    = var.project_name
  environment     = var.environment
  artifact_bucket = module.pipeline.artifact_bucket_arn
}

# ─── EC2 Module ────────────────────────────────────────────────────────────────
# Creates the EC2 instance that will host the deployed application
module "ec2" {
  source = "./modules/ec2"

  project_name        = var.project_name
  environment         = var.environment
  instance_type       = var.instance_type
  ec2_instance_profile = module.iam.ec2_instance_profile_name
  vpc_id              = var.vpc_id
  subnet_id           = var.subnet_id
  allowed_ssh_cidr    = var.allowed_ssh_cidr
}

# ─── Pipeline Module ───────────────────────────────────────────────────────────
# Creates CodePipeline, CodeBuild, CodeDeploy, and the S3 artifact bucket
module "pipeline" {
  source = "./modules/pipeline"

  project_name             = var.project_name
  environment              = var.environment
  github_repo              = var.github_repo
  github_branch            = var.github_branch
  codepipeline_role_arn    = module.iam.codepipeline_role_arn
  codebuild_role_arn       = module.iam.codebuild_role_arn
  codedeploy_role_arn      = module.iam.codedeploy_role_arn
  ec2_instance_id          = module.ec2.instance_id
  ec2_autoscaling_group    = null  # Set if using ASG instead of single EC2
}

# ─── Monitoring Module ─────────────────────────────────────────────────────────
# CloudWatch alarms + SNS notifications for pipeline failures
module "monitoring" {
  source = "./modules/monitoring"

  project_name      = var.project_name
  environment       = var.environment
  pipeline_name     = module.pipeline.pipeline_name
  alert_email       = var.alert_email
}
