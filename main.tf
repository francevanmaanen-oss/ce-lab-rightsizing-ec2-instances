terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # No backend block — state is stored locally and uploaded
  # as a GitHub Actions artifact after each apply
}

provider "aws" {
  region = var.aws_region
}

# ── Data sources ─────────────────────────────────────────────────────────────

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

# ── EC2 instances ─────────────────────────────────────────────────────────────
# All t3.micro — free tier eligible (750 hrs/month combined)

locals {
  instances = {
    web-server     = "Simulates a moderately loaded web server (~68% CPU)"
    api-server     = "Simulates an idle API server (~2% CPU) — over-provisioned"
    data-processor = "Simulates an idle data processor (~2% CPU) — over-provisioned"
  }
}

resource "aws_instance" "lab" {
  for_each = local.instances

  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  subnet_id                   = data.aws_subnets.default.ids[0]
  iam_instance_profile        = aws_iam_instance_profile.cloudwatch_agent.name
  user_data                   = file("${path.module}/user-data.sh")
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
  }

  tags = {
    Name        = "rightsizing-${each.key}"
    Role        = each.key
    Description = each.value
    Environment = var.environment
    Lab         = var.lab_tag
    ManagedBy   = "terraform"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}
