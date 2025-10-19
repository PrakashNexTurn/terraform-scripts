# CodePipeline Module
# This module creates an AWS CodePipeline with GitHub App integration and CodeBuild stages

# Data source for current AWS region
data "aws_region" "current" {}

# Data source for current AWS caller identity
data "aws_caller_identity" "current" {}

# S3 bucket for CodePipeline artifacts
resource "aws_s3_bucket" "artifacts" {
  count  = var.create_artifacts_bucket ? 1 : 0
  bucket = var.artifacts_bucket_name != "" ? var.artifacts_bucket_name : "${var.pipeline_name}-artifacts-${random_id.bucket_suffix[0].hex}"

  tags = merge(
    var.common_tags,
    {
      Name = "CodePipeline Artifacts"
    }
  )
}

resource "random_id" "bucket_suffix" {
  count       = var.create_artifacts_bucket ? 1 : 0
  byte_length = 8
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "artifacts" {
  count  = var.create_artifacts_bucket ? 1 : 0
  bucket = aws_s3_bucket.artifacts[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  count  = var.create_artifacts_bucket ? 1 : 0
  bucket = aws_s3_bucket.artifacts[0].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.artifacts_encryption_key_arn
      sse_algorithm     = var.artifacts_encryption_key_arn != "" ? "aws:kms" : "AES256"
    }
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "artifacts" {
  count  = var.create_artifacts_bucket ? 1 : 0
  bucket = aws_s3_bucket.artifacts[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "artifacts" {
  count  = var.create_artifacts_bucket && var.enable_artifacts_lifecycle ? 1 : 0
  bucket = aws_s3_bucket.artifacts[0].id

  rule {
    id     = "artifacts_lifecycle"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = var.artifacts_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.artifacts_noncurrent_version_retention_days
    }
  }
}

# CodeStar connection for GitHub App integration
resource "aws_codestarconnections_connection" "github" {
  count         = var.create_github_connection ? 1 : 0
  name          = var.github_connection_name != "" ? var.github_connection_name : "${var.pipeline_name}-github"
  provider_type = "GitHub"

  tags = merge(
    var.common_tags,
    {
      Name = "GitHub Connection"
    }
  )
}

# IAM role for CodePipeline
resource "aws_iam_role" "codepipeline" {
  name = "${var.pipeline_name}-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.pipeline_name}-codepipeline-role"
    }
  )
}

# IAM policy for CodePipeline
resource "aws_iam_role_policy" "codepipeline" {
  name = "${var.pipeline_name}-codepipeline-policy"
  role = aws_iam_role.codepipeline.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketVersioning",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = [
          var.create_artifacts_bucket ? aws_s3_bucket.artifacts[0].arn : var.existing_artifacts_bucket_arn,
          var.create_artifacts_bucket ? "${aws_s3_bucket.artifacts[0].arn}/*" : "${var.existing_artifacts_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codestar-connections:UseConnection"
        ]
        Resource = var.create_github_connection ? aws_codestarconnections_connection.github[0].arn : var.existing_github_connection_arn
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudformation:CreateStack",
          "cloudformation:DeleteStack",
          "cloudformation:DescribeStacks",
          "cloudformation:UpdateStack",
          "cloudformation:CreateChangeSet",
          "cloudformation:DeleteChangeSet",
          "cloudformation:DescribeChangeSet",
          "cloudformation:ExecuteChangeSet",
          "cloudformation:SetStackPolicy",
          "cloudformation:ValidateTemplate"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = "*"
        Condition = {
          StringEqualsIfExists = {
            "iam:PassedToService" = [
              "cloudformation.amazonaws.com",
              "elasticbeanstalk.amazonaws.com",
              "ec2.amazonaws.com",
              "ecs-tasks.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
}

# CodePipeline
resource "aws_codepipeline" "main" {
  name          = var.pipeline_name
  pipeline_type = var.pipeline_type
  role_arn      = aws_iam_role.codepipeline.arn

  artifact_store {
    location = var.create_artifacts_bucket ? aws_s3_bucket.artifacts[0].bucket : var.existing_artifacts_bucket_name
    type     = "S3"

    dynamic "encryption_key" {
      for_each = var.artifacts_encryption_key_arn != "" ? [1] : []
      content {
        id   = var.artifacts_encryption_key_arn
        type = "KMS"
      }
    }
  }

  # Source stage
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn        = var.create_github_connection ? aws_codestarconnections_connection.github[0].arn : var.existing_github_connection_arn
        FullRepositoryId     = var.github_repository
        BranchName          = var.github_branch
        OutputArtifactFormat = var.source_output_format
        DetectChanges       = var.detect_changes
      }
    }
  }

  # Build stages
  dynamic "stage" {
    for_each = var.build_stages
    content {
      name = stage.value.name

      dynamic "action" {
        for_each = stage.value.actions
        content {
          name             = action.value.name
          category         = "Build"
          owner            = "AWS"
          provider         = "CodeBuild"
          version          = "1"
          input_artifacts  = action.value.input_artifacts
          output_artifacts = action.value.output_artifacts
          run_order       = action.value.run_order
          region          = action.value.region != "" ? action.value.region : null

          configuration = {
            ProjectName   = action.value.project_name
            PrimarySource = action.value.primary_source
          }
        }
      }
    }
  }

  # Deploy stages
  dynamic "stage" {
    for_each = var.deploy_stages
    content {
      name = stage.value.name

      dynamic "action" {
        for_each = stage.value.actions
        content {
          name            = action.value.name
          category        = action.value.category
          owner           = action.value.owner
          provider        = action.value.provider
          version         = action.value.version
          input_artifacts = action.value.input_artifacts
          run_order      = action.value.run_order
          region         = action.value.region

          configuration = action.value.configuration

          dynamic "role_arn" {
            for_each = action.value.role_arn != "" ? [1] : []
            content {
              role_arn = action.value.role_arn
            }
          }
        }
      }
    }
  }

  # Manual approval stages
  dynamic "stage" {
    for_each = var.approval_stages
    content {
      name = stage.value.name

      action {
        name     = stage.value.action_name
        category = "Approval"
        owner    = "AWS"
        provider = "Manual"
        version  = "1"

        configuration = {
          NotificationArn = stage.value.notification_arn
          CustomData      = stage.value.custom_data
          ExternalEntityLink = stage.value.external_entity_link
        }
      }
    }
  }

  # Pipeline triggers (for V2 pipelines)
  dynamic "trigger" {
    for_each = var.pipeline_type == "V2" ? var.triggers : []
    content {
      provider_type = trigger.value.provider_type

      git_configuration {
        source_action_name = trigger.value.source_action_name

        dynamic "push" {
          for_each = trigger.value.push_filters
          content {
            dynamic "branches" {
              for_each = push.value.branches != null ? [push.value.branches] : []
              content {
                includes = branches.value.includes
                excludes = branches.value.excludes
              }
            }

            dynamic "file_paths" {
              for_each = push.value.file_paths != null ? [push.value.file_paths] : []
              content {
                includes = file_paths.value.includes
                excludes = file_paths.value.excludes
              }
            }

            dynamic "tags" {
              for_each = push.value.tags != null ? [push.value.tags] : []
              content {
                includes = tags.value.includes
                excludes = tags.value.excludes
              }
            }
          }
        }

        dynamic "pull_request" {
          for_each = trigger.value.pull_request_filters
          content {
            events = pull_request.value.events

            dynamic "branches" {
              for_each = pull_request.value.branches != null ? [pull_request.value.branches] : []
              content {
                includes = branches.value.includes
                excludes = branches.value.excludes
              }
            }

            dynamic "file_paths" {
              for_each = pull_request.value.file_paths != null ? [pull_request.value.file_paths] : []
              content {
                includes = file_paths.value.includes
                excludes = file_paths.value.excludes
              }
            }
          }
        }
      }
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name = var.pipeline_name
    }
  )
}