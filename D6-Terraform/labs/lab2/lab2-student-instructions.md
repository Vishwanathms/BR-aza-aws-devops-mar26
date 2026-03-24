# Lab 2: Understanding State and Drift Detection
## Student Instructions

---

## Objective
Learn how Terraform detects and manages infrastructure drift when resources are modified outside of Terraform.

## Time Estimate
30-35 minutes

---

## What You'll Learn
- What tags are and how to use them in Terraform
- How Terraform detects drift (changes made outside Terraform)
- How to revert drift back to desired state
- How to accept drift by updating your configuration
- The difference between desired state and actual state

---

## Prerequisites
- Access to Lab environment (us-west-1 region)

---

## High-Level Instructions

1. **Create project directory**

2. **Write configuration files with tags**
   - `terraform.tf`
   - `main.tf` (with EC2 instance including tags)

3. **Initialize and deploy infrastructure**

---

4. **Create tag drift manually using AWS CLI**

5. **Detect drift using terraform plan**

6. **Revert drift using terraform apply**

7. **Create drift again and accept it by updating configuration**

8. **Clean up resources**

---

## Documentation Related to This Lab

**AWS Provider Documentation:**
https://registry.terraform.io/providers/hashicorp/aws/latest/docs

**aws_instance Resource:**
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance

**Terraform Language:**
https://developer.hashicorp.com/terraform/language

---

## Quick Introduction: What Are Tags?

**Tags** are key-value pairs you attach to AWS resources for organization and management.

**Common uses:**
- Identify resources by name, environment, or owner
- Track costs by project or department
- Automate operations (e.g., backup all resources tagged "Production")

**Example:**
```hcl
tags = {
  Name        = "MyInstance"
  Environment = "Training"
  Owner       = "UserX"
}
```

---

## Detailed Instructions

### Step 1: Create Project Directory

Create and navigate to your lab directory:
```bash
cd
mkdir lab2-drift-detection
cd lab2-drift-detection
```

---

### Step 2: Create Terraform Configuration Files

**Create `terraform.tf`** - This file defines Terraform settings:

```hcl
# Terraform Configuration Block
# Defines the version requirements for Terraform and providers

terraform {
  # Provider requirements
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.20.0" # Allows 6.20.x versions (e.g., 6.20.0, 6.20.1)
    }
  }
  # Minimum Terraform version required
  required_version = "~> 1.13.5"
}
```

---

**Create `main.tf`** - This file defines your infrastructure:

```hcl
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

  # Instance type - t3.micro is free tier eligible
  instance_type = "t3.micro"

  # Tags - Key-value pairs for resource organization and identification
  # Tags help you organize, track costs, and manage resources
  tags = {
    Name        = "DriftDemoUserX"  # Human-readable name for the instance
    Environment = "Training"        # Which environment (Dev, Staging, Prod,)
  }
}
```

---

**What this code does:**
- Creates EC2 instance (same as Lab 1)
- **NEW:** Adds `tags` block with two key-value pairs
- Tags help organize and identify resources

---

### Step 3: Initialize and Deploy Infrastructure

Initialize Terraform:
```bash
terraform init
```

Validate configuration:
```bash
terraform validate
```

Preview changes:
```bash
terraform plan
```

---

Deploy infrastructure:
```bash
terraform apply
```

Type `yes` when prompted.

**Success indicators:**
- "Apply complete! Resources: 1 added"
- Instance created successfully

---

### Step 4: Create Tag Drift Manually

Now we'll modify tags **outside of Terraform** to simulate drift.

**Get the instance ID from Terraform state:**
```bash
INSTANCE_ID=$(terraform state show aws_instance.drift_demo | grep "\"i-" | awk '{print $3}' | tr -d '"')

echo $INSTANCE_ID
```

This command queries your local Terraform state file for the instance ID.

--- 

**Modify tags using AWS CLI:**
```bash
aws ec2 create-tags --region us-west-1 --resources $INSTANCE_ID \
  --tags Key=Name,Value=ModifiedDriftDemoUserX
```

**Verify the changes in AWS:**
```bash
aws ec2 describe-tags --region us-west-1 \
  --filters "Name=resource-id,Values=$INSTANCE_ID" \
  --output table
```

