# ECR Terraform Module

This module creates an Amazon Elastic Container Registry (ECR) repository with comprehensive configuration options including lifecycle policies, scanning, encryption, and replication.

## Features

- **Private ECR Repository**: Secure container image storage
- **Public ECR Repository**: Optional public container registry
- **KMS Encryption**: Custom KMS key for image encryption at rest
- **Image Scanning**: Vulnerability scanning on push
- **Lifecycle Policies**: Automated image cleanup and retention
- **Cross-Region Replication**: Multi-region image replication
- **Repository Policies**: Fine-grained access control
- **Tag Mutability**: Flexible image tag management
- **Registry Scanning**: Enhanced vulnerability scanning

## Architecture

The module creates:
- ECR private repository with configurable settings
- KMS key and alias for encryption (optional)
- Lifecycle policy for image management
- Repository policy for access control (optional)
- Cross-region replication configuration (optional)
- Public ECR repository (optional)
- Registry-level scanning configuration (optional)

## Usage

### Basic Usage

```hcl
module "ecr" {
  source = "git::https://github.com/PrakashNexTurn/terraform-scripts.git//modules/ecr?ref=develop"

  repository_name = "my-app"

  common_tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

### Advanced Usage

```hcl
module "ecr" {
  source = "git::https://github.com/PrakashNexTurn/terraform-scripts.git//modules/ecr?ref=develop"

  repository_name      = "my-production-app"
  image_tag_mutability = "IMMUTABLE"
  force_delete        = false

  # Encryption
  enable_kms_encryption = true

  # Scanning
  scan_on_push = true
  enable_registry_scanning = true
  registry_scan_type = "ENHANCED"

  # Lifecycle policy
  enable_lifecycle_policy = true
  max_image_count = 20
  untagged_image_retention_days = 3
  protected_tags = ["latest", "main", "prod", "v*"]

  # Repository policy for cross-account access
  repository_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CrossAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::123456789012:root"
        }
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
      }
    ]
  })

  # Cross-region replication
  enable_cross_region_replication = true
  replication_destinations = [
    {
      destinations = [
        {
          region      = "us-east-1"
          registry_id = "123456789012"
        },
        {
          region      = "eu-west-1"
          registry_id = "123456789012"
        }
      ]
      repository_filters = [
        {
          filter      = "my-production-app"
          filter_type = "PREFIX_MATCH"
        }
      ]
    }
  ]

  common_tags = {
    Environment = "production"
    Project     = "my-project"
    Owner       = "platform-team"
  }
}
```

### Public Repository Usage

```hcl
module "ecr_public" {
  source = "git::https://github.com/PrakashNexTurn/terraform-scripts.git//modules/ecr?ref=develop"

  repository_name = "my-private-app"

  # Public repository configuration
  create_public_repository = true
  public_repository_name = "my-public-app"
  public_repository_description = "My awesome public container image"
  public_repository_about_text = "This is a sample application container"
  public_repository_usage_text = "docker pull public.ecr.aws/my-org/my-public-app:latest"
  public_repository_architectures = ["x86-64", "ARM 64"]
  public_repository_operating_systems = ["Linux", "Windows"]

  common_tags = {
    Environment = "production"
    Project     = "my-project"
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
| repository_name | Name of the ECR repository | `string` | n/a | yes |
| image_tag_mutability | The tag mutability setting for the repository | `string` | `"MUTABLE"` | no |
| force_delete | If true, will delete the repository even if it contains images | `bool` | `false` | no |
| enable_kms_encryption | Whether to enable KMS encryption for the ECR repository | `bool` | `true` | no |
| scan_on_push | Indicates whether images are scanned after being pushed to the repository | `bool` | `true` | no |
| enable_lifecycle_policy | Whether to enable lifecycle policy for the ECR repository | `bool` | `true` | no |
| max_image_count | Maximum number of tagged images to keep | `number` | `10` | no |
| untagged_image_retention_days | Number of days to retain untagged images | `number` | `7` | no |
| protected_tags | List of image tag prefixes that should be protected from lifecycle policy | `list(string)` | `["latest", "main", "master", "prod", "production"]` | no |
| repository_policy | The JSON policy document for the ECR repository | `string` | `null` | no |
| enable_cross_region_replication | Whether to enable cross-region replication | `bool` | `false` | no |
| create_public_repository | Whether to create a public ECR repository | `bool` | `false` | no |
| common_tags | Common tags to be applied to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| repository_arn | Full ARN of the repository |
| repository_name | Name of the repository |
| repository_url | The URL of the repository |
| registry_id | The registry ID where the repository was created |
| kms_key_arn | The Amazon Resource Name (ARN) of the KMS key used for encryption |
| docker_login_command | Docker login command for this repository |
| docker_build_command | Example docker build command |
| docker_push_command | Example docker push command |
| repository_info | Complete repository information for CI/CD systems |

## Examples

See the [examples/basic](examples/basic/) directory for a complete example.

## Security

This module implements several security best practices:

1. **Encryption at Rest**: KMS encryption with customer-managed keys
2. **Image Scanning**: Vulnerability scanning on image push
3. **Access Control**: Repository policies for fine-grained permissions
4. **Lifecycle Management**: Automated cleanup of old images
5. **Tag Immutability**: Option to prevent tag overwrites

## Image Lifecycle Management

The module automatically creates a lifecycle policy that:

1. **Keeps Tagged Images**: Retains the most recent tagged images (configurable count)
2. **Protects Important Tags**: Excludes critical tags from cleanup (latest, prod, etc.)
3. **Cleans Untagged Images**: Removes untagged images after specified days
4. **Custom Rules**: Supports custom lifecycle policy JSON

## Scanning

Two types of scanning are supported:

1. **Basic Scanning**: Uses Amazon ECR basic scanning (CVE database)
2. **Enhanced Scanning**: Uses Amazon Inspector for comprehensive scanning

Enable enhanced scanning for production workloads for better security insights.

## Cross-Region Replication

Configure cross-region replication for:

- **Disaster Recovery**: Images available in multiple regions
- **Performance**: Reduce image pull latency
- **Compliance**: Data residency requirements

## Tag Mutability

Four tag mutability options:

1. **MUTABLE**: Tags can be overwritten (default)
2. **IMMUTABLE**: Tags cannot be overwritten
3. **IMMUTABLE_WITH_EXCLUSION**: Immutable with specific tag exceptions
4. **MUTABLE_WITH_EXCLUSION**: Mutable with specific tag restrictions

## Integration with CI/CD

The module outputs convenient commands and information for CI/CD integration:

- Docker login commands
- Repository URLs and ARNs
- Registry information
- Build and push commands

## Monitoring and Logging

ECR integrates with CloudWatch for:

- Repository events
- Image scan results
- Push/pull metrics
- Lifecycle policy events

## Cost Optimization

Built-in cost optimization features:

- Lifecycle policies to clean up old images
- Configurable retention periods
- Protected tags to prevent accidental deletion
- Cross-region replication only when needed

## License

This module is released under the MIT License. See LICENSE for more details.