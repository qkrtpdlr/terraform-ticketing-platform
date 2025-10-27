# modules/cache/main.tf

# ==========================================
# ElastiCache Subnet Group
# ==========================================
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-redis-subnet-group"
  subnet_ids = var.database_subnet_ids
  
  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-redis-subnet-group"
      Environment = var.environment
    },
    var.tags
  )
}

# ==========================================
# ElastiCache Parameter Group
# ==========================================
resource "aws_elasticache_parameter_group" "main" {
  name   = "${var.project_name}-${var.environment}-redis-pg"
  family = var.parameter_group_family
  
  # 최대 메모리 정책 (메모리 부족 시 오래된 키 삭제)
  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }
  
  # 타임아웃 설정 (초)
  parameter {
    name  = "timeout"
    value = "300"
  }
  
  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-redis-pg"
      Environment = var.environment
    },
    var.tags
  )
}

# ==========================================
# ElastiCache Replication Group (Redis Cluster)
# ==========================================
resource "aws_elasticache_replication_group" "main" {
  replication_group_id       = "${var.project_name}-${var.environment}-redis"
  replication_group_description = "Redis cluster for ${var.project_name} ${var.environment}"
  
  # 엔진 설정
  engine                     = "redis"
  engine_version             = var.engine_version
  node_type                  = var.node_type
  num_cache_clusters         = var.num_cache_nodes
  parameter_group_name       = aws_elasticache_parameter_group.main.name
  port                       = 6379
  
  # 네트워크 설정
  subnet_group_name          = aws_elasticache_subnet_group.main.name
  security_group_ids         = [var.security_group_id]
  
  # 고가용성 설정
  automatic_failover_enabled = var.num_cache_nodes > 1 ? true : false
  multi_az_enabled           = var.num_cache_nodes > 1 ? true : false
  
  # 보안 설정
  at_rest_encryption_enabled = true  # 저장 데이터 암호화
  transit_encryption_enabled = true  # 전송 데이터 암호화
  auth_token_enabled         = false # 인증 토큰 (필요시 true)
  
  # 백업 설정
  snapshot_retention_limit   = var.snapshot_retention_limit
  snapshot_window            = var.snapshot_window
  
  # 유지보수 설정
  maintenance_window         = var.maintenance_window
  
  # 자동 마이너 버전 업그레이드
  auto_minor_version_upgrade = true
  
  # 알림 설정 (선택 사항)
  notification_topic_arn     = null
  
  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-redis"
      Environment = var.environment
    },
    var.tags
  )
  
  lifecycle {
    ignore_changes = [engine_version]
  }
}
