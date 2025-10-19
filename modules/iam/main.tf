# IAM Module
# This module creates IAM roles, policies, users, and groups with comprehensive configuration

# Data source for current AWS caller identity
data "aws_caller_identity" "current" {}

# Data source for current AWS region
data "aws_region" "current" {}

# IAM Roles
resource "aws_iam_role" "roles" {
  for_each = var.roles

  name                 = each.key
  assume_role_policy   = each.value.assume_role_policy
  path                 = each.value.path
  description          = each.value.description
  max_session_duration = each.value.max_session_duration
  permissions_boundary = each.value.permissions_boundary

  dynamic "inline_policy" {
    for_each = each.value.inline_policies
    content {
      name   = inline_policy.key
      policy = inline_policy.value
    }
  }

  tags = merge(
    var.common_tags,
    each.value.tags,
    {
      Name = each.key
    }
  )
}

# IAM Role Policy Attachments
resource "aws_iam_role_policy_attachment" "role_policies" {
  for_each = local.role_policy_attachments

  role       = aws_iam_role.roles[each.value.role_name].name
  policy_arn = each.value.policy_arn
}

# IAM Policies
resource "aws_iam_policy" "policies" {
  for_each = var.policies

  name        = each.key
  path        = each.value.path
  description = each.value.description
  policy      = each.value.policy_document

  tags = merge(
    var.common_tags,
    each.value.tags,
    {
      Name = each.key
    }
  )
}

# IAM Users
resource "aws_iam_user" "users" {
  for_each = var.users

  name                 = each.key
  path                 = each.value.path
  permissions_boundary = each.value.permissions_boundary
  force_destroy        = each.value.force_destroy

  tags = merge(
    var.common_tags,
    each.value.tags,
    {
      Name = each.key
    }
  )
}

# IAM User Policy Attachments
resource "aws_iam_user_policy_attachment" "user_policies" {
  for_each = local.user_policy_attachments

  user       = aws_iam_user.users[each.value.user_name].name
  policy_arn = each.value.policy_arn
}

# IAM User Inline Policies
resource "aws_iam_user_policy" "user_inline_policies" {
  for_each = local.user_inline_policies

  name   = each.value.policy_name
  user   = aws_iam_user.users[each.value.user_name].name
  policy = each.value.policy_document
}

# IAM Groups
resource "aws_iam_group" "groups" {
  for_each = var.groups

  name = each.key
  path = each.value.path
}

# IAM Group Policy Attachments
resource "aws_iam_group_policy_attachment" "group_policies" {
  for_each = local.group_policy_attachments

  group      = aws_iam_group.groups[each.value.group_name].name
  policy_arn = each.value.policy_arn
}

# IAM Group Inline Policies
resource "aws_iam_group_policy" "group_inline_policies" {
  for_each = local.group_inline_policies

  name   = each.value.policy_name
  group  = aws_iam_group.groups[each.value.group_name].name
  policy = each.value.policy_document
}

# IAM Group Memberships
resource "aws_iam_group_membership" "group_memberships" {
  for_each = var.groups

  name  = "${each.key}-membership"
  group = aws_iam_group.groups[each.key].name
  users = [
    for user in each.value.users : aws_iam_user.users[user].name
  ]
}

# IAM Access Keys
resource "aws_iam_access_key" "access_keys" {
  for_each = {
    for user_name, user_config in var.users : user_name => user_config
    if user_config.create_access_key
  }

  user    = aws_iam_user.users[each.key].name
  pgp_key = each.value.pgp_key
  status  = each.value.access_key_status
}

# IAM User Login Profile (Console Password)
resource "aws_iam_user_login_profile" "login_profiles" {
  for_each = {
    for user_name, user_config in var.users : user_name => user_config
    if user_config.create_login_profile
  }

  user                    = aws_iam_user.users[each.key].name
  pgp_key                 = each.value.pgp_key
  password_length         = each.value.password_length
  password_reset_required = each.value.password_reset_required
}

