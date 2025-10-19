# CodePipeline Variables

# Required variables
variable "pipeline_name" {
  description = "Name of the CodePipeline"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository in the format 'owner/repo-name'"
  type        = string
}

# Optional variables with defaults
variable "pipeline_type" {
  description = "Type of the pipeline (V1 or V2)"
  type        = string
  default     = "V2"
  
  validation {
    condition     = contains(["V1", "V2"], var.pipeline_type)
    error_message = "Pipeline type must be V1 or V2."
  }
}

variable "github_branch" {
  description = "GitHub branch to track"
  type        = string
  default     = "main"
}

variable "source_output_format" {
  description = "Output format for source artifacts"
  type        = string
  default     = "CODE_ZIP"
  
  validation {
    condition     = contains(["CODE_ZIP", "CODEBUILD_CLONE_REF"], var.source_output_format)
    error_message = "Source output format must be CODE_ZIP or CODEBUILD_CLONE_REF."
  }
}

variable "detect_changes" {
  description = "Whether to automatically start pipeline on source changes"
  type        = bool
  default     = true
}

# Artifacts bucket variables
variable "create_artifacts_bucket" {
  description = "Whether to create a new S3 bucket for artifacts"
  type        = bool
  default     = true
}

variable "artifacts_bucket_name" {
  description = "Name of the S3 bucket for artifacts (if creating new bucket)"
  type        = string
  default     = ""
}

variable "existing_artifacts_bucket_name" {
  description = "Name of existing S3 bucket for artifacts"
  type        = string
  default     = ""
}

variable "existing_artifacts_bucket_arn" {
  description = "ARN of existing S3 bucket for artifacts"
  type        = string
  default     = ""
}

variable "artifacts_encryption_key_arn" {
  description = "ARN of KMS key for artifacts encryption"
  type        = string
  default     = ""
}

variable "enable_artifacts_lifecycle" {
  description = "Whether to enable lifecycle policy for artifacts bucket"
  type        = bool
  default     = true
}

variable "artifacts_retention_days" {
  description = "Number of days to retain artifacts"
  type        = number
  default     = 30
}

variable "artifacts_noncurrent_version_retention_days" {
  description = "Number of days to retain non-current versions of artifacts"
  type        = number
  default     = 7
}

# GitHub connection variables
variable "create_github_connection" {
  description = "Whether to create a new GitHub connection"
  type        = bool
  default     = true
}

variable "github_connection_name" {
  description = "Name of the GitHub connection"
  type        = string
  default     = ""
}

variable "existing_github_connection_arn" {
  description = "ARN of existing GitHub connection"
  type        = string
  default     = ""
}

# Build stages configuration
variable "build_stages" {
  description = "List of build stages"
  type = list(object({
    name = string
    actions = list(object({
      name             = string
      input_artifacts  = list(string)
      output_artifacts = list(string)
      project_name     = string
      primary_source   = optional(string)
      run_order        = optional(number)
      region           = optional(string)
    }))
  }))
  default = []
}

# Deploy stages configuration
variable "deploy_stages" {
  description = "List of deploy stages"
  type = list(object({
    name = string
    actions = list(object({
      name            = string
      category        = string
      owner           = string
      provider        = string
      version         = string
      input_artifacts = list(string)
      configuration   = map(string)
      run_order       = optional(number)
      region          = optional(string)
      role_arn        = optional(string)
    }))
  }))
  default = []
}

# Approval stages configuration
variable "approval_stages" {
  description = "List of manual approval stages"
  type = list(object({
    name                = string
    action_name         = string
    notification_arn    = optional(string)
    custom_data         = optional(string)
    external_entity_link = optional(string)
  }))
  default = []
}

# Pipeline triggers (for V2 pipelines)
variable "triggers" {
  description = "Pipeline triggers configuration for V2 pipelines"
  type = list(object({
    provider_type      = string
    source_action_name = string
    push_filters = optional(list(object({
      branches = optional(object({
        includes = optional(list(string))
        excludes = optional(list(string))
      }))
      file_paths = optional(object({
        includes = optional(list(string))
        excludes = optional(list(string))
      }))
      tags = optional(object({
        includes = optional(list(string))
        excludes = optional(list(string))
      }))
    })))
    pull_request_filters = optional(list(object({
      events = list(string)
      branches = optional(object({
        includes = optional(list(string))
        excludes = optional(list(string))
      }))
      file_paths = optional(object({
        includes = optional(list(string))
        excludes = optional(list(string))
      }))
    })))
  }))
  default = []
}

# Common tags
variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default = {
    Terraform = "true"
    Module    = "codepipeline"
  }
}