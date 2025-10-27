# variables.tf

# ==========================================
# 기본 설정
# ==========================================
variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = "ticketing"
}

variable "environment" {
  description = "환경 (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# ==========================================
# VPC 설정
# ==========================================
variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "가용 영역 리스트"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "public_subnet_cidrs" {
  description = "Public Subnet CIDR 블록들"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private Subnet CIDR 블록들"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "database_subnet_cidrs" {
  description = "Database Subnet CIDR 블록들"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
}

variable "enable_nat_gateway" {
  description = "NAT Gateway 활성화 (비용 절감을 위해 dev는 false 가능)"
  type        = bool
  default     = true
}

# ==========================================
# RDS 설정
# ==========================================
variable "db_name" {
  description = "데이터베이스 이름"
  type        = string
  default     = "ticketing"
}

variable "db_username" {
  description = "데이터베이스 마스터 사용자 이름"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "db_password" {
  description = "데이터베이스 마스터 비밀번호"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS 인스턴스 클래스"
  type        = string
  default     = "db.t3.medium"
}

variable "db_read_replica_count" {
  description = "Read Replica 개수"
  type        = number
  default     = 1
}

# ==========================================
# ElastiCache Redis 설정
# ==========================================
variable "redis_node_type" {
  description = "Redis 노드 타입"
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_num_nodes" {
  description = "Redis 노드 개수"
  type        = number
  default     = 2
}

# ==========================================
# EC2 Auto Scaling 설정
# ==========================================
variable "ec2_instance_type" {
  description = "EC2 인스턴스 타입"
  type        = string
  default     = "t3.medium"
}

variable "asg_min_size" {
  description = "Auto Scaling 최소 인스턴스 수"
  type        = number
  default     = 2
}

variable "asg_desired_capacity" {
  description = "Auto Scaling 희망 인스턴스 수"
  type        = number
  default     = 4
}

variable "asg_max_size" {
  description = "Auto Scaling 최대 인스턴스 수"
  type        = number
  default     = 20
}

# ==========================================
# SSL 인증서 (선택 사항)
# ==========================================
variable "certificate_arn" {
  description = "ACM 인증서 ARN (HTTPS용)"
  type        = string
  default     = ""
}
