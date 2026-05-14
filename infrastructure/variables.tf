# variables.tf
# All input variables declared here — no hardcoded values anywhere else

variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project — used as a prefix for all resource names"
  type        = string
  default     = "cicd-demo"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "owner" {
  description = "Owner tag applied to all resources — your name for the portfolio"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"  # Free tier eligible
}

variable "vpc_id" {
  description = "VPC ID to deploy EC2 into"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for EC2 placement"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into EC2 — use your IP, not 0.0.0.0/0"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository in format 'owner/repo-name'"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch to deploy from"
  type        = string
  default     = "main"
}

variable "alert_email" {
  description = "Email address for pipeline failure alerts via SNS"
  type        = string
}
