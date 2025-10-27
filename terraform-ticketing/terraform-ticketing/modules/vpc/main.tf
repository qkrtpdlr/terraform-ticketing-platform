# modules/vpc/main.tf

# ==========================================
# VPC (Virtual Private Cloud)
# ==========================================
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true  # DNS 호스트명 활성화 (중요!)
  enable_dns_support   = true  # DNS 지원 활성화
  
  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-vpc"
      Environment = var.environment
    },
    var.tags
  )
}

# ==========================================
# Internet Gateway (인터넷 게이트웨이)
# ==========================================
# Public Subnet이 인터넷과 통신하기 위해 필요
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-igw"
      Environment = var.environment
    },
    var.tags
  )
}

# ==========================================
# Public Subnet (공개 서브넷)
# ==========================================
# ALB, NAT Gateway가 위치하는 곳
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true  # 자동으로 Public IP 할당
  
  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-public-${count.index + 1}"
      Type        = "public"
      Environment = var.environment
    },
    var.tags
  )
}

# ==========================================
# Private Subnet (프라이빗 서브넷)
# ==========================================
# EC2 애플리케이션 서버가 위치하는 곳
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  
  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-private-${count.index + 1}"
      Type        = "private"
      Environment = var.environment
    },
    var.tags
  )
}

# ==========================================
# Database Subnet (데이터베이스 서브넷)
# ==========================================
# RDS, ElastiCache가 위치하는 곳
resource "aws_subnet" "database" {
  count             = length(var.database_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.database_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  
  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-database-${count.index + 1}"
      Type        = "database"
      Environment = var.environment
    },
    var.tags
  )
}

# ==========================================
# Elastic IP for NAT Gateway
# ==========================================
# NAT Gateway가 사용할 고정 IP
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? length(var.availability_zones) : 0
  domain = "vpc"
  
  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-nat-eip-${count.index + 1}"
      Environment = var.environment
    },
    var.tags
  )
  
  depends_on = [aws_internet_gateway.main]
}

# ==========================================
# NAT Gateway
# ==========================================
# Private Subnet이 인터넷에 접근하기 위한 게이트웨이
# (인터넷에서는 Private Subnet으로 접근 불가, 단방향)
resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_gateway ? length(var.availability_zones) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-nat-${count.index + 1}"
      Environment = var.environment
    },
    var.tags
  )
  
  depends_on = [aws_internet_gateway.main]
}

# ==========================================
# Route Table - Public
# ==========================================
# Public Subnet의 라우팅 규칙
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-public-rt"
      Type        = "public"
      Environment = var.environment
    },
    var.tags
  )
}

# Public Route: 모든 트래픽(0.0.0.0/0)을 Internet Gateway로
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Public Subnet과 Route Table 연결
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ==========================================
# Route Table - Private
# ==========================================
# Private Subnet의 라우팅 규칙
resource "aws_route_table" "private" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.main.id
  
  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-private-rt-${count.index + 1}"
      Type        = "private"
      Environment = var.environment
    },
    var.tags
  )
}

# Private Route: 모든 트래픽을 NAT Gateway로
resource "aws_route" "private_nat" {
  count                  = var.enable_nat_gateway ? length(var.private_subnet_cidrs) : 0
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[count.index].id
}

# Private Subnet과 Route Table 연결
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# ==========================================
# Route Table - Database
# ==========================================
# Database Subnet의 라우팅 규칙 (인터넷 접근 없음)
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-database-rt"
      Type        = "database"
      Environment = var.environment
    },
    var.tags
  )
}

# Database Subnet과 Route Table 연결
resource "aws_route_table_association" "database" {
  count          = length(var.database_subnet_cidrs)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}
