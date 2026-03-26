variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = "my-ec2-key"
}

variable "ami_name_filter" {
  description = "Filter for AMI name"
  type        = string
  default     = "amzn2-ami-hvm-*-x86_64-gp2"
}

variable "security_group_name" {
  description = "Name of the security group"
  type        = string
  default     = "allow-ssh-http-https"
}

variable "allowed_cidrs" {
  description = "CIDR blocks allowed for ingress"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}