region              = "us-west-1"
instance_type        = "t2.medium"
ami_name_filter      = "amzn2-ami-hvm-*-x86_64-gp2"
security_group_name  = "allow-ssh-http-https"
allowed_cidrs        = ["0.0.0.0/0"]
key_name = "key_pair"
private_key_path = "aws_key_pair.pem"