# ECR Repository Variables

# Required variables
variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9]+(?:[._-][a-z0-9]+)*$", var.repository_name))
    error_message = "Repository name must be lowercase letters, numbers, hyphens, underscores, and periods only."
  }
}

# Optional variables with defaults
variable "image_tag_mutability" {
  description = "The tag mutability setting for the repository"
  type        = string
  default     = "MUTABLE"
  
  validation {
    condition = contains([
      "MUTABLE", 
      "IMMUTABLE", 
      "IMMUTABLE_WITH_EXCLUSION", 
      "MUTABLE_WITH_EXCLUSION"
    ], var.image_tag_mutability)
    error_message = "Image tag mutability must be MUTABLE, IMMUTABLE, IMMUTABLE_WITH_EXCLUSION, or MUTABLE_WITH_EXCLUSION."
  }
}

variable "image_tag_mutability_exclusion_filters" {
  description = "Configuration for image tag mutability exclusion filters"
  type = list(object({
    filter      = string
    filter_type = string
  }))
  default = []
  
  validation {
    condition = alltrue([
      for filter in var.image_tag_mutability_exclusion_filters : filter.filter_type == "WILDCARD"
    ])
    error_message = "Filter type must be WILDCARD."
  }
}

variable "force_delete" {
  description = "If true, will delete the repository even if it contains images"
  type        = bool
  default     = false
}

# Encryption variables
variable "enable_kms_encryption" {
  description = "Whether to enable KMS encryption for the ECR repository"
  type        = bool
  default     = true
}

variable "kms_key_deletion_window" {
  description = "The waiting period, specified in number of days, after which the KMS key is deleted"
  type        = number
  default     = 10
  
  validation {
    condition     = var.kms_key_deletion_window >= 7 && var.kms_key_deletion_window <= 30
    error_message = "KMS key deletion window must be between 7 and 30 days."
  }
}

# Scanning variables
variable "scan_on_push" {
  description = "Indicates whether images are scanned after being pushed to the repository"
  type        = bool
  default     = true
}

variable "enable_registry_scanning" {
  description = "Whether to enable ECR registry scanning configuration"
  type        = bool
  default     = false
}

variable "registry_scan_type" {
  description = "The type of scanning to configure for the registry"
  type        = string
  default     = "ENHANCED"
  
  validation {
    condition     = contains(["BASIC", "ENHANCED"], var.registry_scan_type)
    error_message = "Registry scan type must be BASIC or ENHANCED."
  }
}

variable "registry_scan_rules" {
  description = "Registry scanning rules"
  type = list(object({
    scan_frequency    = string
    repository_filter = string
    filter_type      = string
  }))
  default = []
}

# Policy variables
variable "repository_policy" {
  description = "The JSON policy document for the ECR repository"
  type        = string
  default     = null
}

# Lifecycle policy variables
variable "enable_lifecycle_policy" {
  description = "Whether to enable lifecycle policy for the ECR repository"
  type        = bool
  default     = true
}

variable "lifecycle_policy" {
  description = "The JSON lifecycle policy document for the ECR repository"
  type        = string
  default     = null
}

variable "max_image_count" {
  description = "Maximum number of tagged images to keep"
  type        = number
  default     = 10
  
  validation {
    condition     = var.max_image_count > 0
    error_message = "Maximum image count must be greater than 0."
  }
}

variable "untagged_image_retention_days" {
  description = "Number of days to retain untagged images"
  type        = number
  default     = 7
  
  validation {
    condition     = var.untagged_image_retention_days > 0
    error_message = "Untagged image retention days must be greater than 0."
  }
}

variable "protected_tags" {
  description = "List of image tag prefixes that should be protected from lifecycle policy"
  type        = list(string)
  default     = ["latest", "main", "master", "prod", "production"]
}

# Replication variables
variable "enable_cross_region_replication" {
  description = "Whether to enable cross-region replication"
  type        = bool
  default     = false
}

variable "replication_destinations" {
  description = "Cross-region replication destinations"
  type = list(object({
    destinations = list(object({
      region      = string
      registry_id = string
    }))
    repository_filters = list(object({
      filter      = string
      filter_type = string
    }))
  }))
  default = []
}

# Public repository variables
variable "create_public_repository" {
  description = "Whether to create a public ECR repository"
  type        = bool
  default     = false
}

variable "public_repository_name" {
  description = "Name of the public ECR repository (if different from main repository)"
  type        = string
  default     = ""
}

variable "public_repository_description" {
  description = "Description for the public ECR repository"
  type        = string
  default     = ""
}

variable "public_repository_about_text" {
  description = "About text for the public ECR repository"
  type        = string
  default     = ""
}

variable "public_repository_usage_text" {
  description = "Usage text for the public ECR repository"
  type        = string
  default     = ""
}

variable "public_repository_architectures" {
  description = "List of supported architectures for the public repository"
  type        = list(string)
  default     = ["x86-64"]
}

variable "public_repository_operating_systems" {
  description = "List of supported operating systems for the public repository"
  type        = list(string)
  default     = ["Linux"]
}

variable "public_repository_logo_image_blob" {
  description = "Logo image blob for the public repository"
  type        = string
  default     = null
}

variable "public_repository_policy" {
  description = "The JSON policy document for the public ECR repository"
  type        = string
  default     = null
}

# Tags
variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default = {
    Terraform = "true"
    Module    = "ecr"
  }
}