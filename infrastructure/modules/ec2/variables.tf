# modules/ec2/variables.tf
variable "project_name" { type = string }
variable "environment" { type = string }
variable "instance_type" { type = string }
variable "ec2_instance_profile" { type = string }
variable "vpc_id" { type = string }
variable "subnet_id" { type = string }
variable "allowed_ssh_cidr" { type = string }
