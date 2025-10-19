# IAM Module Outputs

# IAM Roles
output "roles" {
  description = "Map of IAM roles created"
  value = {
    for name, role in aws_iam_role.roles : name => {
      arn                  = role.arn
      id                   = role.id
      name                 = role.name
      path                 = role.path
      unique_id            = role.unique_id
      max_session_duration = role.max_session_duration
    }
  }
}

output "role_arns" {
  description = "Map of IAM role ARNs"
  value       = { for name, role in aws_iam_role.roles : name => role.arn }
}

output "role_names" {
  description = "Map of IAM role names"
  value       = { for name, role in aws_iam_role.roles : name => role.name }
}

# IAM Policies
output "policies" {
  description = "Map of IAM policies created"
  value = {
    for name, policy in aws_iam_policy.policies : name => {
      arn         = policy.arn
      id          = policy.id
      name        = policy.name
      path        = policy.path
      description = policy.description
      policy      = policy.policy
    }
  }
}

output "policy_arns" {
  description = "Map of IAM policy ARNs"
  value       = { for name, policy in aws_iam_policy.policies : name => policy.arn }
}

# IAM Users
output "users" {
  description = "Map of IAM users created"
  value = {
    for name, user in aws_iam_user.users : name => {
      arn       = user.arn
      id        = user.id
      name      = user.name
      path      = user.path
      unique_id = user.unique_id
    }
  }
}

output "user_arns" {
  description = "Map of IAM user ARNs"
  value       = { for name, user in aws_iam_user.users : name => user.arn }
}

output "user_names" {
  description = "Map of IAM user names"
  value       = { for name, user in aws_iam_user.users : name => user.name }
}

# IAM Access Keys (encrypted)
output "access_keys" {
  description = "Map of IAM access keys (encrypted)"
  value = {
    for name, key in aws_iam_access_key.access_keys : name => {
      id                     = key.id
      encrypted_secret       = key.encrypted_secret
      key_fingerprint        = key.key_fingerprint
      encrypted_ses_smtp_password_v4 = key.encrypted_ses_smtp_password_v4
      secret                 = key.secret
      ses_smtp_password_v4   = key.ses_smtp_password_v4
    }
  }
  sensitive = true
}

# IAM User Login Profiles (encrypted)
output "user_login_profiles" {
  description = "Map of IAM user login profiles (encrypted)"
  value = {
    for name, profile in aws_iam_user_login_profile.login_profiles : name => {
      encrypted_password = profile.encrypted_password
      key_fingerprint    = profile.key_fingerprint
      password           = profile.password
    }
  }
  sensitive = true
}

# IAM Groups
output "groups" {
  description = "Map of IAM groups created"
  value = {
    for name, group in aws_iam_group.groups : name => {
      arn       = group.arn
      id        = group.id
      name      = group.name
      path      = group.path
      unique_id = group.unique_id
    }
  }
}

output "group_arns" {
  description = "Map of IAM group ARNs"
  value       = { for name, group in aws_iam_group.groups : name => group.arn }
}

# IAM SAML Identity Providers
output "saml_providers" {
  description = "Map of SAML identity providers created"
  value = {
    for name, provider in aws_iam_saml_identity_provider.saml_providers : name => {
      arn = provider.arn
      id  = provider.id
    }
  }
}

# IAM OpenID Connect Identity Providers
output "oidc_providers" {
  description = "Map of OpenID Connect identity providers created"
  value = {
    for name, provider in aws_iam_openid_connect_provider.oidc_providers : name => {
      arn = provider.arn
      id  = provider.id
      url = provider.url
    }
  }
}

output "oidc_provider_arns" {
  description = "Map of OpenID Connect provider ARNs"
  value       = { for name, provider in aws_iam_openid_connect_provider.oidc_providers : name => provider.arn }
}

# Service Account Roles (IRSA)
output "service_account_roles" {
  description = "Map of service account roles created"
  value = {
    for name, role in aws_iam_role.service_account_roles : name => {
      arn                  = role.arn
      id                   = role.id
      name                 = role.name
      path                 = role.path
      unique_id            = role.unique_id
      max_session_duration = role.max_session_duration
    }
  }
}

output "service_account_role_arns" {
  description = "Map of service account role ARNs"
  value       = { for name, role in aws_iam_role.service_account_roles : name => role.arn }
}

# Instance Profiles
output "instance_profiles" {
  description = "Map of instance profiles created"
  value = {
    for name, profile in aws_iam_instance_profile.instance_profiles : name => {
      arn       = profile.arn
      id        = profile.id
      name      = profile.name
      path      = profile.path
      unique_id = profile.unique_id
    }
  }
}

output "instance_profile_arns" {
  description = "Map of instance profile ARNs"
  value       = { for name, profile in aws_iam_instance_profile.instance_profiles : name => profile.arn }
}

# Useful outputs for cross-module integration
output "all_role_arns" {
  description = "Combined map of all role ARNs (regular and service account)"
  value = merge(
    { for name, role in aws_iam_role.roles : name => role.arn },
    { for name, role in aws_iam_role.service_account_roles : name => role.arn }
  )
}

output "all_policy_arns" {
  description = "Map of all policy ARNs created by this module"
  value = { for name, policy in aws_iam_policy.policies : name => policy.arn }
}