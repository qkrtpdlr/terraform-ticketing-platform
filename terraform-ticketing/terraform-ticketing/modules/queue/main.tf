# modules/queue/main.tf

variable "project_name" { type = string }
variable "environment" { type = string }
variable "tags" { type = map(string); default = {} }

# SQS Queue (티켓 예매 대기열)
resource "aws_sqs_queue" "ticketing" {
  name                       = "${var.project_name}-${var.environment}-ticketing-queue"
  delay_seconds              = 0
  max_message_size           = 262144  # 256KB
  message_retention_seconds  = 86400   # 1일
  receive_wait_time_seconds  = 10      # Long Polling
  visibility_timeout_seconds = 300     # 5분
  
  # Dead Letter Queue 설정
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })
  
  tags = merge(
    { Name = "${var.project_name}-${var.environment}-ticketing-queue" },
    var.tags
  )
}

# Dead Letter Queue (실패한 메시지)
resource "aws_sqs_queue" "dlq" {
  name                       = "${var.project_name}-${var.environment}-dlq"
  message_retention_seconds  = 1209600  # 14일
  
  tags = merge(
    { Name = "${var.project_name}-${var.environment}-dlq" },
    var.tags
  )
}

# SNS Topic (알림용)
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-${var.environment}-alerts"
  
  tags = merge(
    { Name = "${var.project_name}-${var.environment}-alerts" },
    var.tags
  )
}

# SNS 이메일 구독 (선택 사항)
# resource "aws_sns_topic_subscription" "email" {
#   topic_arn = aws_sns_topic.alerts.arn
#   protocol  = "email"
#   endpoint  = "your-email@example.com"
# }

output "sqs_queue_url" { value = aws_sqs_queue.ticketing.url }
output "sqs_queue_arn" { value = aws_sqs_queue.ticketing.arn }
output "sns_topic_arn" { value = aws_sns_topic.alerts.arn }
