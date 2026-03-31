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



variable "private_key_path" {
  description = "Path to the private key PEM file for SSH (uploaded to Jenkins and available to Terraform)"
  type        = string
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

variable "key_name" {}