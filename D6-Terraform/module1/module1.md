---
marp: true
header: 'Terraform level 1 - Day 1 - **Module 2**'
style: |
  img[alt~="center"] {
    display: block;
    margin: 0 auto;
  }
paginate: true
---
# Terraform Training
## LEVEL 1: Terraform Beginner

---

# Module 1: Introduction to IaC

By the end of this module you will understand:
- What Infrastructure as Code (IaC) is and why it matters
- Common problems with manual and script-based infrastructure management
- The difference between Imperative and Declarative approaches
- Why Terraform is the industry standard for IaC
- Basic Terraform architecture and workflow

---
# What is Infrastructure as Code (IaC)?

> Infrastructure as code is a way to ***automatically*** **manage infrastructure** with **configuration** files rather than ***manually*** through a *web user interface* or ***semi-automatically*** through *command line* scripts.

**Manage** = **C**reate/**R**ead/**U**pdate/**D**elete = **CRUD**

**Infrastructure** = Compute/Storage/Networking resources
- Examples: EC2 instances, S3 buckets, VPCs, Load Balancers, Databases

---

# Ways to manage infrastructure

Let's explore common approaches to infrastructure management and their limitations:

1. **Manual Web page (AWS Console) approach** - Quick for one-off tasks, but doesn't scale
2. **Command Line scripts approach** - Faster than AWS Console, but lacks dependency handling

---
# Scenario 1: Using *AWS Console* to manage infrastructure.
**Example**: Launch an EC2 instance, then change instance type and re-launch.

## Why we do it?
- Quick for simple one-off resources

## What can go wrong?
- Time consuming with multiple resources
- Difficult to track current state
- Prone to human error
- Not reproducible

---
# Scenario 2: Using *Command Line* to manage infrastructure.
**Example**: Write scripts to launch EC2 instances and modify their types.

## Why we do it?
- Faster than AWS Console once scripts are developed

## What can go wrong?
- No automatic dependency handling
- Difficult error handling
- Not idempotent (running twice creates duplicates)
- Hard to validate compliance

---

# What's Missing?

Both approaches have significant limitations:

## AWS Console Problems:
- Not scalable beyond a few resources
- Infrastructure configuration not version controlled
- Difficult to replicate across environments

---

## Command Line Scripts Problems:
- No automatic dependency resolution
- Difficult error handling
- Not truly idempotent
- Scripts themselves aren't audited (only the API calls they make)

---

## What we need:
- Automatic dependency handling
- Declarative approach (describe the "what", not the "how")
- State tracking and management
- Idempotent operations (safe to run multiple times)

---
# The Solution: Declarative IaC

Instead of writing step-by-step instructions (imperative), we:

1. **Describe the desired end state** (declarative)
2. Let the IaC tool figure out how to get there
3. The tool handles dependencies, errors, and state automatically

**Analogy**: Like ordering at a restaurant - you tell the chef "I want a margherita pizza", not "Get flour, mix with water, add yeast, knead for 10 minutes, let rise, shape, add sauce and cheese, bake at 450°F for 15 minutes..."

The chef (Terraform) knows all the steps, handles the order of operations, and delivers what you want.

---
# Imperative vs. Declarative IaC


---
# Imperative - step by step sequence of commands
**Example: Changing instance type**
1. Launch an EC2 with m5.large type
2. Wait until instance is up and running
3. Find the instance you previously launched
4. Stop instance
5. Change instance type to m5.2xlarge
6. Start instance

**Problems**: Order matters, not resilient to changes made to resources outside script

---
# Declarative - define how the infrastructure should look
**Example: Changing instance type**
1. Create config file with `instance_type = "m5.large"`
   → Run terraform apply
2. Modify config to `instance_type = "m5.2xlarge"`
   → Run terraform apply

**Advantages**:
- Idempotent (safe to run multiple times)
- Handles dependencies automatically
- Self-documenting and can be version controlled since it's a text

# What is Terraform and why it's important?

## Terraform is widely adopted in large Enterprises as Infrastructure as Code tool of choice

**Why Terraform?**
- Multi-cloud support (AWS, Azure, GCP, and 3000+ providers)
- Industry standard with large community
- Declarative syntax (HCL - HashiCorp Configuration Language)
- State management built-in
- Modular and reusable code
- Trusted by Fortune 500 companies

---
# Basic Terraform architecture overview


![center](tf-arch-overview-v2.svg)

---

**Key Components**:
- **Configuration Files** (.tf files) - What you write (desired state)
- **Terraform Command Line** (terraform command) - Engine that processes your configuration
- **Providers** - Plugins that talk to cloud platforms (AWS, Azure, etc.)
- **State File** - Terraform's memory of what currently exists
- **Resources** - The actual infrastructure created in your cloud

---
# The Terraform Workflow

Terraform follows a simple, repeatable workflow:

1. **Define** - Create `.tf` configuration files
2. **Init** - `terraform init` - Initialize working directory and download providers
3. **Plan** - `terraform plan` - Show changes required by current configuration
4. **Apply** - `terraform apply` - Execute actions to create, update, or destroy infrastructure
5. **Verify** - Use `terraform show` or `terraform state list` to inspect state
6. **Modify** - Change configuration files as needed (repeat from step 3)
7. **Destroy** - `terraform destroy` - Remove all managed infrastructure

---

# Key Takeaways

**IaC** automates infrastructure management through configuration files

**Declarative approach** (Terraform) beats imperative (scripts) for scalability

**Terraform** is the industry-standard multi-cloud IaC tool

**Core workflow**: Define → Init → Plan → Apply → Destroy

Terraform handles **dependencies**, **state**, and **idempotency** automatically

---

# Knowledge Check 1

**What does "idempotent" mean in the context of Terraform?**

A) Running the same operation once or multiple times produces the same result

B) Each run creates new duplicate resources

C) The operation can only be run once

D) The operation fails if run more than once

<!--
Answer: A
Explanation: Idempotency means running the same Terraform configuration multiple times will produce the same infrastructure state - critical for environments where consistency and repeatability are essential.
-->

---
# Knowledge Check 2

**What is the correct order of the basic Terraform workflow?**

A) Apply → Init → Plan → Destroy

B) Plan → Init → Apply → Destroy

C) Init → Plan → Apply → Destroy

D) Destroy → Init → Plan → Apply

<!--
Answer: C
Explanation: The correct workflow is: Init (download providers) → Plan (preview changes) → Apply (execute changes) → Destroy (cleanup).
-->

---
# Knowledge Check 3

**Your team needs to track all infrastructure changes for regulatory compliance. Which Terraform advantage helps with this?**

A) Terraform is free

B) Configuration files can be version controlled in Git

C) Terraform runs faster than scripts

D) Terraform doesn't require permissions

<!--
Answer: B
Explanation: Terraform configurations are text files that can be stored in version control systems like Git, providing a complete audit trail of all infrastructure changes - essential for compliance requirements.
-->


