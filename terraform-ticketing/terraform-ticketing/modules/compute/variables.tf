# modules/compute/variables.tf

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경 이름"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public Subnet ID 리스트 (ALB용)"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private Subnet ID 리스트 (EC2용)"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "ALB Security Group ID"
  type        = string
}

variable "ec2_security_group_id" {
  description = "EC2 Security Group ID"
  type        = string
}

variable "ami_id" {
  description = "EC2 AMI ID"
  type        = string
  default     = ""  # 기본값은 최신 Amazon Linux 2023
}

variable "instance_type" {
  description = "EC2 인스턴스 타입"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "EC2 Key Pair 이름"
  type        = string
  default     = ""
}

variable "min_size" {
  description = "Auto Scaling 최소 인스턴스 수"
  type        = number
  default     = 2
}

variable "desired_capacity" {
  description = "Auto Scaling 희망 인스턴스 수"
  type        = number
  default     = 4
}

variable "max_size" {
  description = "Auto Scaling 최대 인스턴스 수"
  type        = number
  default     = 20
}

variable "health_check_path" {
  description = "Health Check 경로"
  type        = string
  default     = "/health"
}

variable "certificate_arn" {
  description = "ACM 인증서 ARN (HTTPS용)"
  type        = string
  default     = ""
}

variable "db_endpoint" {
  description = "RDS 엔드포인트"
  type        = string
  default     = ""
}

variable "db_name" {
  description = "데이터베이스 이름"
  type        = string
  default     = "ticketing"
}

variable "db_username" {
  description = "데이터베이스 사용자 이름"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "db_password" {
  description = "데이터베이스 비밀번호"
  type        = string
  sensitive   = true
}

variable "redis_endpoint" {
  description = "Redis 엔드포인트"
  type        = string
  default     = ""
}

variable "s3_bucket_name" {
  description = "S3 버킷 이름"
  type        = string
  default     = ""
}

variable "tags" {
  description = "리소스 태그"
  type        = map(string)
  default     = {}
}
