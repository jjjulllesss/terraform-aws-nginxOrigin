output "instance_id" {
  value = aws_instance.instance[*].id
}

output "instance_public_ip" {
  value = aws_eip.elasticip[*].public_ip
}

output "instance_private_ip" {
  value = aws_instance.instance[*].private_ip
}