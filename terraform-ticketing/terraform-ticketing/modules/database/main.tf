# modules/database/main.tf

# ==========================================
# DB Subnet Group
# ==========================================
# RDS가 배치될 서브넷 그룹
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = var.database_subnet_ids
  
  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-db-subnet-group"
      Environment = var.environment
    },
    var.tags
  )
}

# ==========================================
# RDS Aurora Cluster Parameter Group
# ==========================================
# 클러스터 수준 설정
resource "aws_rds_cluster_parameter_group" "main" {
  name        = "${var.project_name}-${var.environment}-cluster-pg"
  family      = "aurora-mysql8.0"
  description = "Aurora MySQL cluster parameter group"

  # 문자셋 설정 (한글 지원)
  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_client"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_connection"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_results"
    value = "utf8mb4"
  }

  # 타임존 설정 (서울)
  parameter {
    name  = "time_zone"
    value = "Asia/Seoul"
  }

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-cluster-pg"
      Environment = var.environment
    },
    var.tags
  )
}

# ==========================================
# RDS DB Parameter Group
# ==========================================
# 인스턴스 수준 설정
resource "aws_db_parameter_group" "main" {
  name        = "${var.project_name}-${var.environment}-db-pg"
  family      = "aurora-mysql8.0"
  description = "Aurora MySQL DB parameter group"

  # 슬로우 쿼리 로깅
  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-db-pg"
      Environment = var.environment
    },
    var.tags
  )
}

# ==========================================
# RDS Aurora Cluster
# ==========================================
# Aurora MySQL 클러스터 생성
resource "aws_rds_cluster" "main" {
  cluster_identifier              = "${var.project_name}-${var.environment}-aurora-cluster"
  engine                          = "aurora-mysql"
  engine_version                  = var.engine_version
  database_name                   = var.database_name
  master_username                 = var.master_username
  master_password                 = var.master_password
  
  # 백업 설정
  backup_retention_period         = var.backup_retention_period
  preferred_backup_window         = var.preferred_backup_window
  preferred_maintenance_window    = var.preferred_maintenance_window
  
  # 네트워크 설정
  db_subnet_group_name            = aws_db_subnet_group.main.name
  vpc_security_group_ids          = [var.security_group_id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main.name
  
  # CloudWatch 로그 전송
  enabled_cloudwatch_logs_exports = ["audit", "error", "slowquery"]
  
  # 암호화
  storage_encrypted               = true
  
  # 삭제 보호 (프로덕션 환경에서는 true 권장)
  deletion_protection             = var.environment == "prod" ? true : false
  
  # 최종 스냅샷 설정
  skip_final_snapshot             = var.skip_final_snapshot
  final_snapshot_identifier       = var.skip_final_snapshot ? null : "${var.project_name}-${var.environment}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  
  # 자동 마이너 버전 업그레이드
  apply_immediately               = var.environment != "prod"
  
  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-aurora-cluster"
      Environment = var.environment
    },
    var.tags
  )
  
  lifecycle {
    ignore_changes = [final_snapshot_identifier]
  }
}

# ==========================================
# Aurora Cluster Instance - Writer (Primary)
# ==========================================
# 쓰기 작업을 처리하는 Primary 인스턴스
resource "aws_rds_cluster_instance" "writer" {
  identifier                   = "${var.project_name}-${var.environment}-aurora-writer"
  cluster_identifier           = aws_rds_cluster.main.id
  instance_class               = var.instance_class
  engine                       = aws_rds_cluster.main.engine
  engine_version               = aws_rds_cluster.main.engine_version
  db_parameter_group_name      = aws_db_parameter_group.main.name
  
  # Performance Insights 활성화 (성능 모니터링)
  performance_insights_enabled = true
  performance_insights_retention_period = 7
  
  # Enhanced Monitoring (상세 모니터링)
  monitoring_interval          = 60
  monitoring_role_arn          = aws_iam_role.rds_monitoring.arn
  
  # 자동 마이너 버전 업그레이드
  auto_minor_version_upgrade   = true
  
  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-aurora-writer"
      Role        = "writer"
      Environment = var.environment
    },
    var.tags
  )
}

# ==========================================
# Aurora Cluster Instance - Reader (Replica)
# ==========================================
# 읽기 작업을 처리하는 Read Replica 인스턴스
resource "aws_rds_cluster_instance" "reader" {
  count                        = var.read_replica_count
  identifier                   = "${var.project_name}-${var.environment}-aurora-reader-${count.index + 1}"
  cluster_identifier           = aws_rds_cluster.main.id
  instance_class               = var.instance_class
  engine                       = aws_rds_cluster.main.engine
  engine_version               = aws_rds_cluster.main.engine_version
  db_parameter_group_name      = aws_db_parameter_group.main.name
  
  # Performance Insights 활성화
  performance_insights_enabled = true
  performance_insights_retention_period = 7
  
  # Enhanced Monitoring
  monitoring_interval          = 60
  monitoring_role_arn          = aws_iam_role.rds_monitoring.arn
  
  # 자동 마이너 버전 업그레이드
  auto_minor_version_upgrade   = true
  
  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-aurora-reader-${count.index + 1}"
      Role        = "reader"
      Environment = var.environment
    },
    var.tags
  )
}

# ==========================================
# IAM Role for Enhanced Monitoring
# ==========================================
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.project_name}-${var.environment}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-rds-monitoring-role"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
