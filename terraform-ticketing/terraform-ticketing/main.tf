# main.tf (Root Module)

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Remote State 설정 (선택 사항)
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "ticketing/terraform.tfstate"
  #   region         = "ap-northeast-2"
  #   encrypt        = true
  #   dynamodb_table = "terraform-lock"
  # }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# ==========================================
# 1. VPC 모듈
# ==========================================
module "vpc" {
  source = "./modules/vpc"
  
  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
  
  enable_nat_gateway = var.enable_nat_gateway
}

# ==========================================
# 2. Security Group 모듈
# ==========================================
module "security" {
  source = "./modules/security"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  vpc_cidr     = module.vpc.vpc_cidr
}

# ==========================================
# 3. RDS Aurora 모듈
# ==========================================
module "database" {
  source = "./modules/database"
  
  project_name        = var.project_name
  environment         = var.environment
  database_subnet_ids = module.vpc.database_subnet_ids
  vpc_id              = module.vpc.vpc_id
  security_group_id   = module.security.rds_security_group_id
  
  database_name       = var.db_name
  master_username     = var.db_username
  master_password     = var.db_password
  instance_class      = var.db_instance_class
  read_replica_count  = var.db_read_replica_count
  
  skip_final_snapshot = var.environment != "prod"
}

# ==========================================
# 4. ElastiCache Redis 모듈
# ==========================================
module "cache" {
  source = "./modules/cache"
  
  project_name        = var.project_name
  environment         = var.environment
  database_subnet_ids = module.vpc.database_subnet_ids
  security_group_id   = module.security.redis_security_group_id
  
  node_type        = var.redis_node_type
  num_cache_nodes  = var.redis_num_nodes
}

# ==========================================
# 5. S3 모듈
# ==========================================
module "storage" {
  source = "./modules/storage"
  
  project_name = var.project_name
  environment  = var.environment
}

# ==========================================
# 6. SQS + SNS 모듈
# ==========================================
module "queue" {
  source = "./modules/queue"
  
  project_name = var.project_name
  environment  = var.environment
}

# ==========================================
# 7. ALB + Auto Scaling 모듈
# ==========================================
module "compute" {
  source = "./modules/compute"
  
  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  
  alb_security_group_id = module.security.alb_security_group_id
  ec2_security_group_id = module.security.ec2_security_group_id
  
  instance_type    = var.ec2_instance_type
  min_size         = var.asg_min_size
  desired_capacity = var.asg_desired_capacity
  max_size         = var.asg_max_size
  
  db_endpoint    = module.database.cluster_endpoint
  db_name        = var.db_name
  db_username    = var.db_username
  db_password    = var.db_password
  redis_endpoint = module.cache.redis_primary_endpoint
  s3_bucket_name = module.storage.bucket_name
  
  certificate_arn = var.certificate_arn
}

# ==========================================
# 8. CloudWatch 모니터링 모듈
# ==========================================
module "monitoring" {
  source = "./modules/monitoring"
  
  project_name              = var.project_name
  environment               = var.environment
  alb_arn_suffix            = module.compute.alb_arn
  target_group_arn_suffix   = module.compute.target_group_arn
  autoscaling_group_name    = module.compute.autoscaling_group_name
  sns_topic_arn             = module.queue.sns_topic_arn
}
