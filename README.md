# Terraform AWS Modules

A comprehensive collection of reusable Terraform modules for AWS infrastructure components. These modules follow AWS and Terraform best practices and are designed to be consumed via Git references.

## 📋 Available Modules

### 🚀 Container & Compute
- **[EKS](modules/eks/)** - Amazon Elastic Kubernetes Service cluster with managed node groups (v1.33)
- **[ECR](modules/ecr/)** - Amazon Elastic Container Registry with lifecycle policies and scanning

### 🔄 CI/CD & DevOps  
- **[CodePipeline](modules/codepipeline/)** - AWS CodePipeline with GitHub App integration
- **[IAM](modules/iam/)** - Comprehensive IAM roles, policies, users, groups, and IRSA

## 🏗️ Architecture

These modules are designed to work together seamlessly:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   CodePipeline  │───▶│      ECR        │───▶│      EKS        │
│   (CI/CD)       │    │  (Registry)     │    │   (Runtime)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                         IAM Module                              │
│              (Roles, Policies, Service Accounts)               │
└─────────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Using a Module

```hcl
module "my_eks_cluster" {
  source = "git::https://github.com/PrakashNexTurn/terraform-scripts.git//modules/eks?ref=develop"

  cluster_name = "my-production-cluster"
  vpc_id       = "vpc-12345678"
  subnet_ids   = ["subnet-12345", "subnet-67890"]

  common_tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

### Module Versioning

Use Git references to pin to specific versions:

```hcl
# Use develop branch (latest)
source = "git::https://github.com/PrakashNexTurn/terraform-scripts.git//modules/eks?ref=develop"

# Use specific tag
source = "git::https://github.com/PrakashNexTurn/terraform-scripts.git//modules/eks?ref=v1.0.0"

# Use specific commit
source = "git::https://github.com/PrakashNexTurn/terraform-scripts.git//modules/eks?ref=abc123"
```

## 📚 Module Documentation

| Module | Description | Version | Examples |
|--------|-------------|---------|----------|
| [EKS](modules/eks/) | Kubernetes cluster with v1.33 support | [![EKS](https://img.shields.io/badge/EKS-v1.33-blue)](modules/eks/) | [Basic](modules/eks/examples/basic/) |
| [ECR](modules/ecr/) | Container registry with security scanning | [![ECR](https://img.shields.io/badge/ECR-Latest-green)](modules/ecr/) | [Basic](modules/ecr/examples/basic/) |
| [CodePipeline](modules/codepipeline/) | CI/CD pipeline with GitHub integration | [![Pipeline](https://img.shields.io/badge/Pipeline-V2-orange)](modules/codepipeline/) | Coming Soon |
| [IAM](modules/iam/) | Identity and access management | [![IAM](https://img.shields.io/badge/IAM-Comprehensive-red)](modules/iam/) | Coming Soon |

## 🛠️ Development

### Prerequisites

- Terraform >= 1.0
- AWS CLI configured
- Git

### Testing Modules

The repository includes comprehensive GitHub Actions workflows for testing:

```bash
# Test specific module locally
cd modules/eks
terraform init
terraform validate
terraform plan -var="vpc_id=vpc-test" -var="subnet_ids=[\"subnet-1\",\"subnet-2\"]"
```

### Module Structure

Each module follows this standard structure:

```
modules/
├── <module-name>/
│   ├── main.tf          # Main resource definitions
│   ├── variables.tf     # Input variables
│   ├── outputs.tf       # Output values
│   ├── README.md        # Module documentation
│   └── examples/
│       └── basic/       # Basic usage example
│           ├── main.tf
│           ├── variables.tf
│           └── outputs.tf
```

## 🔒 Security & Best Practices

### Security Features

- **Encryption**: All modules support KMS encryption where applicable
- **Least Privilege**: IAM policies follow principle of least privilege  
- **Network Security**: VPC and security group configurations
- **Scanning**: Container image vulnerability scanning
- **Secrets**: Encrypted handling of sensitive data

### Best Practices Implemented

- **Tagging Strategy**: Consistent resource tagging
- **Naming Conventions**: Standardized resource naming
- **Documentation**: Comprehensive README files
- **Examples**: Working examples for each module
- **Testing**: Automated validation and linting
- **Versioning**: Git-based module versioning

## 📖 Usage Examples

### Complete Application Stack

```hcl
# IAM Roles and Policies
module "iam" {
  source = "git::https://github.com/PrakashNexTurn/terraform-scripts.git//modules/iam?ref=develop"
  
