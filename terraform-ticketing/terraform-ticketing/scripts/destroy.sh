#!/bin/bash
# scripts/destroy.sh
# Terraform 인프라 삭제 스크립트

set -e

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "========================================="
echo -e "${RED}⚠️  인프라 삭제 (Destroy)${NC}"
echo "========================================="
echo ""
echo -e "${YELLOW}경고: 모든 AWS 리소스가 영구적으로 삭제됩니다!${NC}"
echo "  - VPC, Subnet, NAT Gateway"
echo "  - ALB, Auto Scaling Group, EC2 인스턴스"
echo "  - RDS Aurora 클러스터 (백업 포함)"
echo "  - ElastiCache Redis"
echo "  - S3 버킷 (비어있어야 삭제됨)"
echo "  - CloudWatch Logs"
echo ""
read -p "정말 삭제하시겠습니까? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo -e "${GREEN}✅ 삭제가 취소되었습니다.${NC}"
    exit 0
fi

echo ""
echo -e "${RED}⚠️  한 번 더 확인합니다!${NC}"
read -p "데이터를 복구할 수 없습니다. 계속하시겠습니까? (DELETE 입력): " final_confirm

if [ "$final_confirm" != "DELETE" ]; then
    echo -e "${GREEN}✅ 삭제가 취소되었습니다.${NC}"
    exit 0
fi

echo ""
echo "🗑️  인프라 삭제 중..."
echo ""

terraform destroy -auto-approve

echo ""
echo "========================================="
echo -e "${GREEN}✅ 모든 리소스가 삭제되었습니다!${NC}"
echo "========================================="
echo ""
echo "💰 더 이상 비용이 발생하지 않습니다."
echo ""
