# CodePipeline Terraform Module

This module creates an AWS CodePipeline with GitHub App integration, supporting flexible build and deployment stages with comprehensive configuration options.

## Features

- **GitHub App Integration**: Secure connection using CodeStar connections
- **V2 Pipeline Support**: Latest pipeline features with advanced triggers
- **Flexible Stages**: Configurable build, deploy, and approval stages
- **Artifact Management**: S3 bucket with lifecycle policies and encryption
- **Advanced Triggers**: Branch, file path, and tag-based triggering
- **Cross-Region Support**: Deploy across multiple AWS regions
- **IAM Integration**: Secure role-based permissions
- **Manual Approvals**: Human approval gates in the pipeline
- **CloudFormation**: Native support for infrastructure deployments

## Architecture

The module creates:
- CodePipeline with configurable stages
- IAM role with least-privilege permissions
- S3 bucket for artifact storage (optional)
- CodeStar connection for GitHub integration (optional)
- CloudWatch integration for monitoring

## Usage

### Basic Usage

```hcl
module "codepipeline" {
  source = "git::https://github.com/PrakashNexTurn/terraform-scripts.git//modules/codepipeline?ref=develop"

  pipeline_name     = "my-app-pipeline"
  github_repository = "myorg/my-app"
  github_branch     = "main"

  build_stages = [
    {
      name = "Build"
      actions = [
        {
          name             = "Build"
          input_artifacts  = ["source_output"]
          output_artifacts = ["build_output"]
          project_name     = "my-app-build"
        }
      ]
    }
  ]

  common_tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

### Advanced Multi-Stage Pipeline

```hcl
module "codepipeline" {
  source = "git::https://github.com/PrakashNexTurn/terraform-scripts.git//modules/codepipeline?ref=develop"

  pipeline_name = "my-production-pipeline"
  pipeline_type = "V2"
  
  github_repository = "myorg/my-app"
  github_branch     = "main"
  source_output_format = "CODEBUILD_CLONE_REF"

  # Artifact bucket configuration
  create_artifacts_bucket = true
  artifacts_bucket_name   = "my-app-pipeline-artifacts"
  artifacts_encryption_key_arn = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"
  
  # Build stages
  build_stages = [
    {
      name = "Test"
      actions = [
        {
          name             = "UnitTests"
          input_artifacts  = ["source_output"]
          output_artifacts = ["test_output"]
          project_name     = "my-app-unit-tests"
          run_order        = 1
        },
        {
          name             = "SecurityScan"
          input_artifacts  = ["source_output"]
          output_artifacts = ["security_output"]
          project_name     = "my-app-security-scan"
          run_order        = 2
        }
      ]
    },
    {
      name = "Build"
      actions = [
        {
          name             = "BuildApp"
          input_artifacts  = ["source_output"]
          output_artifacts = ["build_output"]
          project_name     = "my-app-build"
        }
      ]
    }
  ]

  # Manual approval before production
  approval_stages = [
    {
      name        = "ProductionApproval"
      action_name = "ManualApproval"
      custom_data = "Please review and approve production deployment"
      notification_arn = "arn:aws:sns:us-west-2:123456789012:deployment-approvals"
    }
  ]

  # Deploy stages
  deploy_stages = [
    {
      name = "Deploy"
      actions = [
        {
          name            = "DeployToProduction"
          category        = "Deploy"
          owner           = "AWS"
          provider        = "CloudFormation"
          version         = "1"
          input_artifacts = ["build_output"]
          configuration = {
            ActionMode     = "CREATE_UPDATE"
            StackName      = "my-app-production"
            TemplatePath   = "build_output::infrastructure/template.yaml"
            Capabilities   = "CAPABILITY_IAM,CAPABILITY_NAMED_IAM"
            RoleArn        = "arn:aws:iam::123456789012:role/CloudFormationDeploymentRole"
          }
        }
      ]
    }
  ]

