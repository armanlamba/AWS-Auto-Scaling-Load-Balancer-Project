terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.27"
    }
  }

  required_version = ">=0.14"
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "192.168.0.0/16"

  tags = {
    Name = "projectvpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "project-gateway"
  }
}

# Route Table
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "project-route-table"
  }
}

# Subnets
resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "192.168.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "subnet1"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "192.168.50.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "subnet2"
  }
}

# Associate Route Table with Subnets
resource "aws_route_table_association" "subnet1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.main.id
}

resource "aws_route_table_association" "subnet2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.main.id
}

# Security Group
resource "aws_security_group" "allow_http" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description      = "SSH from everywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_http"
  }
}

# IAM Role
resource "aws_iam_role" "instance_role" {
  name = "project-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "project-instance-role"
  }
}

# IAM Policy for the Role
resource "aws_iam_role_policy" "instance_policy" {
  name = "project-instance-policy"
  role = aws_iam_role.instance_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
          "ec2:Get*",
          "ec2:List*",
          "ec2:RunInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:TerminateInstances"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "instance_profile" {
  name = "project-instance-profile"
  role = aws_iam_role.instance_role.name

  tags = {
    Name = "project-instance-profile"
  }
}

# EC2 Instance
resource "aws_instance" "web" {
  ami                    = "ami-0b72821e2f351e396" # Amazon Linux 2023 AMI
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet1.id
  vpc_security_group_ids = [aws_security_group.allow_http.id]
  iam_instance_profile   = aws_iam_instance_profile.instance_profile.name

  user_data = <<-EOF
              #!/bin/bash
              # Update the package repository
              yum -y update

              # Install Apache web server
              yum -y install httpd

              # Retrieve instance ID from metadata using IMDSv2
              TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
              instance_id=`curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/instance-id`

              # Create a simple web page with the instance ID
              echo "<h1>Welcome to Arman Lamba. My instance ID is $instance_id</h1>" > /var/www/html/index.html

              # Start the Apache web server
              systemctl start httpd

              # Enable Apache to start on boot
              systemctl enable httpd
              EOF

  tags = {
    Name = "instance1"
  }
}

# Launch Configuration
resource "aws_launch_configuration" "example" {
  name                 = "projectlaunchconfig"
  image_id             = aws_instance.web.ami
  instance_type        = aws_instance.web.instance_type
  security_groups      = [aws_security_group.allow_http.id]
  iam_instance_profile = aws_iam_instance_profile.instance_profile.name

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.id
  min_size             = 2
  desired_capacity     = 2
  max_size             = 6
  vpc_zone_identifier  = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]

  tag {
    key                 = "project"
    value               = "example-instance"
    propagate_at_launch = true
  }
}

# ALB
resource "aws_lb" "example" {
  name               = "project-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_http.id]
  subnets            = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]

  tags = {
    Name = "project-lb"
  }
}

# Target Group
resource "aws_lb_target_group" "example" {
  name     = "project-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "project-tg"
  }
}

# Listener
resource "aws_lb_listener" "example" {
  load_balancer_arn = aws_lb.example.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example.arn
  }

  tags = {
    Name = "project-listener"
  }
}

# Auto Scaling Policies
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale_up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.example.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale_down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.example.name
}

# Auto Scaling Target Tracking Policy
resource "aws_autoscaling_policy" "target_tracking" {
  name                   = "target_tracking"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.example.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 5.0
  }
}
