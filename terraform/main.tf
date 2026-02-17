# ---------------------------------------------------
# Terraform Backend (Remote State in S3)
# ---------------------------------------------------
terraform {
  backend "s3" {
    bucket         = "strapi-task7-terraform-state"
    key            = "task7/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ---------------------------------------------------
# AWS Provider
# ---------------------------------------------------
provider "aws" {
  region = "us-east-1"
}

# ---------------------------------------------------
# Get Default VPC
# ---------------------------------------------------
data "aws_vpc" "default" {
  default = true
}

# ---------------------------------------------------
# Get Subnets
# ---------------------------------------------------
data "aws_subnets" "default_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ---------------------------------------------------
# Use Existing ECR Repository
# ---------------------------------------------------
data "aws_ecr_repository" "strapi_repo" {
  name = "strapi-task7"
}

# ---------------------------------------------------
# ECS Cluster
# ---------------------------------------------------
resource "aws_ecs_cluster" "strapi_cluster" {
  name = "strapi-task7"
}

# ---------------------------------------------------
# IAM Role for ECS EC2 Instance
# ---------------------------------------------------
resource "aws_iam_role" "ecs_instance_role" {
  name = "ecsInstanceRoleTask7"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_instance_attach" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecsInstanceProfileTask7"
  role = aws_iam_role.ecs_instance_role.name
}

# ---------------------------------------------------
# ECS Task Execution Role (Pull from ECR)
# ---------------------------------------------------
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRoleTask7"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ---------------------------------------------------
# Security Group
# ---------------------------------------------------
resource "aws_security_group" "ecs_sg" {
  name   = "strapi-task7-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------------------------------------------
# Get ECS Optimized AMI
# ---------------------------------------------------
data "aws_ami" "ecs_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

# ---------------------------------------------------
# EC2 Instance for ECS
# ---------------------------------------------------
resource "aws_instance" "ecs_instance" {
  ami                         = data.aws_ami.ecs_ami.id
  instance_type               = "t2.micro"
  subnet_id                   = data.aws_subnets.default_subnets.ids[0]
  vpc_security_group_ids      = [aws_security_group.ecs_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ecs_instance_profile.name
  associate_public_ip_address = true

  user_data = file("${path.module}/userdata.sh")

  root_block_device {
    volume_size = 30
  }

  tags = {
    Name = "strapi-task7"
  }
}

# ---------------------------------------------------
# ECS Task Definition
# ---------------------------------------------------
resource "aws_ecs_task_definition" "strapi_task" {
  family                   = "strapi-task7"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "768"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "strapi"
      image     = "${data.aws_ecr_repository.strapi_repo.repository_url}:${var.image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = 1337
          hostPort      = 1337
        }
      ],

      environment = [
        { name = "NODE_ENV", value = "production" },
        { name = "HOST", value = "0.0.0.0" },
        { name = "PORT", value = "1337" },
        { name = "APP_KEYS", value = "testkey1,testkey2,testkey3,testkey4" },
        { name = "API_TOKEN_SALT", value = "randomsalt123" },
        { name = "ADMIN_JWT_SECRET", value = "adminsecret123" },
        { name = "JWT_SECRET", value = "jwtsecret123" }
      ]
    }
  ])
}


# ---------------------------------------------------
# ECS Service
# ---------------------------------------------------
resource "aws_ecs_service" "strapi_service" {
  name            = "strapi-task7"
  cluster         = aws_ecs_cluster.strapi_cluster.id
  task_definition = aws_ecs_task_definition.strapi_task.arn
  desired_count   = 1
  launch_type     = "EC2"

  depends_on = [aws_instance.ecs_instance]
}

# ---------------------------------------------------
# Output Public URL
# ---------------------------------------------------
output "strapi_url" {
  value = "http://${aws_instance.ecs_instance.public_ip}:1337/"
}
