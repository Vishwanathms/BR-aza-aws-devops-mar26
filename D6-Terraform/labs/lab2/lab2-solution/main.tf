# Provider Configuration
# Specifies which cloud provider to use and in which region
provider "aws" {
  region = "us-west-1"

  # IMPORTANT: Change 'userX' to your assigned student ID (user1, user2, etc.)
  default_tags {
    tags = {
      owner = "userX"
    }
  }
}

# EC2 Instance Resource with Tags
# Creates a single EC2 instance in AWS with organizational tags
resource "aws_instance" "drift_demo" {

  # AMI (Amazon Machine Image) - Amazon Linux 2023 for us-west-1
  ami = "ami-067ec7f9e54a67559"

  instance_type = "t3.micro"

  # Tags - Key-value pairs for resource organization and identification
  # Tags help you organize, track costs, and manage resources
  tags = {
    Name        = "DriftDemoUserX"  # Human-readable name for the instance
    Environment = "Training"        # Which environment (Dev, Staging, Prod, etc.)
    # Comment out this line to accept the drift after creating this
    # tag using aws cli.
    # Team        = "DevOps"          
  }
}
