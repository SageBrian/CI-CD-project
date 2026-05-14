# modules/ec2/main.tf
# EC2 instance to host the deployed application

# Look up the latest Amazon Linux 2023 AMI — never hardcode AMI IDs
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Security group — only allow what's needed (least privilege for networking)
resource "aws_security_group" "app" {
  name        = "${var.project_name}-${var.environment}-app-sg"
  description = "Security group for ${var.project_name} application server"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from your IP only — never 0.0.0.0/0"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "App port"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound — needed for package installs, SSM, etc."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-app-sg"
  }
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.app.id]
  iam_instance_profile   = var.ec2_instance_profile  # Role-based auth — no access keys

  # User data runs on first boot — installs CodeDeploy agent, Node.js, PM2
  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Update system
    yum update -y

    # Install Node.js 18
    curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
    yum install -y nodejs

    # Install PM2 (process manager — keeps app alive)
    npm install -g pm2
    pm2 startup systemd -u ec2-user --hp /home/ec2-user

    # Install CodeDeploy agent
    yum install -y ruby wget
    cd /home/ec2-user
    wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
    chmod +x ./install
    ./install auto
    systemctl start codedeploy-agent
    systemctl enable codedeploy-agent

    # Install CloudWatch agent
    yum install -y amazon-cloudwatch-agent

    echo "Bootstrap complete"
  EOF

  tags = {
    Name = "${var.project_name}-${var.environment}-app-server"
  }
}
