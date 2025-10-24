variable "ec2_sg_name" {}
variable "vpc_id" {}
variable "public_subnet_cidr_block" {}
variable "alb_sg_name" {}


resource "aws_security_group" "ec2_sg_http" {
  name        = var.ec2_sg_name
  description = "Enable the Port 443(https) & Port 80(http)"
  vpc_id      = var.vpc_id

  # enable http
  ingress {
    description = "Allow HTTP request from anywhere"
    security_groups = [ aws_security_group.alb_sg_http.id ]
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }

  # enable http
  ingress {
    description = "Allow HTTP request from anywhere"
    security_groups = [ aws_security_group.alb_sg_http.id ]
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  }

  #Outgoing request
  egress {
    description = "Allow outgoing request"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "EC2 Security Groups to allow HTTP and HTTPS"
  }
}

# Security Group for ALB
resource "aws_security_group" "alb_sg_http" {
  name        = var.alb_sg_name
  description = "Allow access to Ec2 instances from ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # enable https
  ingress {
    description = "Allow HTTPs request from anywhere"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  }
  #Outgoing request
  egress {
    description = "Allow outgoing request"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "ALB Security Groups to allow HTTP and HTTPS"
  }
}

/*
resource "aws_security_group" "ec2_sg_python_api" {
  name        = var.ec2_sg_name_for_python_api
  description = "Enable the Port 5000 for python api"
  vpc_id      = var.vpc_id

  # ssh for terraform remote exec
  ingress {
    description = "Allow traffic on port 5000"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
  }

  tags = {
    Name = "Security Groups to allow traffic on port 5000"
  }
} */

output "sg_alb" {
    value = aws_security_group.alb_sg_http.id
}

output "sg_ec2" {
  value = aws_security_group.ec2_sg_http.id
}