# modules/pipeline/variables.tf
variable "project_name" { type = string }
variable "environment" { type = string }
variable "github_repo" { type = string }
variable "github_branch" { type = string }
variable "codepipeline_role_arn" { type = string }
variable "codebuild_role_arn" { type = string }
variable "codedeploy_role_arn" { type = string }
variable "ec2_instance_id" { type = string }
variable "ec2_autoscaling_group" {
  type    = string
  default = null
}
