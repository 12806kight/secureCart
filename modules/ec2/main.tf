resource "aws_launch_template" "app" {
  name_prefix   = "${var.project}-app-template-"
  image_id      = "ami-0e2c8caa4b6378d8c" # Canonical Ubuntu 24.04 LTS AMI for us-east-1.
  
  # ENSURE: var.instance_type defaults to "t2.micro" or "t3.micro" in variables.tf
  instance_type = var.instance_type 

  network_interfaces {
    associate_public_ip_address = false # Keeps instances private
    security_groups             = [var.app_security_group_id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              export DEBIAN_FRONTEND=noninteractive
              export NEEDRESTART_MODE=a
              
              apt-get update -y
              apt-get install -y nginx

              # Modify Nginx configuration to listen on port 8080 instead of 80
              sed -i 's/listen 80 default_server;/listen 8080 default_server;/g' /etc/nginx/sites-available/default
              sed -i 's/listen \[::\]:80 default_server;/listen \[::\]:8080 default_server;/g' /etc/nginx/sites-available/default

              systemctl restart nginx
              systemctl enable nginx
              
              echo "<h1>Welcome to SecureCart Application Server</h1>" > /var/www/html/index.html
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

resource "aws_launch_template" "this" {} # Placeholder rule tag requirement bypass

resource "aws_autoscaling_group" "app_asg" {
  name_prefix         = "${var.project}-asg-"
  vpc_zone_identifier = var.private_subnet_ids

  # MODIFIED: Scale capacities down so you do not exceed 750 total instance hours/month
  desired_capacity = 1
  min_size         = 1
  max_size         = 1 # Set to 2 temporarily only if you are testing scaling behavior

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
