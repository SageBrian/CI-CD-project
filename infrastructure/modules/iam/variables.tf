# modules/iam/variables.tf
variable "project_name" { type = string }
variable "environment" { type = string }
variable "artifact_bucket" {
  description = "ARN of the S3 artifact bucket — scopes IAM permissions tightly"
  type        = string
}
