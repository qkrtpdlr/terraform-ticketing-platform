#!/bin/bash
# scripts/deploy.sh
# Terraform 티켓팅 플랫폼 배포 스크립트

set -e  # 에러 발생 시 중단

echo "========================================="
echo "🚀 Terraform 티켓팅 플랫폼 배포 시작"
echo "========================================="

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. 환경 변수 파일 확인
if [ ! -f "terraform.tfvars" ]; then
    echo -e "${RED}❌ terraform.tfvars 파일이 없습니다!${NC}"
    echo -e "${YELLOW}💡 terraform.tfvars.example을 복사해서 생성하세요:${NC}"
    echo "   cp terraform.tfvars.example terraform.tfvars"
    echo "   nano terraform.tfvars  # 비밀번호 등 수정"
    exit 1
fi

# 2. Terraform 버전 확인
echo ""
echo "📌 1단계: Terraform 버전 확인"
terraform version

# 3. Terraform 초기화
echo ""
echo "📌 2단계: Terraform 초기화 (프로바이더 다운로드)"
terraform init

# 4. Terraform 포맷 체크
echo ""
echo "📌 3단계: 코드 포맷 확인"
terraform fmt -recursive

# 5. Terraform 유효성 검사
echo ""
echo "📌 4단계: 코드 유효성 검사"
terraform validate

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 코드 유효성 검사 통과!${NC}"
else
    echo -e "${RED}❌ 코드에 오류가 있습니다!${NC}"
    exit 1
fi

# 6. Terraform Plan
echo ""
echo "📌 5단계: 실행 계획 생성 (Plan)"
echo -e "${YELLOW}⚠️  생성될 리소스를 확인하세요...${NC}"
terraform plan -out=tfplan

# 7. 사용자 확인
echo ""
echo "========================================="
echo -e "${YELLOW}⚠️  주의: AWS 리소스가 생성되며 비용이 발생합니다!${NC}"
echo "========================================="
echo "예상 월 비용: 약 $365 (Dev 환경 기준)"
echo ""
read -p "배포를 진행하시겠습니까? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo -e "${RED}❌ 배포가 취소되었습니다.${NC}"
    rm -f tfplan
    exit 0
fi

# 8. Terraform Apply
echo ""
echo "📌 6단계: 인프라 배포 시작!"
echo -e "${GREEN}🚀 약 10-15분 소요됩니다. 커피 한 잔 하고 오세요! ☕${NC}"
terraform apply tfplan

# 9. 배포 완료
echo ""
echo "========================================="
echo -e "${GREEN}✅ 배포 완료!${NC}"
echo "========================================="

# Outputs 출력
terraform output connection_info

# 10. 정리
rm -f tfplan

echo ""
echo "========================================="
echo "💡 다음 단계:"
echo "========================================="
echo "1. 웹사이트 접속 테스트"
echo "   ALB DNS: $(terraform output -raw alb_dns_name)"
echo ""
echo "2. Auto Scaling 확인"
echo "   AWS Console → EC2 → Auto Scaling Groups"
echo ""
echo "3. RDS 접속 테스트"
echo "   mysql -h $(terraform output -raw rds_endpoint) -u admin -p"
echo ""
echo "4. 모니터링 확인"
echo "   AWS Console → CloudWatch → Dashboards"
echo ""
echo "========================================="
echo -e "${YELLOW}⚠️  인프라 삭제: ./scripts/destroy.sh${NC}"
echo "========================================="
