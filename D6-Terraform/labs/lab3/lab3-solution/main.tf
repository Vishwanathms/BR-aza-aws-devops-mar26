provider "aws" {
  region = "us-west-1"

  # IMPORTANT: Change 'userX' to your assigned student ID (user1, user2, etc.)
  default_tags {
    tags = {
      owner = "userX"
    }
  }
}

# Security Group - base security group (rules defined separately)
resource "aws_security_group" "web_sg" {
  name        = "lab3-web-sg-UserX"
  description = "Security group for web server"

  tags = {
    Name = "lab3-web-sg-UserX"
    Lab  = "lab3"
  }
}

# Security Group Rule - HTTP ingress
resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.web_sg.id
  description       = "HTTP"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "lab3-http-rule-UserX"
    Lab  = "lab3"
  }
}

/*
# Security Group Rule - HTTPS ingress (uncomment for incremental change step)
resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.web_sg.id
  description       = "HTTPS"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "lab3-https-rule-UserX"
    Lab  = "lab3"
  }
}
*/

# Security Group Rule - Allow all outbound
resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.web_sg.id
  description       = "Allow all outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "lab3-egress-rule-UserX"
    Lab  = "lab3"
  }
}

# IAM Role for EC2
resource "aws_iam_role" "ec2_role" {
  name = "lab3-ec2-role-UserX"

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

  tags = {
    Name = "lab3-ec2-role-UserX"
    Lab  = "lab3"
  }
}

# IAM Instance Profile - connects the role to EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "lab3-ec2-profile-UserX"
  role = aws_iam_role.ec2_role.name
}

# EC2 Instance - uses the security group and IAM profile
resource "aws_instance" "web_server" {
  ami                    = "ami-067ec7f9e54a67559"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "lab3-web-server-UserX"
    Lab  = "lab3"
  }
}
