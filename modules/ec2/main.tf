resource "aws_launch_template" "app" {
  name_prefix = "${var.project}-app-template-"
  image_id    = "ami-0e2c8caa4b6378d8c" # Canonical Ubuntu 24.04 LTS AMI

  instance_type = var.instance_type

  iam_instance_profile {
    name = var.ec2_instance_profile_name
  }

  network_interfaces {
    associate_public_ip_address = false # Keeps instances secure in private subnets
    security_groups             = [var.app_security_group_id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              # Redirect all output to a log file so you can inspect it if needed
              exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
              
              export DEBIAN_FRONTEND=noninteractive
              
              # 1. Install Docker runtime layers AND jq on the Ubuntu host machine
              apt-get update -y
              apt-get install -y docker.io unzip jq curl
              
              systemctl start docker
              systemctl enable docker

              # 2. CRITICAL FIXED: Pointing to the real, official official AWS CLI v2 binary download link
              curl "https://amazonaws.com" -o "awscliv2.zip"
              unzip awscliv2.zip
              ./aws/install

              # 3. Authenticate securely to your private container registry
              aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${var.ecr_repository_url}
              
              # 4. DYNAMIC FIX: Pointing to your variable repository path
              docker pull ${var.ecr_repository_url}:latest

              # 5. Fetch parameter configurations securely from SSM Store
              FETCH_HOST=$(aws ssm get-parameter --name "/securecart/db/host" --region us-east-1 --query "Parameter.Value" --output text)
              FETCH_USER=$(aws ssm get-parameter --name "/securecart/db/username" --region us-east-1 --query "Parameter.Value" --output text)
              FETCH_SECRET_ARN=$(aws ssm get-parameter --name "/securecart/db/password_secret_arn" --region us-east-1 --query "Parameter.Value" --output text)

              # 6. Query Secrets Manager using the dynamic ARN metadata and parse cleanly via jq
              FETCH_REAL_PASS=$(aws secretsmanager get-secret-value --secret-id "$FETCH_SECRET_ARN" --region us-east-1 --query "SecretString" --output text | jq -r '.password')

              # 7. DYNAMIC FIX: Passing your variable registry image to the runner
              docker run -d \
                -p 8080:8080 \
                -e DB_HOST="$FETCH_HOST" \
                -e DB_USER="$FETCH_USER" \
                -e DB_PASSWORD="$FETCH_REAL_PASS" \
                -e DB_NAME="SecureCartDB" \
                --name securecart-service \
                --restart always \
                ${var.ecr_repository_url}:latest
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