# IAM SAML Identity Provider
resource "aws_iam_saml_identity_provider" "saml_providers" {
  for_each = var.saml_providers

  name                   = each.key
  saml_metadata_document = each.value.saml_metadata_document

  tags = merge(
    var.common_tags,
    each.value.tags,
    {
      Name = each.key
    }
  )
}

# IAM OpenID Connect Identity Provider
resource "aws_iam_openid_connect_provider" "oidc_providers" {
  for_each = var.oidc_providers

  url             = each.value.url
  client_id_list  = each.value.client_id_list
  thumbprint_list = each.value.thumbprint_list

  tags = merge(
    var.common_tags,
    each.value.tags,
    {
      Name = each.key
    }
  )
}

# IAM Role for Service Accounts (IRSA) - for EKS
resource "aws_iam_role" "service_account_roles" {
  for_each = var.service_account_roles

  name = each.key

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = each.value.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(each.value.oidc_provider_arn, "/.*provider//", "")}:sub" = each.value.service_account_subject
            "${replace(each.value.oidc_provider_arn, "/.*provider//", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  path                 = each.value.path
  description          = each.value.description
  max_session_duration = each.value.max_session_duration
  permissions_boundary = each.value.permissions_boundary

  tags = merge(
    var.common_tags,
    each.value.tags,
    {
      Name = each.key
    }
  )
}

# IAM Service Account Role Policy Attachments
resource "aws_iam_role_policy_attachment" "service_account_role_policies" {
  for_each = local.service_account_role_policy_attachments

  role       = aws_iam_role.service_account_roles[each.value.role_name].name
  policy_arn = each.value.policy_arn
}

# Instance Profiles
resource "aws_iam_instance_profile" "instance_profiles" {
  for_each = var.instance_profiles

  name = each.key
  path = each.value.path
  role = aws_iam_role.roles[each.value.role_name].name

  tags = merge(
    var.common_tags,
    each.value.tags,
    {
      Name = each.key
    }
  )
}

# Local values for flattening nested structures
locals {
  # Role policy attachments
  role_policy_attachments = merge([
    for role_name, role_config in var.roles : {
      for policy_arn in role_config.policy_arns : "${role_name}-${replace(policy_arn, "/[:/-]/", "_")}" => {
        role_name  = role_name
        policy_arn = policy_arn
      }
    }
  ]...)

  # User policy attachments
  user_policy_attachments = merge([
    for user_name, user_config in var.users : {
      for policy_arn in user_config.policy_arns : "${user_name}-${replace(policy_arn, "/[:/-]/", "_")}" => {
        user_name  = user_name
        policy_arn = policy_arn
      }
    }
  ]...)

  # User inline policies
  user_inline_policies = merge([
    for user_name, user_config in var.users : {
      for policy_name, policy_document in user_config.inline_policies : "${user_name}-${policy_name}" => {
        user_name       = user_name
        policy_name     = policy_name
        policy_document = policy_document
      }
    }
  ]...)

  # Group policy attachments
  group_policy_attachments = merge([
    for group_name, group_config in var.groups : {
      for policy_arn in group_config.policy_arns : "${group_name}-${replace(policy_arn, "/[:/-]/", "_")}" => {
        group_name = group_name
        policy_arn = policy_arn
      }
    }
  ]...)

  # Group inline policies
  group_inline_policies = merge([
    for group_name, group_config in var.groups : {
      for policy_name, policy_document in group_config.inline_policies : "${group_name}-${policy_name}" => {
        group_name      = group_name
        policy_name     = policy_name
        policy_document = policy_document
      }
    }
  ]...)

  # Service account role policy attachments
  service_account_role_policy_attachments = merge([
    for role_name, role_config in var.service_account_roles : {
      for policy_arn in role_config.policy_arns : "${role_name}-${replace(policy_arn, "/[:/-]/", "_")}" => {
        role_name  = role_name
        policy_arn = policy_arn
      }
    }
  ]...)
}