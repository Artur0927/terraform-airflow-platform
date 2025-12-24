output "public_ip" {
  value = data.aws_eip.by_id.public_ip
}

output "public_dns" {
  value = aws_instance.airflow_ec2.public_dns
}
