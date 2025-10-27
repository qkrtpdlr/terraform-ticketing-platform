# modules/database/outputs.tf

output "cluster_id" {
  description = "RDS Cluster ID"
  value       = aws_rds_cluster.main.id
}

output "cluster_endpoint" {
  description = "Writer 엔드포인트 (쓰기용)"
  value       = aws_rds_cluster.main.endpoint
}

output "cluster_reader_endpoint" {
  description = "Reader 엔드포인트 (읽기용)"
  value       = aws_rds_cluster.main.reader_endpoint
}

output "cluster_port" {
  description = "데이터베이스 포트"
  value       = aws_rds_cluster.main.port
}

output "database_name" {
  description = "데이터베이스 이름"
  value       = aws_rds_cluster.main.database_name
}

output "master_username" {
  description = "마스터 사용자 이름"
  value       = aws_rds_cluster.main.master_username
  sensitive   = true
}
