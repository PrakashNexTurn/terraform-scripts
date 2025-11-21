# ECR Repository Module
# This module creates Amazon Elastic Container Registry repositories with lifecycle policies

# Data source for current AWS region
data "aws_region" "current" {}

# Data source for current AWS caller identity
data "aws_caller_identity" "current" {}

# KMS key for ECR encryption
resource "aws_kms_key" "ecr" {
  count                   = var.enable_kms_encryption ? 1 : 0
  description             = "ECR KMS Key for ${var.repository_name}"
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow ECR service"
        Effect = "Allow"
        Principal = {
          Service = "ecr.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.repository_name}-ecr-kms-key"
    }
  )
}

# KMS key alias
resource "aws_kms_alias" "ecr" {
  count         = var.enable_kms_encryption ? 1 : 0
  name          = "alias/${var.repository_name}-ecr-key"
  target_key_id = aws_kms_key.ecr[0].key_id
}

# ECR Repository
resource "aws_ecr_repository" "main" {
  name                 = var.repository_name
  image_tag_mutability = var.image_tag_mutability
  force_delete         = var.force_delete

  encryption_configuration {
    encryption_type = var.enable_kms_encryption ? "KMS" : "AES256"
    kms_key         = var.enable_kms_encryption ? aws_kms_key.ecr[0].arn : null
  }

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  # Note: image_tag_mutability_exclusion_filter is not supported in dynamic blocks
  # This functionality would need to be implemented with individual static blocks
  # if needed for specific use cases

  tags = merge(
    var.common_tags,
    {
      Name = var.repository_name
    }
  )
}

# ECR Repository Policy
resource "aws_ecr_repository_policy" "main" {
  count      = var.repository_policy != null ? 1 : 0
  repository = aws_ecr_repository.main.name
  policy     = var.repository_policy
}

# ECR Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "main" {
  count      = var.enable_lifecycle_policy ? 1 : 0
  repository = aws_ecr_repository.main.name

  policy = var.lifecycle_policy != null ? var.lifecycle_policy : jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.max_image_count} images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = var.protected_tags
          countType     = "imageCountMoreThan"
          countNumber   = var.max_image_count
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images older than ${var.untagged_image_retention_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.untagged_image_retention_days
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ECR Repository scanning configuration
resource "aws_ecr_registry_scanning_configuration" "scanning" {
  count     = var.enable_registry_scanning ? 1 : 0
  scan_type = var.registry_scan_type

  dynamic "rule" {
    for_each = var.registry_scan_rules
    content {
      scan_frequency = rule.value.scan_frequency
      repository_filter {
        filter      = rule.value.repository_filter
        filter_type = rule.value.filter_type
      }
    }
  }
}

# ECR Replication Configuration
resource "aws_ecr_replication_configuration" "replication" {
  count = var.enable_cross_region_replication ? 1 : 0

  replication_configuration {
    dynamic "rule" {
      for_each = var.replication_destinations
      content {
        dynamic "destination" {
          for_each = rule.value.destinations
          content {
            region      = destination.value.region
            registry_id = destination.value.registry_id
          }
        }
        
        dynamic "repository_filter" {
          for_each = rule.value.repository_filters
          content {
            filter      = repository_filter.value.filter
            filter_type = repository_filter.value.filter_type
          }
        }
      }
    }
  }
}

# ECR Public Repository (optional)
resource "aws_ecrpublic_repository" "public" {
  count           = var.create_public_repository ? 1 : 0
  repository_name = var.public_repository_name != "" ? var.public_repository_name : var.repository_name
  
  catalog_data {
    about_text        = var.public_repository_about_text
    architectures     = var.public_repository_architectures
    description       = var.public_repository_description
    logo_image_blob   = var.public_repository_logo_image_blob
    operating_systems = var.public_repository_operating_systems
    usage_text        = var.public_repository_usage_text
  }

  tags = merge(
    var.common_tags,
    {
      Name = var.public_repository_name != "" ? var.public_repository_name : var.repository_name
    }
  )
}

# ECR Public Repository Policy
resource "aws_ecrpublic_repository_policy" "public" {
  count           = var.create_public_repository && var.public_repository_policy != null ? 1 : 0
  repository_name = aws_ecrpublic_repository.public[0].repository_name
  policy          = var.public_repository_policy
}