  # Advanced triggers for V2 pipelines
  triggers = [
    {
      provider_type      = "CodeStarSourceConnection"
      source_action_name = "Source"
      
      push_filters = [
        {
          branches = {
            includes = ["main", "release/*"]
            excludes = ["feature/*"]
          }
          file_paths = {
            includes = ["src/**", "infrastructure/**"]
            excludes = ["docs/**", "*.md"]
          }
        }
      ]
      
      pull_request_filters = [
        {
          events = ["OPEN", "UPDATED"]
          branches = {
            includes = ["main"]
          }
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

### Using Existing Resources

```hcl
module "codepipeline" {
  source = "git::https://github.com/PrakashNexTurn/terraform-scripts.git//modules/codepipeline?ref=develop"

  pipeline_name     = "my-app-pipeline"
  github_repository = "myorg/my-app"

  # Use existing resources
  create_artifacts_bucket       = false
  existing_artifacts_bucket_name = "existing-artifacts-bucket"
  existing_artifacts_bucket_arn  = "arn:aws:s3:::existing-artifacts-bucket"

  create_github_connection      = false
  existing_github_connection_arn = "arn:aws:codestar-connections:us-west-2:123456789012:connection/existing-connection"

  build_stages = [
    {
      name = "Build"
      actions = [
        {
          name             = "Build"
          input_artifacts  = ["source_output"]
          output_artifacts = ["build_output"]
          project_name     = "existing-codebuild-project"
        }
      ]
    }
  ]

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
| random | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| pipeline_name | Name of the CodePipeline | `string` | n/a | yes |
| github_repository | GitHub repository in the format 'owner/repo-name' | `string` | n/a | yes |
| pipeline_type | Type of the pipeline (V1 or V2) | `string` | `"V2"` | no |
| github_branch | GitHub branch to track | `string` | `"main"` | no |
| source_output_format | Output format for source artifacts | `string` | `"CODE_ZIP"` | no |
| create_artifacts_bucket | Whether to create a new S3 bucket for artifacts | `bool` | `true` | no |
| build_stages | List of build stages | `list(object)` | `[]` | no |
| deploy_stages | List of deploy stages | `list(object)` | `[]` | no |
| approval_stages | List of manual approval stages | `list(object)` | `[]` | no |
| triggers | Pipeline triggers configuration for V2 pipelines | `list(object)` | `[]` | no |
| common_tags | Common tags to be applied to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| pipeline_id | CodePipeline ID |
| pipeline_name | CodePipeline name |
| pipeline_arn | CodePipeline ARN |
| pipeline_role_arn | ARN of the IAM role used by CodePipeline |
| artifacts_bucket_name | Name of the S3 bucket used for pipeline artifacts |
| github_connection_arn | ARN of the GitHub connection |
| start_execution_command | AWS CLI command to start pipeline execution |
| pipeline_info | Complete pipeline information |

## Examples

See the [examples/basic](examples/basic/) directory for a complete example.

## Security

This module implements several security best practices:

1. **Least Privilege IAM**: Minimal required permissions for CodePipeline
2. **Encrypted Artifacts**: S3 bucket encryption for pipeline artifacts
3. **Secure GitHub Integration**: CodeStar connections instead of webhooks
4. **Cross-Account Roles**: Support for assuming roles in different accounts
5. **VPC Support**: Can deploy to VPC-enabled resources

## Pipeline Stages

### Source Stage
- Always included
- Uses CodeStar connection for GitHub integration
- Supports branch and detection configuration

### Build Stages
- Multiple parallel or sequential build actions
- Supports CodeBuild projects
- Configurable input/output artifacts
- Cross-region build support

### Deploy Stages
- CloudFormation deployments
- ECS deployments
- Lambda deployments
- Custom deployment actions

### Approval Stages
- Manual approval gates
- SNS notifications
- Custom approval data
- External links for context

## Advanced Features

### V2 Pipeline Features
- Advanced Git triggers
- File path filtering
- Branch-based triggers
- Pull request triggers

### Artifact Management
- Automatic S3 bucket creation
- Lifecycle policies
- Encryption support
- Cross-region replication

### Monitoring
- CloudWatch integration
- Pipeline state tracking
- Execution history
- Event notifications

## GitHub App Setup

1. Create a CodeStar connection in the AWS Console
2. Connect to your GitHub organization
3. Use the connection ARN in the module
4. The connection must be in "Available" status

## Cost Optimization

- Lifecycle policies for artifact cleanup
- On-demand build projects
- Efficient trigger configuration
- Regional resource placement

## Troubleshooting

### Common Issues

1. **Connection Not Available**: Ensure GitHub connection is approved
2. **Permission Errors**: Check IAM role permissions
3. **Artifact Errors**: Verify S3 bucket permissions
4. **Build Failures**: Check CodeBuild project configuration

### Monitoring

Use CloudWatch to monitor:
- Pipeline execution status
- Stage completion times
- Failure rates
- Artifact sizes

## License

This module is released under the MIT License. See LICENSE for more details.