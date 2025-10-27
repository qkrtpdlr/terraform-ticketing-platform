# outputs.tf

# ==========================================
# VPC 정보
# ==========================================
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public Subnet ID 리스트"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private Subnet ID 리스트"
  value       = module.vpc.private_subnet_ids
}

# ==========================================
# ALB 정보
# ==========================================
output "alb_dns_name" {
  description = "ALB DNS 이름 (웹사이트 접속 주소)"
  value       = module.compute.alb_dns_name
}

output "alb_url" {
  description = "ALB URL"
  value       = "http://${module.compute.alb_dns_name}"
}

# ==========================================
# 데이터베이스 정보
# ==========================================
output "rds_endpoint" {
  description = "RDS Writer 엔드포인트"
  value       = module.database.cluster_endpoint
  sensitive   = true
}

output "rds_reader_endpoint" {
  description = "RDS Reader 엔드포인트"
  value       = module.database.cluster_reader_endpoint
  sensitive   = true
}

# ==========================================
# Redis 정보
# ==========================================
output "redis_endpoint" {
  description = "Redis Primary 엔드포인트"
  value       = module.cache.redis_primary_endpoint
  sensitive   = true
}

# ==========================================
# S3 정보
# ==========================================
output "s3_bucket_name" {
  description = "S3 버킷 이름"
  value       = module.storage.bucket_name
}

# ==========================================
# SQS 정보
# ==========================================
output "sqs_queue_url" {
  description = "SQS Queue URL"
  value       = module.queue.sqs_queue_url
}

# ==========================================
# 접속 정보 요약
# ==========================================
output "connection_info" {
  description = "인프라 접속 정보 요약"
  value = <<-EOT
  
  ========================================
  🎯 Terraform 티켓팅 플랫폼 배포 완료!
  ========================================
  
  📍 웹사이트 주소:
     ${module.compute.alb_dns_name}
  
  📊 데이터베이스:
     - Writer: ${module.database.cluster_endpoint}
     - Reader: ${module.database.cluster_reader_endpoint}
     - Database: ${var.db_name}
     - Username: ${var.db_username}
  
  🔴 Redis:
     ${module.cache.redis_primary_endpoint}:6379
  
  📦 S3 Bucket:
     ${module.storage.bucket_name}
  
  📬 SQS Queue:
     ${module.queue.sqs_queue_url}
  
  ========================================
  💡 다음 단계:
  1. 웹사이트 접속: http://${module.compute.alb_dns_name}
  2. 헬스체크 확인: http://${module.compute.alb_dns_name}/health
  3. Auto Scaling 확인: AWS Console → EC2 → Auto Scaling Groups
  4. 모니터링 확인: AWS Console → CloudWatch
  ========================================
  
  EOT
}
