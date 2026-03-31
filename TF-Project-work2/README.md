# Project-work2 Deployment Outputs

## READ this file completely before runnig the terraform script.

This file contains the important outputs and information from the Terraform deployment.

## Infrastructure Created

- **EC2 Instance**: Amazon Linux 2 t2.micro in us-west-1 default VPC
- **Security Group**: Allows SSH (22), HTTP (80), HTTPS (443)
- **EBS Volume**: 20 GB root volume
- **IAM Role**: ec2-s3-full-access-role with policies:
  - AmazonEC2FullAccess
  - AmazonS3FullAccess
  - AmazonEC2ContainerRegistryFullAccess
- **ECR Repository**: pythonapp (with image scanning enabled)
- **SSH Key Pair**: Generated and saved locally

## Installed Software (via Provisioner)

- Docker
- Docker Compose
- kubectl
- Minikube
- Java Development Kit (JDK) 17 (for Jenkins agent)

## Outputs

After running `terraform apply`, the following outputs will be displayed:

- **instance_public_ip**: Public IP address of the EC2 instance
- **private_key_path**: Path to the SSH private key file (e.g., my-ec2-key.pem)
- **ecr_repository_url**: URL of the ECR repository (e.g., 123456789012.dkr.ecr.us-west-1.amazonaws.com/pythonapp)
- **jenkins_node_info**: Jenkins node configuration details (IP, user, Java version)

## Pre-Deployment Setup (Jenkins Node Integration)

Before running `terraform apply`, prepare the Jenkins master public key:

1. **On Jenkins Master Machine**, copy the Jenkins master SSH public key:
   ```bash
   cat ~/.ssh/id_rsa.pub
   # or
   sudo cat /var/lib/jenkins/.ssh/id_rsa.pub
   ```

2. **In the project-work2 directory**, create a file named `jenkins_master.pub` with the public key content:
   ```bash
   echo "<jenkins-public-key-content>" > jenkins_master.pub
   chmod 600 jenkins_master.pub
   ```

   Alternatively, copy it directly:
   ```bash
   scp jenkins-user@jenkins-machine:.ssh/id_rsa.pub ./jenkins_master.pub
   ```

## Usage Instructions

1. **SSH Access**:
   ```bash
   ssh -i <private_key_path> ec2-user@<instance_public_ip>
   ```

2. **Docker Operations**:
   ```bash
   # Login to ECR
   aws ecr get-login-password --region us-west-1 | docker login --username AWS --password-stdin <ecr_repository_url>

   # Push image
   docker tag myimage:latest <ecr_repository_url>:latest
   docker push <ecr_repository_url>:latest
   ```

3. **Kubernetes Operations**:
   ```bash
   # Start Minikube
   minikube start --driver=docker

   # Deploy to Kubernetes
   kubectl apply -f deployment.yaml
   ```

4. **Jenkins Agent Node Setup**:

   After the infrastructure is deployed, add the EC2 instance as a Jenkins node:

   a. Get the node details from Terraform outputs:
   ```bash
   terraform output jenkins_node_info
   ```

   b. In Jenkins UI (http://jenkins-machine:8080):
      - Go to Manage Jenkins → Nodes
      - Click "New Node"
      - Enter node name: `aws-ec2-node` (or preferred name)
      - Select "Permanent Agent"
      - Configure:
        - **Remote root directory**: `/home/ec2-user`
        - **Labels**: `aws`, `ec2`, `docker`, `kubernetes`
        - **Launch method**: SSH
        - **Host**: `<instance_public_ip>` (from terraform output)
        - **Credentials**: Create new SSH credentials with key `<my-ec2-key.pem>`
        - **Host Key Verification Strategy**: Non-verifying (or configure known_hosts)

   c. Click "Save" to add the node

   d. Verify node connection:
      - If offline, check Jenkins logs: `docker logs jenkins` or `/var/log/jenkins/jenkins.log`
      - SSH from Jenkins master: `ssh -i jenkins-key ec2-user@<instance_public_ip> "java -version"`

4. **public and private key**:
* using an exsiting keys.
* This code assumes the private key and public key are copied to this folder.
privatekey filename == "aws_key_pair.pem"
public key          == "jenkins_master.pub"

If the keys are availabel in the default .ssh folder, it would take it from it or it would create a new one there 


## Security Notes

- The instance has full access to EC2, S3, and ECR services
- SSH access is open to 0.0.0.0/0 (consider restricting in production)
- Image scanning is enabled on ECR pushes

## Cleanup

To destroy all resources:
```bash
terraform destroy -var-file=terraform.tfvars
```

## Variables

The deployment uses the following variables (defined in terraform.tfvars):
- region: us-west-1
- instance_type: t2.micro
- key_name: my-ec2-key
- ami_name_filter: amzn2-ami-hvm-*-x86_64-gp2
- security_group_name: allow-ssh-http-https
- allowed_cidrs: ["0.0.0.0/0"]