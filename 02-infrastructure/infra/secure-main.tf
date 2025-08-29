provider "aws" {
  region = "us-west-2"
  # Credentials sourced from environment or OIDC; no hardcoded keys
}

# Network and access controls
variable "allowed_ssh_cidr" {
  description = "CIDR allowed for SSH access"
  type        = string
  default     = "192.0.2.0/24" # Example placeholder CIDR
}

variable "allowed_app_cidr" {
  description = "CIDR allowed for application access"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_id" {
  description = "Private subnet ID for the application instance"
  type        = string
}

# SECURITY ISSUE: Public S3 bucket with no encryption
resource "aws_s3_bucket" "app_data" {
  bucket = "my-app-data-bucket"
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "app_data_block" {
  bucket                  = aws_s3_bucket.app_data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# SECURITY ISSUE: Security group with wide open access
resource "aws_security_group" "app_sg" {
  name        = "app-security-group"
  description = "Security group for application servers"
  
  # Restrict SSH to approved CIDR
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # Restrict application access
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = [var.allowed_app_cidr]
  }

  # Restrict egress to HTTPS
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SECURITY ISSUE: EC2 instance with too many permissions
resource "aws_instance" "app_server" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  
  # Encrypted root EBS volume
  root_block_device {
    volume_size = 20
    encrypted   = true
  }
  
  # Place instance in a private subnet
  subnet_id     = var.private_subnet_id
  
  # IAM role with least privilege
  iam_instance_profile = aws_iam_instance_profile.app_profile.name
  
  # No sensitive data in user_data
  user_data = <<-EOF
              #!/bin/bash
              set -euo pipefail
              echo "Configuring instance..."
              EOF
  
  tags = {
    Name = "AppServer"
  }
}

# SECURITY ISSUE: IAM Role with excessive permissions
resource "aws_iam_role" "app_role" {
  name = "app-role"
  
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
}

# SECURITY ISSUE: Admin policy attachment
resource "aws_iam_role_policy" "app_inline_policy" {
  name = "app-least-privilege-policy"
  role = aws_iam_role.app_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup"
        ],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = [
          "kms:Decrypt"
        ],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "app_profile" {
  name = "app-profile"
  role = aws_iam_role.app_role.name
}
