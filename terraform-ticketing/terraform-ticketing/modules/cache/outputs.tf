# modules/cache/outputs.tf

output "redis_replication_group_id" {
  description = "Redis Replication Group ID"
  value       = aws_elasticache_replication_group.main.id
}

output "redis_primary_endpoint" {
  description = "Redis Primary 엔드포인트"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "redis_reader_endpoint" {
  description = "Redis Reader 엔드포인트"
  value       = aws_elasticache_replication_group.main.reader_endpoint_address
}

output "redis_port" {
  description = "Redis 포트"
  value       = aws_elasticache_replication_group.main.port
}

output "redis_configuration_endpoint" {
  description = "Redis Configuration 엔드포인트"
  value       = aws_elasticache_replication_group.main.configuration_endpoint_address
}
