#!/bin/bash
# modules/compute/user-data.sh
# EC2 인스턴스 시작 시 자동 실행되는 스크립트

set -e  # 에러 발생 시 스크립트 중단

# ==========================================
# 시스템 업데이트
# ==========================================
echo "=== 시스템 업데이트 시작 ==="
yum update -y

# ==========================================
# Docker 설치
# ==========================================
echo "=== Docker 설치 시작 ==="
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# ==========================================
# Docker Compose 설치
# ==========================================
echo "=== Docker Compose 설치 시작 ==="
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# ==========================================
# CloudWatch Agent 설치
# ==========================================
echo "=== CloudWatch Agent 설치 시작 ==="
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm
rm -f ./amazon-cloudwatch-agent.rpm

# ==========================================
# 환경 변수 설정
# ==========================================
echo "=== 환경 변수 설정 ==="
cat <<EOF > /etc/environment
DB_HOST=${db_endpoint}
DB_PORT=3306
DB_NAME=${db_name}
DB_USER=${db_username}
DB_PASSWORD=${db_password}
REDIS_HOST=${redis_endpoint}
REDIS_PORT=6379
S3_BUCKET=${s3_bucket}
AWS_REGION=ap-northeast-2
ENVIRONMENT=${environment}
EOF

# ==========================================
# 애플리케이션 디렉토리 생성
# ==========================================
mkdir -p /opt/ticketing-app
cd /opt/ticketing-app

# ==========================================
# Docker 이미지 Pull 및 실행
# ==========================================
# 주의: ECR 이미지 URL을 실제 값으로 변경하세요!
# 예: 123456789012.dkr.ecr.ap-northeast-2.amazonaws.com/ticketing-app:latest

echo "=== Docker 컨테이너 실행 준비 ==="
# ECR 로그인 (IAM Role 필요)
aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin ${ecr_url}

# Docker 이미지 Pull
# docker pull ${ecr_url}/ticketing-app:latest

# Docker 컨테이너 실행
# docker run -d \
#   --name ticketing-app \
#   --restart always \
#   -p 8080:8080 \
#   --env-file /etc/environment \
#   ${ecr_url}/ticketing-app:latest

# ==========================================
# 간단한 테스트용 웹 서버 실행 (임시)
# ==========================================
echo "=== 테스트 웹 서버 실행 ==="
cat <<'EOFHTML' > /opt/ticketing-app/index.html
<!DOCTYPE html>
<html>
<head>
    <title>Ticketing Platform</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            text-align: center;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
        }
        .container {
            background: rgba(255,255,255,0.1);
            padding: 40px;
            border-radius: 10px;
            backdrop-filter: blur(10px);
        }
        h1 { font-size: 3em; margin-bottom: 20px; }
        .info { margin: 20px 0; padding: 20px; background: rgba(255,255,255,0.2); border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎫 Ticketing Platform</h1>
        <p>고가용성 티켓팅 시스템</p>
        <div class="info">
            <p><strong>Environment:</strong> ${environment}</p>
            <p><strong>Instance ID:</strong> <span id="instance-id">Loading...</span></p>
            <p><strong>Availability Zone:</strong> <span id="az">Loading...</span></p>
        </div>
        <p>✅ Health Check OK</p>
    </div>
    <script>
        // 인스턴스 메타데이터 가져오기
        fetch('http://169.254.169.254/latest/meta-data/instance-id')
            .then(r => r.text())
            .then(id => document.getElementById('instance-id').textContent = id);
        fetch('http://169.254.169.254/latest/meta-data/placement/availability-zone')
            .then(r => r.text())
            .then(az => document.getElementById('az').textContent = az);
    </script>
</body>
</html>
EOFHTML

# Python 간단 웹 서버 실행
yum install -y python3
nohup python3 -m http.server 8080 --directory /opt/ticketing-app > /var/log/web-server.log 2>&1 &

# ==========================================
# Health Check 엔드포인트 생성
# ==========================================
mkdir -p /opt/ticketing-app/health
echo "OK" > /opt/ticketing-app/health/index.html

echo "=== 사용자 데이터 스크립트 완료 ==="
