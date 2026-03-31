#!/bin/bash

# Jenkins Node Setup Script
# This script automates adding the EC2 instance as a Jenkins node
# Prerequisites: Jenkins CLI jar file and credentials

set -e

# Configuration
JENKINS_URL="${JENKINS_URL:-http://localhost:8080}"
JENKINS_USER="${JENKINS_USER:-admin}"
JENKINS_TOKEN="${JENKINS_TOKEN:-your-api-token}"
NODE_NAME="${NODE_NAME:-aws-ec2-node}"
NODE_IP="${1:-}"
NODE_SSH_KEY="${2:-./my-ec2-key.pem}"
JENKINS_CLI="${JENKINS_CLI:-jenkins-cli.jar}"

if [ -z "$NODE_IP" ]; then
  echo "Usage: $0 <node_ip> <path_to_ssh_key>"
  echo "Example: $0 54.176.155.46 ./my-ec2-key.pem"
  exit 1
fi

echo "Setting up Jenkins node: $NODE_NAME ($NODE_IP)"

# Check if Jenkins CLI exists
if [ ! -f "$JENKINS_CLI" ]; then
  echo "Downloading Jenkins CLI..."
  wget "$JENKINS_URL/jnlpJars/jenkins-cli.jar" || curl -O "$JENKINS_URL/jnlpJars/jenkins-cli.jar"
fi

# Test Jenkins connection
echo "Testing Jenkins connection..."
java -jar "$JENKINS_CLI" -s "$JENKINS_URL" -auth "$JENKINS_USER:$JENKINS_TOKEN" who-am-i || {
  echo "Failed to connect to Jenkins. Check URL and credentials."
  exit 1
}

# Create Node using Jenkins CLI
echo "Creating Jenkins node..."
java -jar "$JENKINS_CLI" -s "$JENKINS_URL" -auth "$JENKINS_USER:$JENKINS_TOKEN" create-node "$NODE_NAME" << 'EOF'
<slave>
  <name>NODE_NAME_PLACEHOLDER</name>
  <description>AWS EC2 Node</description>
  <remoteFS>/home/ec2-user</remoteFS>
  <numExecutors>2</numExecutors>
  <mode>NORMAL</mode>
  <retentionStrategy class="hudson.slaves.RetentionStrategy$Always"/>
  <launcher class="hudson.plugins.sshslaves.SSHLauncher">
    <host>NODE_IP_PLACEHOLDER</host>
    <port>22</port>
    <username>ec2-user</username>
    <privatekey>PRIVATE_KEY_PLACEHOLDER</privatekey>
    <passphrase></passphrase>
    <ptyEnabled>true</ptyEnabled>
    <trustPhrase></trustPhrase>
  </launcher>
  <label>aws ec2 docker kubernetes</label>
  <nodeProperties/>
</slave>
EOF

echo "Node '$NODE_NAME' created successfully!"
echo "Node will appear in Jenkins UI after it connects."

# Optional: Go online if node is created in offline state
# java -jar "$JENKINS_CLI" -s "$JENKINS_URL" -auth "$JENKINS_USER:$JENKINS_TOKEN" online-node "$NODE_NAME"

echo "To verify the node:"
echo "1. Check Jenkins UI: $JENKINS_URL/manage/nodes"
echo "2. SSH test: ssh -i $NODE_SSH_KEY ec2-user@$NODE_IP \"java -version\""