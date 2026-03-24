# Terraform Configuration Block
# Defines the version requirements for Terraform and providers

terraform {
  # Minimum Terraform version required
  required_version = "~> 1.13.5"

  # Provider requirements
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.20.0" # Allows 6.20.x versions (e.g., 6.20.0, 6.20.1)
    }
  }
}
