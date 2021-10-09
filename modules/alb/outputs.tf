output "dns_name" {
  value = aws_lb.instance.dns_name
}

output "tg_arn" {
  value = aws_lb_target_group.instance.arn
}

output "id" {
  value = aws_lb.instance.id
}