  roles = {
    "eks-node-role" = {
      assume_role_policy = data.aws_iam_policy_document.eks_node_assume_role.json
      policy_arns = [
        "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
        "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      ]
    }
  }
}

# Container Registry
module "ecr" {
  source = "git::https://github.com/PrakashNexTurn/terraform-scripts.git//modules/ecr?ref=develop"
  
  repository_name = "my-app"
  scan_on_push   = true
  
  common_tags = local.common_tags
}

# Kubernetes Cluster
module "eks" {
  source = "git::https://github.com/PrakashNexTurn/terraform-scripts.git//modules/eks?ref=develop"
  
  cluster_name = "my-production-cluster"
  vpc_id       = data.aws_vpc.main.id
  subnet_ids   = data.aws_subnets.private.ids
  
  # Use IAM role from IAM module
  node_group_role_arn = module.iam.role_arns["eks-node-role"]
  
  common_tags = local.common_tags
}

# CI/CD Pipeline
module "pipeline" {
  source = "git::https://github.com/PrakashNexTurn/terraform-scripts.git//modules/codepipeline?ref=develop"
  
  pipeline_name     = "my-app-pipeline"
  github_repository = "myorg/my-app"
  
  build_stages = [
    {
      name = "Build"
      actions = [
        {
          name             = "BuildImage"
          input_artifacts  = ["source_output"]
          output_artifacts = ["build_output"]
          project_name     = aws_codebuild_project.build.name
        }
      ]
    }
  ]
  
  common_tags = local.common_tags
}

locals {
  common_tags = {
    Environment = "production"
    Project     = "my-app"
    Owner       = "platform-team"
    Terraform   = "true"
  }
}
```

## 🧪 Testing

### Automated Testing

The repository includes comprehensive testing:

- **Validation**: `terraform validate` for syntax checking
- **Formatting**: `terraform fmt` for code formatting  
- **Linting**: TFLint for best practices
- **Security**: Checkov for security scanning
- **Integration**: Cross-module compatibility testing

### Manual Testing

```bash
# Clone repository
git clone https://github.com/PrakashNexTurn/terraform-scripts.git
cd terraform-scripts

# Test a specific module
cd modules/eks
terraform init
terraform validate

# Test with example
cd examples/basic
terraform init
terraform plan -var-file="terraform.tfvars.example"
```

## 🔧 Configuration

### Required Providers

All modules require:

```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
```

### Common Variables

Most modules support these common variables:

```hcl
variable "common_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}
```

## 📈 Monitoring & Logging

### CloudWatch Integration

All modules integrate with AWS CloudWatch for:

- **Metrics**: Resource utilization and performance
- **Logs**: Application and infrastructure logs  
- **Alarms**: Automated alerting and notifications
- **Dashboards**: Visual monitoring interfaces

### Cost Management

- **Tagging**: Consistent cost allocation tags
- **Lifecycle Policies**: Automated resource cleanup
- **Right-sizing**: Appropriate resource sizing recommendations
- **Reserved Capacity**: Support for reserved instances and savings plans

## 🤝 Contributing

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/DEVOPS-123`)
3. **Follow** the module structure guidelines
4. **Test** your changes thoroughly
5. **Submit** a pull request

### Contribution Guidelines

- Follow existing code style and structure
- Include comprehensive documentation
- Add examples for new modules
- Ensure all tests pass
- Update README files as needed

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/PrakashNexTurn/terraform-scripts/issues)
- **Documentation**: Module-specific README files
- **Examples**: Working examples in each module

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏷️ Tags

`terraform` `aws` `infrastructure` `iac` `kubernetes` `eks` `ecr` `codepipeline` `iam` `devops` `ci-cd`

---

**Made with ❤️ by the Platform Team**