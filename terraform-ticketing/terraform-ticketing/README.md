# 🎫 Terraform 고가용성 티켓팅 플랫폼

[![Terraform](https://img.shields.io/badge/Terraform-v1.0+-7B42BC?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Multi--AZ-FF9900?logo=amazon-aws)](https://aws.amazon.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**Terraform IaC 기반 대규모 동시 접속 처리가 가능한 고가용성 티켓팅 시스템**

---

## 📋 목차

- [프로젝트 소개](#-프로젝트-소개)
- [아키텍처](#-아키텍처)
- [기술 스택](#-기술-스택)
- [주요 기능](#-주요-기능)
- [시작하기](#-시작하기)
- [배포 가이드](#-배포-가이드)
- [비용 정보](#-비용-정보)
- [트러블슈팅](#-트러블슈팅)

---

## 🎯 프로젝트 소개

### 핵심 목표
- ⚡ **대규모 동시 접속 처리**: 수만 명 동시 접속 지원
- 🔄 **고가용성 아키텍처**: Multi-AZ, Auto Scaling
- 🔐 **보안 강화**: WAF, VPC 격리, 암호화
- 📊 **실시간 모니터링**: CloudWatch Alarms, Dashboards
- 🚀 **완전 자동화**: Terraform IaC, Auto Scaling

### 성과
| 지표 | 목표치 |
|------|--------|
| 동시 접속 | 10,000+ 명 |
| 응답 시간 | < 200ms |
| 가용성 | 99.9% |
| Auto Scaling | 2 → 20 인스턴스 |

---

## 🏗️ 아키텍처

### 시스템 구성도

```
                    ┌─────────────────────────────────────┐
                    │         사용자 (Users)              │
                    │  수만 명 동시 접속 (대규모 트래픽)    │
                    └──────────────┬──────────────────────┘
                                   │
                    ┌──────────────▼──────────────────────┐
                    │      CloudFront (CDN)               │
                    │  - 정적 콘텐츠 캐싱                  │
                    │  - DDoS 방어                        │
                    └──────────────┬──────────────────────┘
                                   │
        ┌──────────────────────────┴──────────────────────────┐
        │                  AWS VPC (10.0.0.0/16)              │
        │                                                     │
        │  ┌─────────────── Public Subnet ────────────────┐  │
        │  │  ALB (Application Load Balancer)             │  │
        │  │  - Multi-AZ (AZ-a, AZ-c)                     │  │
        │  │  - Health Check                              │  │
        │  └──────────────┬───────────────────────────────┘  │
        │                 │                                   │
        │  ┌──────────────▼──────────────────────────────┐   │
        │  │     Private Subnet (Auto Scaling)           │   │
        │  │  - EC2 (t3.medium ~ c5.large)               │   │
        │  │  - Min: 2, Desired: 4, Max: 20              │   │
        │  └──────────────┬───────────────────────────────┘  │
        │                 │                                   │
        │  ┌──────────────▼──────────────────────────────┐   │
        │  │     Database Subnet (격리)                  │   │
        │  │  - RDS Aurora MySQL (Multi-AZ)              │   │
        │  │  - ElastiCache Redis Cluster                │   │
        │  └─────────────────────────────────────────────┘   │
        │                                                     │
        └─────────────────────────────────────────────────────┘
                         │                │
                    ┌────▼────┐      ┌────▼────┐
                    │   SQS   │      │   SNS   │
                    │ (Queue) │      │ (Alert) │
                    └─────────┘      └─────────┘
```

### 3-Tier 아키텍처

**Tier 1: Presentation Layer (Public Subnet)**
- Application Load Balancer
- CloudFront CDN
- Route 53 DNS

**Tier 2: Application Layer (Private Subnet)**
- EC2 Auto Scaling Group
- Docker 컨테이너
- SQS Queue (비동기 처리)

**Tier 3: Data Layer (Database Subnet)**
- RDS Aurora MySQL (Writer + Reader)
- ElastiCache Redis Cluster
- S3 Storage

---

## 🛠️ 기술 스택

### Infrastructure as Code
- **Terraform** 1.0+
  - 12개 모듈화 설계
  - Remote State Management
  - Workspace 분리 (dev/prod)

### AWS 서비스

#### Compute
- EC2 Auto Scaling Group
- Application Load Balancer
- NAT Gateway

#### Database & Cache
- RDS Aurora MySQL 8.0
- ElastiCache Redis 7.0

#### Storage & Queue
- S3 (Server-Side Encryption)
- SQS (Dead Letter Queue)
- SNS (Alerting)

#### Network & Security
- VPC (3-Tier Architecture)
- Security Groups (최소 권한)
- CloudFront + WAF
- ACM (SSL/TLS)

#### Monitoring
- CloudWatch (Logs, Metrics, Alarms)
- CloudTrail (Audit Logs)
- X-Ray (Distributed Tracing)

---

## ⚡ 주요 기능

### 1. 고가용성 (High Availability)
- ✅ Multi-AZ 배포 (2개 가용 영역)
- ✅ Auto Scaling (2 ~ 20 인스턴스)
- ✅ RDS Multi-AZ + Read Replica
- ✅ Redis Multi-AZ Cluster

### 2. 확장성 (Scalability)
- ✅ 수평 확장 (Auto Scaling)
- ✅ 수직 확장 (인스턴스 타입 변경)
- ✅ Read Replica (읽기 성능 향상)

### 3. 보안 (Security)
- ✅ VPC 격리 (Public/Private/DB Subnet)
- ✅ Security Group (최소 권한 원칙)
- ✅ 암호화 (저장/전송 데이터)
- ✅ IAM Role (EC2 권한 관리)

### 4. 모니터링 (Monitoring)
- ✅ CloudWatch Alarms (CPU, 5xx 에러)
- ✅ Auto Scaling Metrics
- ✅ SNS 알림 (이메일, SMS)

---

## 🚀 시작하기

### 사전 요구사항

1. **Terraform 설치** (v1.0+)
```bash
brew install terraform  # macOS
choco install terraform  # Windows
```

2. **AWS CLI 설치 및 설정**
```bash
aws configure
# AWS Access Key ID: YOUR_KEY
# AWS Secret Access Key: YOUR_SECRET
# Default region: ap-northeast-2
```

3. **Git Clone**
```bash
git clone https://github.com/yourusername/terraform-ticketing-platform.git
cd terraform-ticketing-platform
```

---

## 📦 배포 가이드

### 1단계: 환경 변수 설정

```bash
# terraform.tfvars 파일 생성
cp terraform.tfvars.example terraform.tfvars

# 비밀번호 등 수정
nano terraform.tfvars
```

**필수 수정 항목**:
```hcl
db_password = "YourSecurePassword123!"  # 🔒 변경 필수!
```

### 2단계: Terraform 초기화

```bash
terraform init
```

### 3단계: 실행 계획 확인

```bash
terraform plan
```

**생성될 리소스 개수**: 약 50개
- VPC, Subnet: 7개
- Security Groups: 4개
- RDS Cluster: 1개 (인스턴스 2개)
- Redis Cluster: 1개 (노드 2개)
- ALB + Auto Scaling: 5개
- IAM Roles: 2개
- CloudWatch: 3개
- 기타: S3, SQS, SNS

### 4단계: 인프라 배포

```bash
# 자동 배포 스크립트 (권장)
chmod +x scripts/deploy.sh
./scripts/deploy.sh

# 또는 수동 배포
terraform apply
```

**소요 시간**: 약 10-15분 ☕

### 5단계: 배포 확인

```bash
# Outputs 확인
terraform output

# ALB DNS 확인
terraform output -raw alb_dns_name
```

**접속 테스트**:
```bash
# 웹사이트 접속
curl http://$(terraform output -raw alb_dns_name)

# Health Check
curl http://$(terraform output -raw alb_dns_name)/health
```

---

## 💰 비용 정보

### Dev 환경 (월간, 서울 리전 기준)

| 서비스 | 스펙 | 월 비용 (USD) |
|--------|------|---------------|
| EC2 (t3.medium) | 4대 상시 | ~$120 |
| ALB | 1개 | ~$20 |
| RDS Aurora (db.t3.medium) | 2대 | ~$120 |
| ElastiCache (cache.t3.micro) | 2노드 | ~$30 |
| NAT Gateway | 2개 | ~$65 |
| S3 + CloudWatch | 데이터 전송 | ~$10 |
| **총합** | | **~$365/월** |

### 비용 절감 팁 💡

1. **NAT Gateway 비활성화** (Dev 환경)
```hcl
enable_nat_gateway = false  # 월 $65 절감
```

2. **인스턴스 수 줄이기**
```hcl
asg_min_size = 1  # 월 $60 절감
```

3. **Redis 노드 줄이기**
```hcl
redis_num_nodes = 1  # 월 $15 절감
```

4. **사용하지 않을 때 삭제**
```bash
terraform destroy  # 비용 $0
```

### Prod 환경 (예상)
- **월 비용**: 약 $800 ~ $1,200
- **인스턴스 타입 업그레이드**: c5.large, db.r5.large
- **Reserved Instances**: 30-50% 절감 가능

---

## 🔧 트러블슈팅

### 1. Terraform 초기화 실패

**문제**:
```
Error: Failed to install provider
```

**해결**:
```bash
rm -rf .terraform .terraform.lock.hcl
terraform init
```

### 2. RDS 비밀번호 오류

**문제**:
```
Error: password does not meet policy requirements
```

**해결**:
- 최소 8자 이상
- 대문자, 소문자, 숫자 포함
- 특수문자 1개 이상

### 3. NAT Gateway 비용 문제

**해결**:
```hcl
# terraform.tfvars
enable_nat_gateway = false  # Dev 환경만
```

⚠️ **주의**: NAT Gateway 없으면 Private Subnet에서 인터넷 접근 불가

### 4. Auto Scaling 인스턴스가 안 뜸

**확인 사항**:
1. User Data 스크립트 로그 확인
```bash
aws ec2 describe-instances --filters "Name=tag:Name,Values=*web-instance*"
# 인스턴스 ID 확인 후
ssh ec2-user@<instance-ip>
sudo cat /var/log/user-data.log
```

2. Health Check 실패 확인
```bash
# ALB Target Health 확인
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
```

---

## 📝 모듈 구조

```
terraform-ticketing-platform/
├── main.tf                    # Root 모듈
├── variables.tf               # 변수 정의
├── outputs.tf                 # 출력값
├── terraform.tfvars          # 변수 값 (Git 제외)
│
├── modules/
│   ├── vpc/                  # VPC, Subnet, NAT
│   ├── security/             # Security Groups
│   ├── database/             # RDS Aurora
│   ├── cache/                # ElastiCache Redis
│   ├── compute/              # ALB, Auto Scaling
│   ├── storage/              # S3
│   ├── queue/                # SQS, SNS
│   └── monitoring/           # CloudWatch
│
└── scripts/
    ├── deploy.sh             # 배포 스크립트
    └── destroy.sh            # 삭제 스크립트
```

---

## 🎓 학습 포인트

### 1. Infrastructure as Code (IaC)
- Terraform 모듈화 설계
- State Management
- 변수 관리 (민감 정보 보호)

### 2. AWS 아키텍처
- 3-Tier Architecture
- Multi-AZ 고가용성
- Auto Scaling 정책

### 3. 보안
- VPC 격리 (Public/Private/DB)
- Security Group 최소 권한
- IAM Role 기반 권한 관리

### 4. 모니터링
- CloudWatch Metrics
- Alarms 설정
- SNS 알림

---

## 📞 문의

**프로젝트 관련 문의**:
- Email: gkstjdlr12@gmail.com
- GitHub: [@yourusername](https://github.com/yourusername)

---

## 📄 라이선스

MIT License - 자유롭게 사용하세요!

---

## 🙏 참고 자료

- [Terraform AWS Provider 문서](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

---

**⭐ 이 프로젝트가 도움이 되었다면 Star를 눌러주세요!**