You should see:
- `Name` changed from "DriftDemoUserX" to "ModifiedDriftDemoUserX"
- `Environment` still shows "Training"

---

**At this point:**
- AWS has the modified tags
- Terraform's state file still shows the old tags
- Your `.tf` file defines the original tags

---

### Step 5: Detect Drift Using Terraform Plan

Run Terraform plan to detect the drift:
```bash
terraform plan
```

**What you'll see:**
```
~ resource "aws_instance" "drift_demo" {
    ~ tags = {
        ~ Name = "ModifiedDriftDemoUserX" -> "DriftDemoUserX"
      }
  }
```
---

**Understanding the symbols:**
- `~` = Update in-place (no instance replacement)
- `->` = Change from current value to desired value
- `-` = Will be removed

---

**What Terraform is telling you:**
- "I detected that the Name tag changed in AWS"
- "I will change Name back to 'DriftDemoUserX'"
- "This matches what's in your configuration"

**Key concept:** Terraform automatically refreshes state during `plan` to detect drift!

---

### Step 6: Revert Drift Using Terraform Apply

Apply the changes to restore tags to desired state:
```bash
terraform apply
```

Type `yes` when prompted.

**What happens:**
- Terraform updates tags back to match your configuration
- Instance keeps running (in-place update, no downtime)

---

**Verify tags are restored:**
```bash
aws ec2 describe-tags --region us-west-1 \
  --filters "Name=resource-id,Values=$INSTANCE_ID" \
  --output table
```

Tags are back to original:
- `Name` = "DriftDemoUserX"
- `Environment` = "Training"

**Key learning:** Terraform enforces desired state!

---

### Step 7: Accept Drift by Updating Configuration

Now let's explore the **other** way to handle drift: accepting it.

**Create drift again:**
```bash
aws ec2 create-tags --region us-west-1 --resources $INSTANCE_ID \
  --tags Key=Team,Value=DevOps
```

**Check what Terraform wants to do:**
```bash
terraform plan
```

It wants to remove the `Team` tag.

---

**But what if the Team tag is actually useful and we want to keep it?**

**Update your `main.tf`** to accept the drift:

---

```hcl
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

  # Instance type - t3.micro is free tier eligible
  instance_type = "t3.micro"

  # Tags - Key-value pairs for resource organization and identification
  # Tags help you organize, track costs, and manage resources
  tags = {
    Name        = "DriftDemoUserX"  # Human-readable name for the instance
    Environment = "Training"        # Which environment (Dev, Staging, Prod, etc.)
    Team        = "DevOps"          # Added this line to accept the drift!
  }
}
```

---

**Run plan again:**
```bash
terraform plan
```

**Now you'll see:**
```
No changes. Your infrastructure matches the configuration.
```

**What happened:**
1. Manual change created drift
2. We updated our `.tf` file to match the manual change
3. Configuration now matches reality
4. No drift detected!

**Key learning:** You can choose to accept drift by updating your configuration!

---

### Step 8: Understanding the Decision

**When should you REVERT drift?**
- Unauthorized changes
- Accidental modifications
- Changes that violate standards
- You want Terraform to be the single source of truth

**When should you ACCEPT drift?**
- Emergency hotfixes that worked
- Approved manual changes
- Changes you want to codify
- Then update config to match

---

**Best practice:** Minimize manual changes, always update Terraform configuration.

---

### Step 9: Clean Up Resources

Destroy the infrastructure:
```bash
terraform destroy
```

Type `yes` when prompted.

**Success indicator:**
- "Destroy complete! Resources: 1 destroyed"

---

## Key Concepts Recap

### Infrastructure Drift
When actual infrastructure differs from Terraform configuration.

**Common causes:**
- Manual changes via AWS Console/CLI
- Other automation tools
- Team members making direct changes

---

### State Refresh
Terraform automatically queries AWS during `plan` and `apply` to detect drift.

**What happens:**
1. Terraform reads its state file (last known configuration)
2. Terraform queries AWS (current reality)
3. Terraform compares them
4. Shows you the differences

---

### Desired State vs Actual State
- **Desired State:** What's in your `.tf` files
- **Actual State:** What exists in AWS right now
- **Terraform's Job:** Make actual match desired

### Terraform Symbols
- `~` = Update in-place
- `+` = Create
- `-` = Delete
- `-/+` = Replace (destroy and recreate)
