# Lab 3: Working with Multiple Resources
## Student Instructions

---

## Objective
Learn how Terraform manages multiple dependent resources and handles incremental changes.

## Time Estimate
35-40 minutes

---

## What You'll Learn
- Creating multiple AWS resources in one configuration
- Understanding resource dependencies
- Making incremental changes to infrastructure
- How Terraform determines resource creation order
- Exploring the Terraform state

---

## Prerequisites
- Completed Labs 1 and 2
- Understanding of Terraform basic workflow
- AWS CLI configured
- Lab region: us-west-1

---

## IMPORTANT: Unique Resource Names

**You are sharing an AWS account with other students.**

Throughout this lab, you will see placeholder text **`UserX`** in resource names.

**You MUST replace every instance of `UserX` with your assigned user ID** (e.g., `User1`, `User2`, `User3`, etc.).

**Example:**
- If you are assigned **User5**, change:
  - `"lab3-web-sg-UserX"` → `"lab3-web-sg-User5"`
  - `"lab3-ec2-role-UserX"` → `"lab3-ec2-role-User5"`

**Why is this critical?**
- Security Group names must be unique within the VPC
- IAM Role and Instance Profile names must be unique within the AWS account
- Without unique names, your `terraform apply` will fail with "already exists" errors

---

## High-Level Instructions

1. **Create project directory**

2. **Write configuration files**
   - `terraform.tf`
   - `main.tf` with 6 resources:
     - Security Group (base group)
     - Security Group Ingress Rule (HTTP)
     - Security Group Egress Rule (all outbound)
     - IAM Role for EC2
     - IAM Instance Profile
     - EC2 Instance

3. **Initialize and validate**

4. **Review execution plan and observe dependencies**

---

5. **Apply configuration and verify with AWS CLI**

6. **Make incremental change** (add HTTPS to security group)

7. **Apply change and observe update behavior**

8. **Explore the state file**

9. **Clean up resources**

---

## Documentation Related to This Lab

**Security Groups:**
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group

**Security Group Ingress Rule:**
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule

**Security Group Egress Rule:**
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule

**IAM Role:**
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role

**IAM Instance Profile:**
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile

---

## Detailed Instructions

### Step 1: Create Project Directory

Create and navigate to your lab directory:
```bash
cd
mkdir lab3-workflow-drill
cd lab3-workflow-drill
```

---

### Step 2: Create Terraform Configuration Files

