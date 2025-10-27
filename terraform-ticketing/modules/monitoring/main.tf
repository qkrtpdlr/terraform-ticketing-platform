# modules/monitoring/main.tf

variable "project_name" { type = string }
variable "environment" { type = string }
variable "alb_arn_suffix" { type = string }
variable "target_group_arn_suffix" { type = string }
variable "autoscaling_group_name" { type = string }
variable "sns_topic_arn" { type = string }
variable "tags" { type = map(string); default = {} }

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/${var.project_name}/${var.environment}/application"
  retention_in_days = 7
  
  tags = merge(
    { Name = "${var.project_name}-${var.environment}-app-logs" },
    var.tags
  )
}

# ALB 5xx 에러 알람
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.project_name}-${var.environment}-alb-5xx-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "ALB 5xx 에러가 임계값을 초과했습니다"
  alarm_actions       = [var.sns_topic_arn]
  
  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
  
  tags = var.tags
}

# Target 건강 상태 알람
resource "aws_cloudwatch_metric_alarm" "target_health" {
  alarm_name          = "${var.project_name}-${var.environment}-target-unhealthy"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "건강한 타겟이 1개 미만입니다"
  alarm_actions       = [var.sns_topic_arn]
  
  dimensions = {
    TargetGroup  = var.target_group_arn_suffix
    LoadBalancer = var.alb_arn_suffix
  }
  
  tags = var.tags
}

# Auto Scaling CPU 알람
resource "aws_cloudwatch_metric_alarm" "asg_cpu_high" {
  alarm_name          = "${var.project_name}-${var.environment}-asg-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Auto Scaling Group CPU가 80%를 초과했습니다"
  alarm_actions       = [var.sns_topic_arn]
  
  dimensions = {
    AutoScalingGroupName = var.autoscaling_group_name
  }
  
  tags = var.tags
}

output "log_group_name" { value = aws_cloudwatch_log_group.app.name }
