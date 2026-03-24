provider "aws" {
  region = "us-west-1"

  # IMPORTANT: Change 'userX' to your assigned student ID (user1, user2, etc.)
  default_tags {
    tags = {
      owner = "userX"
    }
  }
}


resource "aws_ssm_parameter" "db_password" {
  # IMPORTANT: Change 'user1' to your assigned student ID (user1, user2, etc.)
  name        = "/dev/database/master-password-userX"
  description = "Updated: Master password for development database"
  type        = "SecureString"  # Encrypted in AWS!
  value       = "InsecurePassword"  # DEMO ONLY - never do this in production!
}

/*
resource "aws_db_instance" "main" {
  identifier           = "banking-app-db"
  allocated_storage    = 20
  engine              = "mysql"
  engine_version      = "8.0.43"
  instance_class      = "db.t3.micro"
  db_name             = "banking"
  username            = "admin"

  # Reference the password from SSM Parameter Store
  password = data.aws_ssm_parameter.db_password.value

  skip_final_snapshot = true
  apply_immediately   = true
}
*/