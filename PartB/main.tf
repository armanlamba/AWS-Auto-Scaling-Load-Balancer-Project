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
resource "aws_vpc" "vpc1" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "partbvpc"
  }
}
# Internet Gateway
resource "aws_internet_gateway" "ig1" {
  vpc_id = aws_vpc.vpc1.id

  tags = {
    Name = "project-gateway"
  }
}
# Route Table
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig1.id
  }

  tags = {
    Name = "project-route-table"
  }
}

# Subnets
resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.vpc1.id
  cidr_block              = "10.0.0.0/20"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet1"
  }
}


resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.vpc1.id
  cidr_block              = "10.0.16.0/20"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet2"
  }
}
resource "aws_subnet" "subnet3" {
  vpc_id                  = aws_vpc.vpc1.id
  cidr_block              = "10.0.32.0/20"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = true
  tags = {
    Name = "subnet3"
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
resource "aws_route_table_association" "subnet3" {
  subnet_id      = aws_subnet.subnet3.id
  route_table_id = aws_route_table.main.id
}
# Security Group
resource "aws_security_group" "partb" {
  vpc_id = aws_vpc.vpc1.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "rdp from everywhere"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "partb-rdp"
  }
}
# EC2 Instance
resource "aws_instance" "ws1" {
  ami                    = "ami-07d9456e59793a7d5"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet1.id
  vpc_security_group_ids = [aws_security_group.partb.id]

  user_data = <<-EOF
           
        # Install IIS server role
<powershell>
        Install-WindowsFeature -Name Web-Server -IncludeManagementTools
 
# Remove default html file if it exists

$defaultHtmlPath = "C:\inetpub\wwwroot\iisstart.html"

if (Test-Path -Path $defaultHtmlPath) {

    Remove-Item -Path $defaultHtmlPath -Force

}
 
# Add a new html file that displays server name

$newHtmlContent = "Hello World from $($env:COMPUTERNAME)"

$newHtmlPath = "C:\inetpub\wwwroot\index.html"

Add-Content -Path $newHtmlPath -Value $newHtmlContent
</powershell>
 
              EOF

  tags = {
    Name = "ws1"
  }
}
# EC2 Instance
resource "aws_instance" "ws2" {
  ami                    = "ami-07d9456e59793a7d5"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet2.id
  vpc_security_group_ids = [aws_security_group.partb.id]


  user_data = <<-EOF
           
        # Install IIS server role
<powershell>
        Install-WindowsFeature -Name Web-Server -IncludeManagementTools
 
# Remove default html file if it exists

$defaultHtmlPath = "C:\inetpub\wwwroot\iisstart.html"

if (Test-Path -Path $defaultHtmlPath) {

    Remove-Item -Path $defaultHtmlPath -Force

}
 
# Add a new html file that displays server name

$newHtmlContent = "Hello World from $($env:COMPUTERNAME)"

$newHtmlPath = "C:\inetpub\wwwroot\index.html"

Add-Content -Path $newHtmlPath -Value $newHtmlContent
</powershell>
 
              EOF

  tags = {
    Name = "ws2"
  }
}
# EC2 Instance
resource "aws_instance" "ws3" {
  ami                    = "ami-07d9456e59793a7d5"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet3.id
  vpc_security_group_ids = [aws_security_group.partb.id]

  user_data = <<-EOF
           
        # Install IIS server role
<powershell>
        Install-WindowsFeature -Name Web-Server -IncludeManagementTools
 
# Remove default html file if it exists

$defaultHtmlPath = "C:\inetpub\wwwroot\iisstart.html"

if (Test-Path -Path $defaultHtmlPath) {

    Remove-Item -Path $defaultHtmlPath -Force

}
 
# Add a new html file that displays server name

$newHtmlContent = "Hello World from $($env:COMPUTERNAME)"

$newHtmlPath = "C:\inetpub\wwwroot\index.html"

Add-Content -Path $newHtmlPath -Value $newHtmlContent
</powershell>
 
              EOF

  tags = {
    Name = "ws3"
  }
}
