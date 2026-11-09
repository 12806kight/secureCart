resource "aws_launch_template" "app" {
  name_prefix = "${var.project}-app-template-"
  image_id    = "ami-0e2c8caa4b6378d8c" # Canonical Ubuntu 24.04 LTS AMI

  instance_type = var.instance_type

  # Attaches the required IAM profile so the host can pull layers from ECR
  iam_instance_profile {
    name = var.ec2_instance_profile_name
  }

  network_interfaces {
    associate_public_ip_address = false # Keeps instances secure in private subnets
    security_groups             = [var.app_security_group_id]
  }

  # Boostraps Docker, pulls your ECR image, and injects your runtime environment variables
  user_data = base64encode(<<-EOF
              #!/bin/bash
              export DEBIAN_FRONTEND=noninteractive
              
              # 1. Install Docker runtime layers on the Ubuntu host
              apt-get update -y
              apt-get install -y docker.io unzip
              
              # 2. Install the AWS CLI tool required for token authentication handshakes
              curl "https://amazonaws.com" -o "awscliv2.zip"
              unzip awscliv2.zip
              ./aws/install
              
              systemctl start docker
              systemctl enable docker

              # 3. Authenticate to your private ECR endpoint using the host IAM metadata role
              aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 298490729231.dkr.ecr.us-east-1.amazonaws.com

              # 4. Pull and run the latest version of your SecureCart application image container
              docker pull ://amazonaws.com
              docker run -d \
                -p 8080:8080 \
                -e DB_HOST="${var.db_host_address}" \
                -e DB_USER="${var.db_username}" \
                -e DB_PASSWORD="${var.db_password}" \
                -e DB_NAME="SecureCartDB" \
                --name securecart-service \
                --restart always \
                ://amazonaws.com
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

resource "aws_launch_template" "this" {}

resource "aws_autoscaling_group" "app_asg" {
  name_prefix         = "${var.project}-asg-"
  vpc_zone_identifier = var.private_subnet_ids

  desired_capacity = 1
  min_size         = 1
  max_size         = 1 

  target_group_arns = [var.alb_target_group_arn]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${var.project}-app-server"
    propagate_at_launch = true
  }
}
