# modules/compute/main.tf

# ==========================================
# Data Source: Latest Amazon Linux 2023 AMI
# ==========================================
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ==========================================
# IAM Role for EC2
# ==========================================
resource "aws_iam_role" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-ec2-role"
      Environment = var.environment
    },
    var.tags
  )
}

# EC2가 S3, ECR, CloudWatch에 접근할 수 있도록 정책 연결
resource "aws_iam_role_policy_attachment" "ec2_s3" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "ec2_ecr" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2.name

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-ec2-profile"
      Environment = var.environment
    },
    var.tags
  )
}

# ==========================================
# Launch Template
# ==========================================
resource "aws_launch_template" "web" {
  name_prefix   = "${var.project_name}-${var.environment}-web-"
  image_id      = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type
  key_name      = var.key_name != "" ? var.key_name : null

  vpc_security_group_ids = [var.ec2_security_group_id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  # User Data (인스턴스 시작 스크립트)
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    db_endpoint   = var.db_endpoint
    db_name       = var.db_name
    db_username   = var.db_username
    db_password   = var.db_password
    redis_endpoint = var.redis_endpoint
    s3_bucket     = var.s3_bucket_name
    environment   = var.environment
    ecr_url       = ""  # ECR URL 추가 필요
  }))

  # 모니터링 활성화
  monitoring {
    enabled = true
  }

  # 인스턴스 메타데이터 설정 (IMDSv2 강제)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      {
        Name        = "${var.project_name}-${var.environment}-web-instance"
        Environment = var.environment
      },
      var.tags
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(
      {
        Name        = "${var.project_name}-${var.environment}-web-volume"
        Environment = var.environment
      },
      var.tags
    )
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ==========================================
# Auto Scaling Group
# ==========================================
resource "aws_autoscaling_group" "web" {
  name                = "${var.project_name}-${var.environment}-web-asg"
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [aws_lb_target_group.web.arn]
  
  health_check_type         = "ELB"
  health_check_grace_period = 300
  
  min_size         = var.min_size
  desired_capacity = var.desired_capacity
  max_size         = var.max_size
  
  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  # 인스턴스 종료 시 정책
  termination_policies = ["OldestInstance"]
  
  # 인스턴스 새로고침 설정
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupMaxSize",
    "GroupMinSize",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-web-asg"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}

# ==========================================
# Auto Scaling Policies
# ==========================================

# CPU 기반 스케일링
resource "aws_autoscaling_policy" "cpu_scale_up" {
  name                   = "${var.project_name}-${var.environment}-cpu-scale-up"
  autoscaling_group_name = aws_autoscaling_group.web.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# ALB 요청 수 기반 스케일링
resource "aws_autoscaling_policy" "request_count_scale" {
  name                   = "${var.project_name}-${var.environment}-request-scale"
  autoscaling_group_name = aws_autoscaling_group.web.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.main.arn_suffix}/${aws_lb_target_group.web.arn_suffix}"
    }
    target_value = 1000.0  # 인스턴스당 1000 요청
  }
}

# ==========================================
# Application Load Balancer
# ==========================================
resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.environment == "prod" ? true : false
  enable_http2               = true
  enable_cross_zone_load_balancing = true

  # 접근 로그 (선택 사항)
  # access_logs {
  #   bucket  = var.log_bucket_name
  #   enabled = true
  # }

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-alb"
      Environment = var.environment
    },
    var.tags
  )
}

# ==========================================
# Target Group
# ==========================================
resource "aws_lb_target_group" "web" {
  name     = "${var.project_name}-${var.environment}-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  # Health Check 설정
  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = var.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  # 연결 유지 (Sticky Session)
  stickiness {
    type            = "lb_cookie"
    cookie_duration = 3600
    enabled         = true
  }

  # 느린 시작 모드 (새 인스턴스에 점진적으로 트래픽 전송)
  slow_start = 30

  # Connection Draining
  deregistration_delay = 30

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-tg"
      Environment = var.environment
    },
    var.tags
  )
}

# ==========================================
# ALB Listener - HTTP (80)
# ==========================================
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  # HTTP를 HTTPS로 리다이렉트 (HTTPS 설정 시)
  default_action {
    type = var.certificate_arn != "" ? "redirect" : "forward"

    dynamic "redirect" {
      for_each = var.certificate_arn != "" ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    target_group_arn = var.certificate_arn != "" ? null : aws_lb_target_group.web.arn
  }
}

# ==========================================
# ALB Listener - HTTPS (443)
# ==========================================
resource "aws_lb_listener" "https" {
  count             = var.certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}
