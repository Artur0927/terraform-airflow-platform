output "vpc_id" {
  value = aws_vpc.main_vpc.id
}

output "public_subnet_ids" {
  value = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}

output "private_subnet_ids" {
  value = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
}

output "security_group_alb_id" {
  value = aws_security_group.sg_alb.id
}

output "security_group_private_app_id" {
  value = aws_security_group.sg_private_app.id
}

output "nat_public_ip" {
  value = aws_instance.nat_bastion.public_ip
}

output "alb_dns_name" {
  value = aws_lb.app_alb.dns_name
}

output "target_group_arn" {
  value = aws_lb_target_group.app_tg.arn
}
