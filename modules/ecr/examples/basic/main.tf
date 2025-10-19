# Basic ECR Repository Example
# This example shows how to create a basic ECR repository with lifecycle policies

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Basic ECR Repository
module "ecr_basic" {
  source = "../../"

  repository_name      = var.repository_name
  image_tag_mutability = var.image_tag_mutability
  force_delete        = var.force_delete

  # Encryption
  enable_kms_encryption = var.enable_kms_encryption

  # Scanning
  scan_on_push = var.scan_on_push

  # Lifecycle policy
  enable_lifecycle_policy       = var.enable_lifecycle_policy
  max_image_count              = var.max_image_count
  untagged_image_retention_days = var.untagged_image_retention_days
  protected_tags               = var.protected_tags

  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    Terraform   = "true"
    Example     = "basic"
  }
}

# Example: ECR Repository with custom lifecycle policy
module "ecr_custom_lifecycle" {
  source = "../../"

  repository_name      = "${var.repository_name}-custom"
  image_tag_mutability = "IMMUTABLE"

  # Custom lifecycle policy
  enable_lifecycle_policy = true
  lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 production images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["prod"]
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep last 10 development images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["dev", "feature"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 3
        description  = "Delete untagged images older than 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })

  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    Terraform   = "true"
    Example     = "custom-lifecycle"
  }
}

# Example: ECR Repository with cross-account access
module "ecr_cross_account" {
  source = "../../"

  repository_name = "${var.repository_name}-shared"

  # Repository policy for cross-account access
  repository_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CrossAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = var.cross_account_arns
        }
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
      }
    ]
  })

  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    Terraform   = "true"
    Example     = "cross-account"
  }
}

# Example: Multiple repositories for microservices
module "ecr_microservices" {
  source = "../../"

  for_each = toset(var.microservice_names)

  repository_name = "${var.repository_prefix}-${each.key}"

  # Different settings per service type
  image_tag_mutability = contains(var.production_services, each.key) ? "IMMUTABLE" : "MUTABLE"
  max_image_count      = contains(var.production_services, each.key) ? 20 : 10

  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    Service     = each.key
    Terraform   = "true"
    Example     = "microservices"
  }
}