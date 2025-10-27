# modules/database/variables.tf

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경 이름"
  type        = string
}

variable "database_subnet_ids" {
  description = "Database Subnet ID 리스트"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "security_group_id" {
  description = "RDS Security Group ID"
  type        = string
}

variable "database_name" {
  description = "데이터베이스 이름"
  type        = string
  default     = "ticketing"
}

variable "master_username" {
  description = "마스터 사용자 이름"
  type        = string
  default     = "admin"
}

variable "master_password" {
  description = "마스터 비밀번호"
  type        = string
  sensitive   = true
}

variable "instance_class" {
  description = "RDS 인스턴스 클래스"
  type        = string
  default     = "db.t3.medium"
}

variable "engine_version" {
  description = "Aurora MySQL 엔진 버전"
  type        = string
  default     = "8.0.mysql_aurora.3.04.0"
}

variable "backup_retention_period" {
  description = "백업 보관 기간 (일)"
  type        = number
  default     = 7
}

variable "preferred_backup_window" {
  description = "백업 시간대 (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "preferred_maintenance_window" {
  description = "유지보수 시간대 (UTC)"
  type        = string
  default     = "mon:04:00-mon:05:00"
}

variable "read_replica_count" {
  description = "Read Replica 개수"
  type        = number
  default     = 1
}

variable "skip_final_snapshot" {
  description = "삭제 시 최종 스냅샷 생략 여부"
  type        = bool
  default     = false
}

variable "tags" {
  description = "리소스 태그"
  type        = map(string)
  default     = {}
}
