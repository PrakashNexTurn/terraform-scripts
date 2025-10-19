# IAM Terraform Module

This module creates comprehensive IAM resources including roles, policies, users, groups, identity providers, and service account roles for IRSA (IAM Roles for Service Accounts).

## Features

- **IAM Roles**: Create roles with assume role policies and attached policies
- **IAM Policies**: Custom managed policies with JSON documents
- **IAM Users**: Users with access keys and login profiles
- **IAM Groups**: Groups with policy attachments and user memberships
- **Identity Providers**: SAML and OpenID Connect providers
- **Service Account Roles**: IRSA roles for EKS service accounts
- **Instance Profiles**: EC2 instance profiles with role attachments
- **Security**: Encrypted passwords and access keys with PGP

## Architecture

The module creates:
- IAM roles with trust policies and permissions
- Custom IAM policies for specific use cases
- IAM users with programmatic and console access
- IAM groups for organizing users and permissions
- Identity providers for federated access
- Service account roles for Kubernetes workloads
- Instance profiles for EC2 instances

## Usage

### Basic Role Creation

```hcl
module "iam" {
  source = "git::https://github.com/PrakashNexTurn/terraform-scripts.git//modules/iam?ref=develop"

  roles = {
    "ec2-role" = {
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
              Service = "ec2.amazonaws.com"
            }
          }
        ]
      })
      description = "Role for EC2 instances"
      policy_arns = [
        "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
      ]
    }
  }

  common_tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

### Advanced Usage with Multiple Resource Types

```hcl
module "iam" {
  source = "git::https://github.com/PrakashNexTurn/terraform-scripts.git//modules/iam?ref=develop"

  # IAM Roles
  roles = {
    "lambda-execution-role" = {
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
              Service = "lambda.amazonaws.com"
            }
          }
        ]
      })
      description = "Execution role for Lambda functions"
      policy_arns = [
        "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
      ]
      inline_policies = {
        "s3-access" = jsonencode({
          Version = "2012-10-17"
          Statement = [
            {
              Effect = "Allow"
              Action = [
                "s3:GetObject",
                "s3:PutObject"
              ]
              Resource = "arn:aws:s3:::my-bucket/*"
            }
          ]
        })
      }
    }
  }

  # Custom Policies
  policies = {
    "custom-s3-policy" = {
      description = "Custom S3 access policy"
      policy_document = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "s3:ListBucket",
              "s3:GetObject",
              "s3:PutObject",
              "s3:DeleteObject"
            ]
            Resource = [
              "arn:aws:s3:::my-app-bucket",
              "arn:aws:s3:::my-app-bucket/*"
            ]
          }
        ]
      })
    }
  }

  # IAM Users
  users = {
    "service-user" = {
      description = "Service account for applications"
      create_access_key = true
      policy_arns = [
        "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
      ]
    }
    "developer" = {
      description = "Developer user"
      create_login_profile = true
      password_length = 16
      password_reset_required = true
    }
  }

  # IAM Groups
  groups = {
    "developers" = {
      users = ["developer"]
      policy_arns = [
        "arn:aws:iam::aws:policy/PowerUserAccess"
      ]
      inline_policies = {
        "deny-billing" = jsonencode({
          Version = "2012-10-17"
          Statement = [
            {
              Effect = "Deny"
              Action = "aws-portal:*"
              Resource = "*"
            }
          ]
        })
      }
    }
  }

  # Instance Profiles
  instance_profiles = {
    "ec2-profile" = {
      role_name = "lambda-execution-role"
    }
  }

  common_tags = {
    Environment = "production"
    Project     = "my-project"
    Owner       = "platform-team"
  }
}
```

### Service Account Roles (IRSA) for EKS

```hcl
module "iam_eks" {
  source = "git::https://github.com/PrakashNexTurn/terraform-scripts.git//modules/iam?ref=develop"

