# VPC 모듈

## 개요
3-Tier 아키텍처를 위한 VPC 네트워크를 생성합니다.

## 구성 요소
- **VPC**: 격리된 가상 네트워크
- **Public Subnet**: ALB, NAT Gateway 위치
- **Private Subnet**: EC2 애플리케이션 서버 위치
- **Database Subnet**: RDS, ElastiCache 위치
- **Internet Gateway**: Public Subnet의 인터넷 연결
- **NAT Gateway**: Private Subnet의 아웃바운드 인터넷 연결

## 사용 예시

```hcl
module "vpc" {
  source = "./modules/vpc"
  
  project_name       = "ticketing"
  environment        = "dev"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["ap-northeast-2a", "ap-northeast-2c"]
  
  public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs  = ["10.0.11.0/24", "10.0.12.0/24"]
  database_subnet_cidrs = ["10.0.21.0/24", "10.0.22.0/24"]
  
  enable_nat_gateway = true
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_name | 프로젝트 이름 | string | - | yes |
| environment | 환경 (dev/prod) | string | - | yes |
| vpc_cidr | VPC CIDR 블록 | string | 10.0.0.0/16 | no |
| availability_zones | 가용 영역 리스트 | list(string) | ["ap-northeast-2a", "ap-northeast-2c"] | no |
| enable_nat_gateway | NAT Gateway 생성 여부 | bool | true | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | VPC ID |
| public_subnet_ids | Public Subnet ID 리스트 |
| private_subnet_ids | Private Subnet ID 리스트 |
| database_subnet_ids | Database Subnet ID 리스트 |

## 비용
- **NAT Gateway**: 약 $0.045/시간 + 데이터 전송 비용
- **Elastic IP**: 사용 중일 때는 무료, 미사용 시 $0.005/시간

## 주의사항
- NAT Gateway는 비용이 많이 들므로, Dev 환경에서는 `enable_nat_gateway = false`로 설정 가능
- Multi-AZ 구성을 위해 최소 2개의 가용 영역 사용 권장
