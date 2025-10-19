# ECR Repository Outputs

# Repository information
output "repository_arn" {
  description = "Full ARN of the repository"
  value       = aws_ecr_repository.main.arn
}

output "repository_name" {
  description = "Name of the repository"
  value       = aws_ecr_repository.main.name
}

output "repository_url" {
  description = "The URL of the repository"
  value       = aws_ecr_repository.main.repository_url
}

output "registry_id" {
  description = "The registry ID where the repository was created"
  value       = aws_ecr_repository.main.registry_id
}

# Repository configuration
output "image_tag_mutability" {
  description = "The tag mutability setting for the repository"
  value       = aws_ecr_repository.main.image_tag_mutability
}

output "image_scanning_configuration" {
  description = "Image scanning configuration for the repository"
  value       = aws_ecr_repository.main.image_scanning_configuration
}

output "encryption_configuration" {
  description = "Encryption configuration for the repository"
  value       = aws_ecr_repository.main.encryption_configuration
}

# KMS Key information
output "kms_key_arn" {
  description = "The Amazon Resource Name (ARN) of the KMS key used for encryption"
  value       = var.enable_kms_encryption ? aws_kms_key.ecr[0].arn : null
}

output "kms_key_id" {
  description = "The globally unique identifier for the KMS key"
  value       = var.enable_kms_encryption ? aws_kms_key.ecr[0].key_id : null
}

output "kms_alias_arn" {
  description = "The Amazon Resource Name (ARN) of the KMS alias"
  value       = var.enable_kms_encryption ? aws_kms_alias.ecr[0].arn : null
}

# Repository policy
output "repository_policy" {
  description = "The repository policy document applied to the repository"
  value       = var.repository_policy != null ? aws_ecr_repository_policy.main[0].policy : null
}

# Lifecycle policy
output "lifecycle_policy" {
  description = "The lifecycle policy document applied to the repository"
  value       = var.enable_lifecycle_policy ? aws_ecr_lifecycle_policy.main[0].policy : null
}

# Public repository information (if created)
output "public_repository_arn" {
  description = "Full ARN of the public repository"
  value       = var.create_public_repository ? aws_ecrpublic_repository.public[0].arn : null
}

output "public_repository_registry_id" {
  description = "The registry ID where the public repository was created"
  value       = var.create_public_repository ? aws_ecrpublic_repository.public[0].registry_id : null
}

output "public_repository_uri" {
  description = "The URI of the public repository"
  value       = var.create_public_repository ? aws_ecrpublic_repository.public[0].repository_uri : null
}

# Replication configuration
output "replication_configuration" {
  description = "The replication configuration for the registry"
  value       = var.enable_cross_region_replication ? aws_ecr_replication_configuration.replication[0] : null
}

# Registry scanning configuration
output "registry_scanning_configuration" {
  description = "The registry scanning configuration"
  value       = var.enable_registry_scanning ? aws_ecr_registry_scanning_configuration.scanning[0] : null
}

# Docker commands for convenience
output "docker_login_command" {
  description = "Docker login command for this repository"
  value       = "aws ecr get-login-password --region ${data.aws_region.current.id} | docker login --username AWS --password-stdin ${aws_ecr_repository.main.repository_url}"
}

output "docker_build_command" {
  description = "Example docker build command"
  value       = "docker build -t ${aws_ecr_repository.main.repository_url}:latest ."
}

output "docker_push_command" {
  description = "Example docker push command"
  value       = "docker push ${aws_ecr_repository.main.repository_url}:latest"
}

# Repository information for CI/CD
output "repository_info" {
  description = "Complete repository information for CI/CD systems"
  value = {
    repository_arn  = aws_ecr_repository.main.arn
    repository_name = aws_ecr_repository.main.name
    repository_url  = aws_ecr_repository.main.repository_url
    registry_id     = aws_ecr_repository.main.registry_id
    region         = data.aws_region.current.id
    account_id     = data.aws_caller_identity.current.account_id
  }
}