**Create `terraform.tf`** - Terraform settings:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.20.0"
    }
  }
  required_version = "~> 1.13.5"
}
```

---

**Create `main.tf`** - Infrastructure configuration:

```hcl
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
```

**Understanding `name` vs `Name` Tag:**

You'll notice this resource has both a `name` attribute and a `Name` tag. Here's why both are needed:

- **`name` attribute** - The actual AWS resource name (required by AWS)
  - Used by AWS APIs and CLI commands
  - Must be unique within your AWS account/region
  - This is what AWS uses internally to identify the security group

- **`Name` tag** - A metadata tag for human readability (optional but recommended)
  - Appears as the display name in the AWS Console
  - Makes resources easy to find and identify visually
  - Just a key-value pair like any other tag

**Best practice:** Set both to the same value for consistency. This pattern applies to IAM roles and other resources that support both a `name` attribute and tags.

---

**IMPORTANT SECURITY NOTE:**
These security group rules use `cidr_ipv4 = "0.0.0.0/0"` which allows access from ANY IP address on the internet. This is acceptable for training purposes only. In production environments:
- Restrict ingress to specific IP ranges (e.g., your organization's CIDR blocks)
- Use security group references for inter-service communication
- Consider using AWS WAF for web application protection
- Follow the principle of least privilege access

---

```hcl
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
```

---

```hcl
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
```

---

```hcl
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
```

---

### Step 3: Initialize Terraform

Download required providers:
```bash
terraform init
```

**Success indicators:**
- Message: "Terraform has been successfully initialized!"
- Creates `.terraform/` directory
- Creates `.terraform.lock.hcl` file

---

### Step 4: Validate and Format

Check for syntax errors and format code:
```bash
terraform validate
terraform fmt
```

**Success indicators:**
- "Success! The configuration is valid."
- Files are properly formatted

---

### Step 5: Review Execution Plan

Preview what Terraform will create:
```bash
terraform plan
```

**What to observe:**
- `Plan: 6 to add, 0 to change, 0 to destroy`
- Six resources will be created:
  - aws_security_group.web_sg
  - aws_vpc_security_group_ingress_rule.http
  - aws_vpc_security_group_egress_rule.all_outbound
  - aws_iam_role.ec2_role
  - aws_iam_instance_profile.ec2_profile
  - aws_instance.web_server

---

**Understanding Dependencies:**

Look at the plan output carefully. Notice:
- Security Group and IAM Role have no dependencies (created first in parallel)
- Security Group Rules depend on Security Group (created next)
- IAM Instance Profile depends on IAM Role
- EC2 Instance depends on Security Group and Instance Profile

Terraform automatically detects these dependencies by analyzing resource references!

---

### Step 6: Apply Configuration

Create all resources:
```bash
terraform apply
```

Type `yes` when prompted.

**What happens:**
- Resources are created in dependency order
- Security Group and IAM Role created first (parallel)
- Security Group Rules created next (depend on Security Group)
- IAM Instance Profile created (depends on IAM Role)
- EC2 Instance created last (depends on Security Group and Instance Profile)
- Message: "Apply complete! Resources: 6 added"

---

### Step 7: Verify Resources with AWS CLI

**Get instance details:**
```bash
# Get instance ID from Terraform state
INSTANCE_ID=$(terraform state show aws_instance.web_server | grep "\"i-" | awk '{print $3}' | tr -d '"')

# Check instance status
aws ec2 describe-instances --instance-ids $INSTANCE_ID \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType]' \
  --output table
```

---

**Check security group rules:**
```bash
# Get security group ID from Terraform state
SG_ID=$(terraform state show aws_security_group.web_sg | grep "\"sg-" | awk '{print $3}' | tr -d '"')

# View security group rules
aws ec2 describe-security-groups --group-ids $SG_ID \
  --query 'SecurityGroups[*].IpPermissions[*].[FromPort,ToPort,IpProtocol]' \
  --output table
```

You should see one rule: HTTP (port 80)

---

**Check IAM role:**
```bash
# Get role name from Terraform state
ROLE_NAME=$(terraform state show aws_iam_role.ec2_role | grep 'name ' | grep -v 'name_prefix' | head -1 | awk '{print $3}' | tr -d '"')

# View IAM role details
aws iam get-role --role-name $ROLE_NAME \
  --query 'Role.[RoleName,Arn]' \
  --output table
```

---

### Step 8: Make Incremental Change

Now let's add HTTPS access to our security group by adding a new security group rule.

**Edit `main.tf`** and add this new resource (after the HTTP ingress rule):

```hcl
# Security Group Rule - HTTPS ingress
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
```

---

### Step 9: Plan the Change

Preview the incremental change:
```bash
terraform plan
```

**What to observe:**
- `Plan: 1 to add, 0 to change, 0 to destroy`
- A new security group rule resource will be created
- Symbol: `+` means "create new resource"
- The security group, EC2 instance, and other resources will **NOT** be modified!

This demonstrates **incremental infrastructure changes** - adding new resources without affecting existing ones.

---

### Step 10: Apply the Change

Apply the incremental change:
```bash
terraform apply
```

Type `yes` when prompted.

**What happens:**
- A new security group rule resource is created
- The security group automatically picks up the new rule
- EC2 instance remains running with the same ID
- Message: "Apply complete! Resources: 1 added, 0 changed, 0 destroyed"

---

### Step 11: Verify the Update

Check that the HTTPS rule was added:
```bash
# View updated security group rules
aws ec2 describe-security-groups --group-ids $SG_ID \
  --query 'SecurityGroups[*].IpPermissions[*].[FromPort,ToPort,IpProtocol]' \
  --output table