  # OIDC Provider for EKS
  oidc_providers = {
    "eks-oidc" = {
      url = "https://oidc.eks.us-west-2.amazonaws.com/id/ABCDEF1234567890"
      client_id_list = ["sts.amazonaws.com"]
      thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]
    }
  }

  # Service Account Roles
  service_account_roles = {
    "aws-load-balancer-controller" = {
      oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-west-2.amazonaws.com/id/ABCDEF1234567890"
      service_account_subject = "system:serviceaccount:kube-system:aws-load-balancer-controller"
      description = "Role for AWS Load Balancer Controller"
      policy_arns = [
        "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
      ]
    }
    "external-dns" = {
      oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-west-2.amazonaws.com/id/ABCDEF1234567890"
      service_account_subject = "system:serviceaccount:external-dns:external-dns"
      description = "Role for External DNS"
      policy_arns = [
        "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
      ]
    }
  }

  common_tags = {
    Environment = "production"
    Project     = "eks-cluster"
  }
}
```

### Identity Providers

```hcl
module "iam_identity" {
  source = "git::https://github.com/PrakashNexTurn/terraform-scripts.git//modules/iam?ref=develop"

  # SAML Identity Provider
  saml_providers = {
    "company-sso" = {
      saml_metadata_document = file("${path.module}/saml-metadata.xml")
    }
  }

  # Roles for federated users
  roles = {
    "federated-admin" = {
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Principal = {
              Federated = "arn:aws:iam::123456789012:saml-provider/company-sso"
            }
            Action = "sts:AssumeRoleWithSAML"
            Condition = {
              StringEquals = {
                "SAML:Role" = "Admin"
              }
            }
          }
        ]
      })
      description = "Admin role for federated users"
      policy_arns = [
        "arn:aws:iam::aws:policy/AdministratorAccess"
      ]
    }
  }

  common_tags = {
    Environment = "production"
    Project     = "identity-federation"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| roles | Map of IAM roles to create | `map(object)` | `{}` | no |
| policies | Map of IAM policies to create | `map(object)` | `{}` | no |
| users | Map of IAM users to create | `map(object)` | `{}` | no |
| groups | Map of IAM groups to create | `map(object)` | `{}` | no |
| saml_providers | Map of SAML identity providers to create | `map(object)` | `{}` | no |
| oidc_providers | Map of OpenID Connect identity providers to create | `map(object)` | `{}` | no |
| service_account_roles | Map of service account roles for IRSA | `map(object)` | `{}` | no |
| instance_profiles | Map of instance profiles to create | `map(object)` | `{}` | no |
| common_tags | Common tags to be applied to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| roles | Map of IAM roles created |
| role_arns | Map of IAM role ARNs |
| policies | Map of IAM policies created |
| policy_arns | Map of IAM policy ARNs |
| users | Map of IAM users created |
| user_arns | Map of IAM user ARNs |
| access_keys | Map of IAM access keys (encrypted) |
| groups | Map of IAM groups created |
| service_account_roles | Map of service account roles created |
| service_account_role_arns | Map of service account role ARNs |
| instance_profiles | Map of instance profiles created |
| all_role_arns | Combined map of all role ARNs |

## Security Best Practices

This module implements several security best practices:

1. **Least Privilege**: Policies follow principle of least privilege
2. **Encrypted Secrets**: Access keys and passwords are encrypted with PGP
3. **Permission Boundaries**: Support for IAM permission boundaries
4. **Trust Policies**: Explicit assume role policies for all roles
5. **Federated Access**: Support for SAML and OIDC identity providers

## Access Key Management

When creating access keys:

1. Always use PGP encryption for secrets
2. Rotate access keys regularly
3. Use IAM roles instead of access keys when possible
4. Monitor access key usage with CloudTrail

## Password Management

For user login profiles:

1. Enforce strong password policies
2. Require password reset on first login
3. Use PGP encryption for temporary passwords
4. Implement MFA requirements separately

## Service Account Roles (IRSA)

For Kubernetes service accounts:

1. Create OIDC provider for your EKS cluster
2. Use specific service account subjects
3. Limit permissions to required actions only
4. Regularly audit role usage

## Cross-Module Integration

This module integrates well with:

- **EKS Module**: Provides service account roles for workloads
- **CodePipeline Module**: Creates roles for deployment pipelines
- **ECR Module**: Provides roles for image registry access

## Monitoring and Auditing

Use CloudTrail and IAM Access Analyzer to:

- Monitor role usage and permissions
- Detect unused roles and policies
- Analyze cross-account access
- Review policy effectiveness

## Cost Optimization

- Remove unused roles and policies regularly
- Use managed policies where possible
- Implement automated cleanup processes
- Monitor IAM costs with Cost Explorer

## License

This module is released under the MIT License. See LICENSE for more details.