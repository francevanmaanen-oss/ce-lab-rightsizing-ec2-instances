output "instance_ids" {
  description = "Map of instance name to instance ID — use these in the metric query steps"
  value       = { for k, v in aws_instance.lab : k => v.id }
}

output "web_server_id" {
  description = "Instance ID of the web-server (the one to stress test)"
  value       = aws_instance.lab["web-server"].id
}

output "ami_used" {
  description = "AMI ID that was selected"
  value       = data.aws_ami.al2023.id
}

output "region" {
  description = "AWS region instances were deployed to"
  value       = var.aws_region
}
