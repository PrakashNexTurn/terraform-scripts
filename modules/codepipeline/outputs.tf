# CodePipeline Outputs

# Pipeline information
output "pipeline_id" {
  description = "CodePipeline ID"
  value       = aws_codepipeline.main.id
}

output "pipeline_name" {
  description = "CodePipeline name"
  value       = aws_codepipeline.main.name
}

output "pipeline_arn" {
  description = "CodePipeline ARN"
  value       = aws_codepipeline.main.arn
}

output "pipeline_type" {
  description = "CodePipeline type"
  value       = aws_codepipeline.main.pipeline_type
}

# IAM Role
output "pipeline_role_arn" {
  description = "ARN of the IAM role used by CodePipeline"
  value       = aws_iam_role.codepipeline.arn
}

output "pipeline_role_name" {
  description = "Name of the IAM role used by CodePipeline"
  value       = aws_iam_role.codepipeline.name
}

# S3 Artifacts Bucket
output "artifacts_bucket_name" {
  description = "Name of the S3 bucket used for pipeline artifacts"
  value       = var.create_artifacts_bucket ? aws_s3_bucket.artifacts[0].id : var.existing_artifacts_bucket_name
}

output "artifacts_bucket_arn" {
  description = "ARN of the S3 bucket used for pipeline artifacts"
  value       = var.create_artifacts_bucket ? aws_s3_bucket.artifacts[0].arn : var.existing_artifacts_bucket_arn
}

# GitHub Connection
output "github_connection_arn" {
  description = "ARN of the GitHub connection"
  value       = var.create_github_connection ? aws_codestarconnections_connection.github[0].arn : var.existing_github_connection_arn
}

output "github_connection_status" {
  description = "Status of the GitHub connection"
  value       = var.create_github_connection ? aws_codestarconnections_connection.github[0].connection_status : null
}

# Pipeline configuration
output "pipeline_stages" {
  description = "List of pipeline stages"
  value       = aws_codepipeline.main.stage
}

output "source_configuration" {
  description = "Source stage configuration"
  value = {
    repository = var.github_repository
    branch     = var.github_branch
    output_format = var.source_output_format
    detect_changes = var.detect_changes
  }
}

# Webhook information (for GitHub integration)
output "webhook_url" {
  description = "Webhook URL for GitHub integration (must be manually configured)"
  value       = "https://console.aws.amazon.com/codesuite/codepipeline/pipelines/${aws_codepipeline.main.name}/view"
}

# Pipeline execution commands
output "start_execution_command" {
  description = "AWS CLI command to start pipeline execution"
  value       = "aws codepipeline start-pipeline-execution --name ${aws_codepipeline.main.name} --region ${data.aws_region.current.name}"
}

output "get_pipeline_state_command" {
  description = "AWS CLI command to get pipeline state"
  value       = "aws codepipeline get-pipeline-state --name ${aws_codepipeline.main.name} --region ${data.aws_region.current.name}"
}

# Pipeline monitoring
output "pipeline_cloudwatch_log_group" {
  description = "CloudWatch log group for pipeline events"
  value       = "/aws/codepipeline/${aws_codepipeline.main.name}"
}

# Complete pipeline information
output "pipeline_info" {
  description = "Complete pipeline information"
  value = {
    pipeline_name = aws_codepipeline.main.name
    pipeline_arn  = aws_codepipeline.main.arn
    pipeline_type = aws_codepipeline.main.pipeline_type
    role_arn      = aws_iam_role.codepipeline.arn
    artifacts_bucket = var.create_artifacts_bucket ? aws_s3_bucket.artifacts[0].id : var.existing_artifacts_bucket_name
    github_connection = var.create_github_connection ? aws_codestarconnections_connection.github[0].arn : var.existing_github_connection_arn
    source_repository = var.github_repository
    source_branch     = var.github_branch
    region           = data.aws_region.current.name
  }
}