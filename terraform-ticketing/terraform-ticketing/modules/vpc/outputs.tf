# modules/vpc/outputs.tf

# VPC ID
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

# VPC CIDR Block
output "vpc_cidr" {
  description = "VPC CIDR 블록"
  value       = aws_vpc.main.cidr_block
}

# Public Subnet IDs
output "public_subnet_ids" {
  description = "Public Subnet ID 리스트"
  value       = aws_subnet.public[*].id
}

# Private Subnet IDs
output "private_subnet_ids" {
  description = "Private Subnet ID 리스트"
  value       = aws_subnet.private[*].id
}

# Database Subnet IDs
output "database_subnet_ids" {
  description = "Database Subnet ID 리스트"
  value       = aws_subnet.database[*].id
}

# NAT Gateway IDs
output "nat_gateway_ids" {
  description = "NAT Gateway ID 리스트"
  value       = aws_nat_gateway.main[*].id
}

# Internet Gateway ID
output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.main.id
}

# Availability Zones
output "availability_zones" {
  description = "사용 중인 가용 영역"
  value       = var.availability_zones
}
