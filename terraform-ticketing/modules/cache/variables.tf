# modules/cache/variables.tf

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

variable "security_group_id" {
  description = "Redis Security Group ID"
  type        = string
}

variable "node_type" {
  description = "Redis 노드 타입"
  type        = string
  default     = "cache.t3.micro"
}

variable "num_cache_nodes" {
  description = "캐시 노드 개수"
  type        = number
  default     = 2
}

variable "engine_version" {
  description = "Redis 엔진 버전"
  type        = string
  default     = "7.0"
}

variable "parameter_group_family" {
  description = "Parameter Group Family"
  type        = string
  default     = "redis7"
}

variable "snapshot_retention_limit" {
  description = "스냅샷 보관 기간 (일)"
  type        = number
  default     = 5
}

variable "snapshot_window" {
  description = "스냅샷 생성 시간대 (UTC)"
  type        = string
  default     = "03:00-05:00"
}

variable "maintenance_window" {
  description = "유지보수 시간대 (UTC)"
  type        = string
  default     = "mon:05:00-mon:06:00"
}

variable "tags" {
  description = "리소스 태그"
  type        = map(string)
  default     = {}
}
