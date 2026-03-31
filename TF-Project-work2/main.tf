resource "aws_key_pair" "jenkins_key" {
  key_name   = var.key_name
  public_key = file("${path.module}/jenkins_master.pub")
}
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.region
}


# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Security group
resource "aws_security_group" "sg" {
  name        = var.security_group_name
  description = "Allow SSH, HTTP, and HTTPS inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = [var.ami_name_filter]
  }
}

# IAM Role for EC2
resource "aws_iam_role" "ec2_role" {
  name = "ec2-s3-full-access-role"

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
}

# Attach EC2 Full Access policy
resource "aws_iam_role_policy_attachment" "ec2_full_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

# Attach S3 Full Access policy
resource "aws_iam_role_policy_attachment" "s3_full_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Attach ECR Full Access policy
resource "aws_iam_role_policy_attachment" "ecr_full_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "ec2" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.jenkins_key.key_name
  vpc_security_group_ids      = [aws_security_group.sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

  root_block_device {
    volume_size = 20
  }
}

# ECR Repository
resource "aws_ecr_repository" "pythonapp" {
  name                 = "pythonapp"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Provision the instance
resource "null_resource" "provisioner" {
  depends_on = [aws_instance.ec2]

  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo amazon-linux-extras install docker -y",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",
      "sudo usermod -a -G docker ec2-user",
      "sudo curl -L \"https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
      "curl -LO \"https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl\"",
      "sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl",
      "curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64",
      "sudo install minikube-linux-amd64 /usr/local/bin/minikube",
      "sudo chmod +x /usr/local/bin/minikube",
      "sudo yum install java-17-amazon-corretto java-17-amazon-corretto-devel -y",
      "java -version",
      "mkdir -p /home/ec2-user/.ssh",
      "chmod 700 /home/ec2-user/.ssh"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = aws_instance.ec2.public_ip
    }
  }
}

# Jenkins Node Setup
resource "null_resource" "jenkins_node_setup" {
  depends_on = [null_resource.provisioner]

  # Copy Jenkins master public key to authorized_keys
  provisioner "file" {
    source      = "${path.module}/jenkins_master.pub"
    destination = "/tmp/jenkins_master.pub"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = aws_instance.ec2.public_ip
    }
  }

  # Configure SSH and verify Java installation
  provisioner "remote-exec" {
    inline = [
      "echo 'Setting up Jenkins node...'",
      "cat /tmp/jenkins_master.pub >> /home/ec2-user/.ssh/authorized_keys",
      "chmod 600 /home/ec2-user/.ssh/authorized_keys",
      "rm /tmp/jenkins_master.pub",
      "echo 'Jenkins SSH key added'",
      "java -version",
      "docker --version",
      "echo 'Jenkins node setup completed'"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = aws_instance.ec2.public_ip
    }
  }
}

# Output the public IP
output "instance_public_ip" {
  value = aws_instance.ec2.public_ip
}


# Output the ECR repository URL
output "ecr_repository_url" {
  value = aws_ecr_repository.pythonapp.repository_url
}

# Output Jenkins node info
output "jenkins_node_info" {
  value = {
    node_ip       = aws_instance.ec2.public_ip
    node_user     = "ec2-user"
    java_version  = "17"
    jenkins_user  = "ec2-user"
    node_home     = "/home/ec2-user"
  }
}