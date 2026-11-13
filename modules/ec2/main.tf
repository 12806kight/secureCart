resource "aws_launch_template" "app" {
  name_prefix   = "${var.project}-app-template-"
  image_id      = "ami-0e2c8caa4b6378d8c" # Canonical Ubuntu 24.04 LTS AMI
  instance_type = var.instance_type

  iam_instance_profile {
    name = var.ec2_instance_profile_name
  }

  # Enforce IMDSv2 to protect IAM role credentials from SSRF attacks
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  network_interfaces {
    associate_public_ip_address = false # Keeps instances secure in private subnets
    security_groups             = [var.app_security_group_id]
  }

  user_data = base64encode(<<EOF
#!/bin/bash
set -e
# Redirect non-sensitive setup logs so you can inspect boot progress
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

# 1. Install system utilities and python/pip dependencies
apt-get update -y
apt-get install -y jq curl unzip python3-pip python3-venv

# 2. Install the AWS CLI tool via Pip
python3 -m venv /opt/awscli-env
/opt/awscli-env/bin/pip install --upgrade pip setuptools wheel
/opt/awscli-env/bin/pip install awscli
ln -sf /opt/awscli-env/bin/aws /usr/local/bin/aws

# 3. Install Docker cleanly on Ubuntu 24.04 LTS
apt-get install -y docker.io

systemctl enable docker
systemctl start docker

# 4. Disable command tracing and pause console logging before handling secrets
set +x
exec > /dev/null 2>&1

# 5. Fetch active immutable image tag (falls back to latest if not yet set)
IMAGE_TAG=$(aws ssm get-parameter --name "/securecart/app/image_tag" --region us-east-1 --query "Parameter.Value" --output text 2>/dev/null || echo "latest")

# 6. Authenticate securely to ECR and pull the application image
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${var.ecr_repository_url}
docker pull ${var.ecr_repository_url}:"$IMAGE_TAG"

# 7. Fetch database configuration and credentials silently
FETCH_HOST=$(aws ssm get-parameter --name "/securecart/dev/db_host" --region us-east-1 --query "Parameter.Value" --output text)
FETCH_USER=$(aws ssm get-parameter --name "/securecart/db/username" --region us-east-1 --query "Parameter.Value" --output text)
FETCH_SECRET_ARN=$(aws ssm get-parameter --name "/securecart/db/password_secret_arn" --region us-east-1 --query "Parameter.Value" --output text)
FETCH_REAL_PASS=$(aws secretsmanager get-secret-value --secret-id "$FETCH_SECRET_ARN" --region us-east-1 --query "SecretString" --output text | jq -r '.password')

# 8. Start the SecureCart container without logging environment secrets
docker run -d \
  -p 8080:8080 \
  -e DB_HOST="$FETCH_HOST" \
  -e DB_USER="$FETCH_USER" \
  -e DB_PASSWORD="$FETCH_REAL_PASS" \
  -e DB_NAME="SecureCartDB" \
  --name securecart-service \
  --restart always \
  ${var.ecr_repository_url}:"$IMAGE_TAG"

# Clear sensitive shell variables from memory
unset FETCH_HOST FETCH_USER FETCH_SECRET_ARN FETCH_REAL_PASS IMAGE_TAG
EOF
  )

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.project}-launch-template"
    Environment = "development"
  }
}

resource "aws_autoscaling_group" "app_asg" {
  name_prefix         = "${var.project}-asg-"
  desired_capacity    = 2
  max_size            = 4
  min_size            = 1
  vpc_zone_identifier = var.private_subnet_ids

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  target_group_arns = [var.alb_target_group_arn]

  # Enables the ASG to safely substitute infrastructure under traffic
  lifecycle {
    create_before_destroy = true
  }

  # This forces instances to inherit naming conventions automatically
  tag {
    key                 = "Name"
    value               = "${var.project}-app-instance"
    propagate_at_launch = true
  }
}
