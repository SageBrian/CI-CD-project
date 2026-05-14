# outputs.tf
# Values printed after terraform apply — useful for referencing deployed resources

output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = module.ec2.public_ip
}

output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = module.ec2.instance_id
}

output "pipeline_name" {
  description = "Name of the CodePipeline"
  value       = module.pipeline.pipeline_name
}

output "artifact_bucket" {
  description = "S3 bucket used for pipeline artifacts"
  value       = module.pipeline.artifact_bucket_name
}

output "app_url" {
  description = "URL to access the deployed application"
  value       = "http://${module.ec2.public_ip}:3000"
}
