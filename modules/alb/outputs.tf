output "dns_name" {
  value = aws_lb.instance.dns_name
}

output "tg_arn" {
  value = aws_lb_target_group.instance.arn
}

output "tg0_arn" {
  value = aws_lb_target_group.instance0.arn
}

output "tg1_arn" {
  value = aws_lb_target_group.instance1.arn
}

output "tg2_arn" {
  value = aws_lb_target_group.instance2.arn
}


output "id" {
  value = aws_lb.instance.id
}
