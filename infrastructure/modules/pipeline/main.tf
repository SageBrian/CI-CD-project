# modules/pipeline/main.tf
# The core CI/CD pipeline — CodePipeline orchestrates CodeBuild + CodeDeploy

# ─── S3 Artifact Bucket ────────────────────────────────────────────────────────
# Stores build artifacts between pipeline stages
resource "aws_s3_bucket" "artifacts" {
  bucket        = "${var.project_name}-${var.environment}-artifacts-${random_id.suffix.hex}"
  force_destroy = true  # Allows terraform destroy to delete even if bucket has objects
}

resource "random_id" "suffix" {
  byte_length = 4  # Makes bucket name globally unique
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  versioning_configuration {
    status = "Enabled"  # Keep artifact history
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"  # Encrypt artifacts at rest
    }
  }
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  # Block all public access — artifacts are internal only
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ─── GitHub Connection ─────────────────────────────────────────────────────────
# CodeStar connection to GitHub — you'll need to authorize this in the AWS console once
resource "aws_codestarconnections_connection" "github" {
  name          = "${var.project_name}-${var.environment}-github"
  provider_type = "GitHub"
}

# ─── CodeBuild Project ─────────────────────────────────────────────────────────
resource "aws_codebuild_project" "app" {
  name          = "${var.project_name}-${var.environment}-build"
  description   = "Builds and tests ${var.project_name} (${var.environment})"
  service_role  = var.codebuild_role_arn
  build_timeout = 10  # Minutes — fail fast

  artifacts {
    type = "CODEPIPELINE"  # Artifacts passed from/to CodePipeline
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"  # Cheapest option — fine for most builds
    image           = "aws/codebuild/standard:7.0"
    type            = "LINUX_CONTAINER"

    environment_variable {
      name  = "APP_ENV"
      value = var.environment
      type  = "PLAINTEXT"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "app/buildspec.yml"  # Points to our buildspec in the repo
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${var.project_name}-${var.environment}"
      stream_name = "build-log"
    }
  }
}

# ─── CodeDeploy Application ────────────────────────────────────────────────────
resource "aws_codedeploy_app" "app" {
  name             = "${var.project_name}-${var.environment}"
  compute_platform = "Server"  # EC2 deployment
}

resource "aws_codedeploy_deployment_group" "app" {
  app_name               = aws_codedeploy_app.app.name
  deployment_group_name  = "${var.project_name}-${var.environment}-dg"
  service_role_arn       = var.codedeploy_role_arn

  # ONE_AT_A_TIME is safest for a single EC2 — no downtime risk
  deployment_config_name = "CodeDeployDefault.OneAtATime"

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = "${var.project_name}-${var.environment}-app-server"
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]  # Auto-rollback on failure
  }
}

# ─── CodePipeline ──────────────────────────────────────────────────────────────
resource "aws_codepipeline" "app" {
  name     = "${var.project_name}-${var.environment}-pipeline"
  role_arn = var.codepipeline_role_arn

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }

  # Stage 1: Pull source from GitHub
  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn        = aws_codestarconnections_connection.github.arn
        FullRepositoryId     = var.github_repo
        BranchName           = var.github_branch
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  # Stage 2: Build and test with CodeBuild
  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.app.name
      }
    }
  }

  # Stage 3: Deploy to EC2 via CodeDeploy
  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ApplicationName     = aws_codedeploy_app.app.name
        DeploymentGroupName = aws_codedeploy_deployment_group.app.deployment_group_name
      }
    }
  }
}
