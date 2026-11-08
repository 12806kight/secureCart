resource "aws_launch_template" "app" {
  name_prefix = "${var.project}-app-template-"
  image_id    = "ami-0e2c8caa4b6378d8c" # Canonical Ubuntu 24.04 LTS AMI for us-east-1.

  instance_type = var.instance_type

  # Crucial: Attaches the IAM profile required to authenticate and pull from ECR
  iam_instance_profile {
    name = var.ec2_instance_profile_name
  }

  network_interfaces {
    associate_public_ip_address = false # Keeps instances private
    security_groups             = [var.app_security_group_id]
  }

  # Updated User Data to install Docker, log into ECR, and run your container image
  user_data = base64encode(<<-EOF
              #!/bin/bash
              export DEBIAN_FRONTEND=noninteractive
              
              # 1. Update packages and install Docker on the Ubuntu host machine
              apt-get update -y
              apt-get install -y docker.io unzip
              
              # 2. Install the AWS CLI tool required for token authentication
              curl "https://amazonaws.com" -o "awscliv2.zip"
              unzip awscliv2.zip
              ./aws/install
              
              systemctl start docker
              systemctl enable docker

              # 3. Log into your private Amazon ECR Registry dynamically using the host's IAM context
              aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 298490729231.dkr.ecr.us-east-1.amazonaws.com

              # 4. Pull and boot up the latest version of your SecureCart container application
              docker pull ://amazonaws.com
              docker run -d \
                -p 8080:8080 \
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
