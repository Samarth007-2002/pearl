provider "aws" {
  region = "us-east-1"  # Change to your preferred region
}

# VPC Setup
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Subnet Setup (Public Subnet)
resource "aws_subnet" "main_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"  # Update as needed
  map_public_ip_on_launch = true
}

# Internet Gateway for Internet Access
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
}

# Route Table to Route Traffic to the Internet Gateway
resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.main_vpc.id
}

# Route to the Internet Gateway
resource "aws_route" "internet_access_route" {
  route_table_id         = aws_route_table.main_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main_igw.id
}

# Associate the Route Table with the Subnet
resource "aws_route_table_association" "main_route_table_assoc" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main_route_table.id
}

# Security Group allowing SSH and HTTP
resource "aws_security_group" "allow_ssh_http" {
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Launch Template for EC2 instances with User Data to start a simple HTTP server
resource "aws_launch_template" "ec2_launch_template" {
  name_prefix   = "autoscaling-template-"
  image_id      = "ami-0866a3c8686eaeeba"  # Example Amazon Linux AMI; change as needed
  instance_type = "t2.micro"

  network_interfaces {
    security_groups             = [aws_security_group.allow_ssh_http.id]
    associate_public_ip_address = true
  }

 

  # User Data script to set up a simple HTTP server
  user_data = base64encode(<<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install python3 -y
              set +o histexpand
              echo "<h1>Hello, World!</h1>" > /home/ubuntu/index.html
              sudo nohup python3 -m http.server 8000 --bind 0.0.0.0 &
              EOF
  )  

  lifecycle {
    create_before_destroy = true
  }
}

# Autoscaling Group
resource "aws_autoscaling_group" "ec2_asg" {
  desired_capacity     = 1
  max_size             = 3
  min_size             = 1
  vpc_zone_identifier  = [aws_subnet.main_subnet.id]
  launch_template {
    id      = aws_launch_template.ec2_launch_template.id
    version = "$Latest"
  }
  health_check_type    = "EC2"
  health_check_grace_period = 300
  tag {
    key                 = "Name"
    value               = "autoscaling-instance"
    propagate_at_launch = true
  }
}

# Outputs (Optional)
output "autoscaling_group_id" {
  value = aws_autoscaling_group.ec2_asg.id
}
