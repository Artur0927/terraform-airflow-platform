

output "public_dns" {
  value = aws_instance.airflow_ec2.public_ip
}

output "instance_private_ip" {
  value = aws_instance.airflow_ec2.private_ip
}

output "instance_id" {
  value = aws_instance.airflow_ec2.id
}
