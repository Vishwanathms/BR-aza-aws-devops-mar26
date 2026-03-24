# Lab 1: Deploy Your First EC2 Instance
## Student Instructions

---

## Objective
Deploy your first AWS EC2 instance using Terraform.

## Time Estimate
20-25 minutes

---

## What You'll Learn
- How to write basic Terraform configuration
- How to configure AWS provider with default tags for resource identification
- The Terraform workflow: init → plan → apply → destroy
- How Terraform manages infrastructure state

---

## Prerequisites
- Access to Lab environment (ask your trainer if you don't have one)
- The lab region is us-west-1

---

## High-Level Instructions

1. **Create project directory**

2. **Write configuration files**
    - `terraform.tf`
    - `main.tf` (with AWS provider including default_tags)

   - Your provider should:
    - Configure us-west-1 region
    - Include default_tags with owner = your user ID (e.g., user1, user2)

   - Your instance should be:
    - t3.micro instance
    - launched in us-west-1
    - use ami with id: ami-067ec7f9e54a67559

---

3. **Initialize Terraform Working Directory**
  
4. **Validate you configuration**

5. **Plan new deployment**

6. **Apply new deployment if everything looks good**

7. **Verify using both terraform and aws cli that instance has been created**

---

8. **Challenge (Optional)**
   - instead of using hardcoded AMI id for your instance, use data sources to get the latest Amazon Linux 2023 AMI
   - Note: Changing AMI will replace the instance with a new ID

9. **Remove instance**
---

## Documentation related to the labs:

**AWS Provider Documentation:**
https://registry.terraform.io/providers/hashicorp/aws/latest/docs

**aws_instance Resource:**
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance

**Terraform Language:**
https://developer.hashicorp.com/terraform/language

---

## Detailed Instructions

### Step 1: Create Project Directory

Create and navigate to your lab directory:
```bash
cd
mkdir -p Day1/lab1
cd Day1/lab1
```

---

### Step 2: Create Terraform Configuration Files

**Create `terraform.tf`** - This file defines Terraform settings:

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

**Create `main.tf`** - This file defines your infrastructure:

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

resource "aws_instance" "my_first_instance" {
  ami           = "ami-067ec7f9e54a67559"
  instance_type = "t3.micro"

  tags = {
    Name = "userX"
  }
}
```

**What this code does:**
- `provider "aws"` - Connects to AWS in us-west-1 region
- `default_tags` - Automatically applies tags to all AWS resources created by this provider
- `owner = "userX"` - **IMPORTANT: Replace "userX" with your assigned student ID (e.g., user1, user2, user3)**
- `resource "aws_instance"` - Creates an EC2 instance
- `ami` - Amazon Machine Image (Amazon Linux 2023)
- `instance_type` - t3.micro (free tier eligible)
- `tags` - Resource-specific tags (in addition to default_tags)
- `Name = "userX"` - **IMPORTANT: Replace "userX" with your assigned student ID** - This tag appears in the AWS Console for easy identification

**Why Use Both Default Tags and Resource-Specific Tags?**
In a shared training environment (or production), using both tag types provides different benefits:
- **Default Tags (owner)** - Applied automatically to ALL resources, essential for tracking in shared accounts
- **Resource-Specific Tags (Name)** - Appears as the name in AWS Console, making resources easy to find visually
- **Cost Tracking** - Monitor your resource usage and costs
- **Avoid Conflicts** - Prevent accidentally modifying other students' resources

**Security Best Practice Note:**
In production environments, you should enable encryption for EC2 root volumes by adding a `root_block_device` block with `encrypted = true`. We're keeping this lab simple for learning purposes, but encryption at rest is a critical security best practice for protecting sensitive data and meeting compliance requirements.

---

### Step 3: Initialize Terraform Working Directory (default workspace)

Download the AWS provider plugin:
```bash
terraform init
```

**Success indicators:**
- Message: "Terraform has been successfully initialized!"
- Creates `.terraform/` directory
- Creates `.terraform.lock.hcl` file

---

### Step 4: Validate Your Configuration

Check for syntax errors:
```bash
terraform validate
```

**Success indicator:**
- Message: "Success! The configuration is valid."

---

### Step 5: Preview Changes

See what Terraform will create:
```bash
terraform plan
```

**What to look for:**
- `Plan: 1 to add, 0 to change, 0 to destroy`
- `+ resource "aws_instance"` (+ means create)
- Check ami and instance_type values match your code

---

### Step 6: Deploy Infrastructure Based On The Configuration

Create the EC2 instance:
```bash
terraform apply
```

When prompted, type `yes` and press Enter.

**What happens:**
- Shows the plan again
- Waits for your confirmation
- Creates the instance 
- Displays "Apply complete! Resources: 1 added"

---

### Step 7: Verify Deployment

**View all instance details:**
```bash
terraform show
```

**Get just the instance ID:**
```bash
INSTANCE_ID=$(terraform state show aws_instance.my_first_instance | grep "\"i-" | awk '{print $3}' | tr -d '"')

echo $INSTANCE_ID
```

You'll see something like: `i-0a1b2c3d4e5f6g7h8`

**Query AWS using the instance ID:**
```bash
aws ec2 describe-instances --instance-ids $INSTANCE_ID
```

**Success indicators:**
- Instance ID displayed (starts with `i-`)
- State shows "running"
- Private IP address assigned
- **Tags section shows both your tags** (verify your user ID is applied)

**To verify your tags were applied:**
```bash
aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCE_ID"
```

You should see **two tags**:
- `Name` tag with your user ID (from resource-specific tags) - appears in AWS Console
- `owner` tag with your user ID (from default_tags) - for tracking in shared account

---

### Step 8: Optional Challenge - Use a Data Source for AMI

Ready for a challenge? Instead of hard-coding the AMI ID, let Terraform automatically find the latest Amazon Linux 2023 AMI.

**What you'll learn:**
- How to use Terraform data sources
- How to query existing AWS resources
- How to make your code more maintainable

---

### Challenge Instructions

1. **Add a data source** to your `main.tf` (before the resource block):

```hcl
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
```

---

2. **Update your EC2 instance** to use the data source:

```hcl
resource "aws_instance" "my_first_instance" {
  ami           = data.aws_ami.amazon_linux_2023.id  # Changed!
  instance_type = "t3.micro"

  tags = {
    Name = "userX"
  }
}
```

3. **Test it:**

```bash
terraform plan
```

Look for the data source query in the plan output!

---

**Important Note:**
When you change the AMI (even to a data source that finds a different AMI), Terraform will **destroy the old instance and create a new one** with a **different instance ID**. This is because changing the AMI is a significant change that requires replacing the instance.

You'll see in the plan:
```
  # aws_instance.my_first_instance must be replaced
-/+ resource "aws_instance" "my_first_instance" {
```

The `-/+` symbol means "destroy and recreate" (also called "replace").

---

**What's happening:**
- `data "aws_ami"` - Queries AWS for AMI information
- `most_recent = true` - Finds the newest AMI
- `filter` - Narrows down results to Amazon Linux 2023
- `data.aws_ami.amazon_linux_2023.id` - References the AMI ID found by the query

**Benefits:**
- Always uses the latest AMI automatically
- No need to manually update AMI IDs
- Works across different AWS regions

---

### Step 9: Clean Up Resources

Destroy the infrastructure:
```bash
terraform destroy
```

When prompted, type `yes` and press Enter.

**What happens:**
- Shows what will be destroyed
- Waits for your confirmation
- Destroys the instance
- Displays "Destroy complete! Resources: 1 destroyed"

