# IAM Module Variables

# IAM Roles
variable "roles" {
  description = "Map of IAM roles to create"
  type = map(object({
    assume_role_policy   = string
    path                 = optional(string, "/")
    description          = optional(string, "")
    max_session_duration = optional(number, 3600)
    permissions_boundary = optional(string, null)
    policy_arns          = optional(list(string), [])
    inline_policies      = optional(map(string), {})
    tags                 = optional(map(string), {})
  }))
  default = {}
}

# IAM Policies
variable "policies" {
  description = "Map of IAM policies to create"
  type = map(object({
    path            = optional(string, "/")
    description     = optional(string, "")
    policy_document = string
    tags            = optional(map(string), {})
  }))
  default = {}
}

# IAM Users
variable "users" {
  description = "Map of IAM users to create"
  type = map(object({
    path                     = optional(string, "/")
    permissions_boundary     = optional(string, null)
    force_destroy           = optional(bool, false)
    policy_arns             = optional(list(string), [])
    inline_policies         = optional(map(string), {})
    create_access_key       = optional(bool, false)
    access_key_status       = optional(string, "Active")
    pgp_key                 = optional(string, "")
    create_login_profile    = optional(bool, false)
    password_length         = optional(number, 20)
    password_reset_required = optional(bool, true)
    tags                    = optional(map(string), {})
  }))
  default = {}
}

# IAM Groups
variable "groups" {
  description = "Map of IAM groups to create"
  type = map(object({
    path            = optional(string, "/")
    policy_arns     = optional(list(string), [])
    inline_policies = optional(map(string), {})
    users           = optional(list(string), [])
  }))
  default = {}
}

# SAML Identity Providers
variable "saml_providers" {
  description = "Map of SAML identity providers to create"
  type = map(object({
    saml_metadata_document = string
    tags                   = optional(map(string), {})
  }))
  default = {}
}

# OpenID Connect Identity Providers
variable "oidc_providers" {
  description = "Map of OpenID Connect identity providers to create"
  type = map(object({
    url             = string
    client_id_list  = list(string)
    thumbprint_list = list(string)
    tags            = optional(map(string), {})
  }))
  default = {}
}

# Service Account Roles (for IRSA)
variable "service_account_roles" {
  description = "Map of service account roles for IRSA"
  type = map(object({
    oidc_provider_arn        = string
    service_account_subject  = string
    path                     = optional(string, "/")
    description              = optional(string, "")
    max_session_duration     = optional(number, 3600)
    permissions_boundary     = optional(string, null)
    policy_arns              = optional(list(string), [])
    tags                     = optional(map(string), {})
  }))
  default = {}
}

# Instance Profiles
variable "instance_profiles" {
  description = "Map of instance profiles to create"
  type = map(object({
    path      = optional(string, "/")
    role_name = string
    tags      = optional(map(string), {})
  }))
  default = {}
}

# Common tags
variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default = {
    Terraform = "true"
    Module    = "iam"
  }
}