```

You should now see two rules: HTTP (80) and HTTPS (443)

---

### Step 12: Explore Terraform State

The state file tracks all managed resources.

**List all resources:**
```bash
terraform state list
```

You should see:
```
aws_iam_instance_profile.ec2_profile
aws_iam_role.ec2_role
aws_instance.web_server
aws_security_group.web_sg
aws_vpc_security_group_egress_rule.all_outbound
aws_vpc_security_group_ingress_rule.http
aws_vpc_security_group_ingress_rule.https
```

---

**Show detailed information for specific resources:**
```bash
# View EC2 instance details
terraform state show aws_instance.web_server

# View security group details
terraform state show aws_security_group.web_sg

# View security group rule details
terraform state show aws_vpc_security_group_ingress_rule.http

# View IAM role details
terraform state show aws_iam_role.ec2_role
```

---

### Step 13: Optional - Visualize Dependencies

Generate a dependency graph:
```bash
terraform graph
```

This outputs a graph in DOT format showing resource dependencies.

---

### Step 14: Clean Up Resources

Destroy all resources:
```bash
terraform destroy
```

Type `yes` when prompted.

**What to observe:**
- Resources are destroyed in **reverse dependency order**
- EC2 Instance destroyed first
- IAM Instance Profile destroyed next
- Security Group Rules destroyed (depend on Security Group)
- Security Group and IAM Role destroyed last (parallel)

---

**Verify destruction:**
```bash
# Should return "terminated" or error
aws ec2 describe-instances --instance-ids $INSTANCE_ID \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' \
  --output table 2>/dev/null || echo "Instance destroyed"
```

---

## Key Concepts

### Resource Dependencies

**Implicit Dependencies** (Terraform detects automatically):
- Created by referencing one resource in another
- Example: `vpc_security_group_ids = [aws_security_group.web_sg.id]`
- Example: `role = aws_iam_role.ec2_role.name`

**Dependency Chain:**
```
Security Group ──> SG Rules (ingress/egress)
                         │
                         ├──> EC2 Instance
                         │
IAM Role ──> Instance Profile ──┘
```

---

### Plan Output Symbols

Understanding what Terraform will do:

| Symbol | Meaning |
|--------|---------|
| `+` | Create new resource |
| `-` | Destroy resource |
| `~` | Update in-place (modify existing) |
| `-/+` | Destroy and recreate (replace) |
| `<=` | Read data source |

---

### In-Place Updates vs. Replacements

**In-Place Update** (no disruption):
- Modifying security group rules
- Changing tags
- Updating instance metadata

**Replacement** (resource recreated):
- Changing AMI
- Changing instance type (usually)
- Changing availability zone

---

## Challenge Exercise (Optional)

**Objective:** Refactor security group configuration into a separate file for better code organization.

Currently, all resources are in `main.tf`. As projects grow, organizing resources into logical files improves maintainability and readability.

**Your Task:**
1. Create a new file called `vpc.tf` in your lab directory
2. Move the following security group resources from `main.tf` to `vpc.tf`:
   - `aws_security_group.web_sg`
   - `aws_vpc_security_group_ingress_rule.http`
   - `aws_vpc_security_group_ingress_rule.https` (if you added it)
   - `aws_vpc_security_group_egress_rule.all_outbound`

**Steps:**
1. Create `vpc.tf` file
2. Copy security group resources from `main.tf` to `vpc.tf`
3. Delete those resources from `main.tf` (leave IAM and EC2 resources)
4. Run `terraform fmt` to format both files
5. Run `terraform validate` to check syntax
6. Run `terraform plan` - should show "No changes" (infrastructure matches configuration)

**What you'll learn:**
- How Terraform reads all `.tf` files in a directory
- How to organize infrastructure code logically
- That refactoring doesn't require infrastructure changes when done correctly

---

## Quick Reference

**Essential Commands:**
```bash
terraform init              # Initialize directory
terraform fmt               # Format code
terraform validate          # Check syntax
terraform plan              # Preview changes
terraform apply             # Apply changes
terraform show              # Show current state
terraform state list        # List resources
terraform destroy           # Destroy all resources
```
