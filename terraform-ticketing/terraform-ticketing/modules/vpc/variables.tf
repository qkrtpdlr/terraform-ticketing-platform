# modules/vpc/variables.tf

# 프로젝트 이름 (예: ticketing-platform)
variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

# 환경 (dev, staging, prod)
variable "environment" {
  description = "환경 이름"
  type        = string
}

# VPC CIDR 블록 (예: 10.0.0.0/16)
variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
  default     = "10.0.0.0/16"
}

# 가용 영역 (Multi-AZ 고가용성)
variable "availability_zones" {
  description = "가용 영역 리스트"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

# Public Subnet CIDR (ALB용)
variable "public_subnet_cidrs" {
  description = "Public Subnet CIDR 블록들"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

# Private Subnet CIDR (EC2용)
variable "private_subnet_cidrs" {
  description = "Private Subnet CIDR 블록들"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

# Database Subnet CIDR (RDS, Redis용)
variable "database_subnet_cidrs" {
  description = "Database Subnet CIDR 블록들"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
}

# NAT Gateway 활성화 여부 (비용 절감용)
variable "enable_nat_gateway" {
  description = "NAT Gateway 생성 여부"
  type        = bool
  default     = true
}

# 태그
variable "tags" {
  description = "리소스 태그"
  type        = map(string)
  default     = {}
}
