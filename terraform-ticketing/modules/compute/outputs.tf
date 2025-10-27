# modules/compute/outputs.tf

output "alb_id" {
  description = "ALB ID"
  value       = aws_lb.main.id
}

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "ALB DNS 이름"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "ALB Zone ID (Route53용)"
  value       = aws_lb.main.zone_id
}

output "target_group_arn" {
  description = "Target Group ARN"
  value       = aws_lb_target_group.web.arn
}

output "autoscaling_group_name" {
  description = "Auto Scaling Group 이름"
  value       = aws_autoscaling_group.web.name
}

output "autoscaling_group_arn" {
  description = "Auto Scaling Group ARN"
  value       = aws_autoscaling_group.web.arn
}

output "launch_template_id" {
  description = "Launch Template ID"
  value       = aws_launch_template.web.id
}
