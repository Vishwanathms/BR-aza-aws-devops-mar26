# Provider Configuration
provider "aws" {
  region = "us-west-1"

}

# EC2 Instance Resource
# Creates a single EC2 instance in AWS
resource "aws_instance" "my_first_instance" {

  # AMI (Amazon Machine Image) - Amazon Linux 2023 for us-west-1
  ami = "ami-067ec7f9e54a67559"
  instance_type = "t3.micro"
  tags = {
    Name = "VM01"
    Owner = "Vishwa"
  }
}
