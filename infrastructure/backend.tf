# backend.tf
# Stores Terraform state remotely in S3 with DynamoDB locking
# This is a real-world must — never store state locally on a team

terraform {
  backend "s3" {
    bucket         = "briankt-tf-state-cicd"  # Must be globally unique
    key            = "cicd-demo/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "briankt-tf-state-lock"
    encrypt        = true  # Encrypts state file at rest
  }
}
