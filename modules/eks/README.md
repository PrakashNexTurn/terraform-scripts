# EKS Terraform Module

This module creates an Amazon Elastic Kubernetes Service (EKS) cluster with managed node groups and all necessary IAM roles and policies.

## Features

- **EKS Cluster v1.33**: Creates a fully managed Kubernetes cluster
- **Managed Node Groups**: Optional managed worker nodes with auto-scaling
- **Security**: KMS encryption for etcd, security groups, and IAM roles
- **High Availability**: Multi-AZ deployment support
- **IRSA Support**: IAM Roles for Service Accounts integration
- **Add-ons**: Support for EKS managed add-ons (CoreDNS, VPC-CNI, kube-proxy)
- **Logging**: CloudWatch cluster logging with configurable log types
- **Flexible Configuration**: Comprehensive variable set for customization

## Architecture

The module creates:
- EKS cluster with configurable Kubernetes version
- IAM roles for cluster and nodes with required policies attached
- KMS key for etcd encryption (optional)
- Managed node groups with scaling configuration
- Security groups for additional rules
- EKS add-ons for cluster functionality
- OIDC provider for IRSA (optional)

## Usage

### Basic Usage

```hcl
module "eks" {
  source = "git::https://github.com/PrakashNexTurn/terraform-scripts.git//modules/eks?ref=develop"

  cluster_name = "my-eks-cluster"
  vpc_id       = "vpc-12345678"
  subnet_ids   = ["subnet-12345", "subnet-67890", "subnet-abcdef"]

  common_tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

### Advanced Usage

```hcl
module "eks" {
  source = "git::https://github.com/PrakashNexTurn/terraform-scripts.git//modules/eks?ref=develop"

  cluster_name       = "my-production-cluster"
  kubernetes_version = "1.33"
  vpc_id            = "vpc-12345678"
  subnet_ids        = ["subnet-12345", "subnet-67890", "subnet-abcdef"]

  # Network configuration
  endpoint_private_access = true
  endpoint_public_access  = false
  public_access_cidrs    = ["10.0.0.0/8"]

  # Security
  enable_encryption = true
  authentication_mode = "API"

  # Node group configuration
  create_node_group               = true
  node_group_name                = "production-nodes"
  node_group_instance_types      = ["m5.large", "m5.xlarge"]
  node_group_capacity_type       = "ON_DEMAND"
  node_group_desired_size        = 3
  node_group_max_size           = 10
  node_group_min_size           = 2
  
  # Remote access
  node_group_remote_access_ec2_ssh_key = "my-key-pair"

  # Add-ons
  cluster_addons = {
    coredns = {
      version = "v1.11.3-eksbuild.2"
    }
    vpc-cni = {
      version = "v1.19.0-eksbuild.1"
    }
    kube-proxy = {
      version = "v1.33.0-eksbuild.1"
    }
    aws-ebs-csi-driver = {
      version = "v1.35.0-eksbuild.1"
    }
  }

  # Logging
  cluster_log_types = ["api", "audit", "authenticator"]

  common_tags = {
    Environment = "production"
    Project     = "my-project"
    Owner       = "platform-team"
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
| tls | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Name of the EKS cluster | `string` | n/a | yes |
| vpc_id | ID of the VPC where the cluster will be deployed | `string` | n/a | yes |
| subnet_ids | List of subnet IDs for the EKS cluster (must be in at least two different availability zones) | `list(string)` | n/a | yes |
| kubernetes_version | Kubernetes version to use for the EKS cluster | `string` | `"1.33"` | no |
| endpoint_private_access | Whether the Amazon EKS private API server endpoint is enabled | `bool` | `true` | no |
| endpoint_public_access | Whether the Amazon EKS public API server endpoint is enabled | `bool` | `true` | no |
| public_access_cidrs | List of CIDR blocks that can access the Amazon EKS public API server endpoint | `list(string)` | `["0.0.0.0/0"]` | no |
| authentication_mode | The authentication mode for the cluster | `string` | `"API_AND_CONFIG_MAP"` | no |
| enable_encryption | Whether to enable EKS cluster encryption | `bool` | `true` | no |
| create_node_group | Whether to create a managed node group | `bool` | `true` | no |
| node_group_instance_types | List of instance types associated with the EKS Node Group | `list(string)` | `["t3.medium"]` | no |
| node_group_capacity_type | Type of capacity associated with the EKS Node Group. Valid values: ON_DEMAND, SPOT | `string` | `"ON_DEMAND"` | no |
| node_group_desired_size | Desired number of nodes in the node group | `number` | `2` | no |
| node_group_max_size | Maximum number of nodes in the node group | `number` | `4` | no |
| node_group_min_size | Minimum number of nodes in the node group | `number` | `1` | no |
| cluster_addons | Map of cluster addon configurations to enable for the cluster | `map(object)` | See variables.tf | no |
| common_tags | Common tags to be applied to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_arn | The Amazon Resource Name (ARN) of the cluster |
| cluster_id | The ID of the EKS cluster |
| cluster_name | The name of the EKS cluster |
| cluster_endpoint | Endpoint for EKS control plane |
| cluster_version | The Kubernetes version for the EKS cluster |
| cluster_certificate_authority_data | Base64 encoded certificate data required to communicate with the cluster |
| cluster_oidc_issuer_url | The URL on the EKS cluster for the OpenID Connect identity provider |
| cluster_iam_role_arn | IAM role ARN associated with EKS cluster |
| node_group_arn | Amazon Resource Name (ARN) of the EKS Node Group |
| node_group_status | Status of the EKS Node Group |
| kms_key_arn | The Amazon Resource Name (ARN) of the KMS key |
| kubeconfig | kubectl config as generated by the module |

## Examples

See the [examples/basic](examples/basic/) directory for a complete example.

## Security

This module implements several security best practices:

1. **Encryption**: KMS encryption for etcd data at rest
2. **Network Security**: Private endpoint support and configurable CIDR access
3. **IAM**: Least privilege IAM roles and policies
4. **Logging**: Comprehensive audit logging capabilities
5. **Updates**: Managed node groups for automated patching

## Kubernetes Version Support

This module supports EKS Kubernetes version 1.33. When upgrading:

1. Update the `kubernetes_version` variable
2. Update add-on versions in `cluster_addons`
3. Plan and apply the changes
4. Update node groups if necessary

## Add-ons

The module includes support for EKS managed add-ons:

- **CoreDNS**: DNS resolution within the cluster
- **VPC-CNI**: Networking plugin for pod networking
- **kube-proxy**: Network proxy running on each node
- **AWS EBS CSI Driver**: For persistent volume support (optional)

## Node Groups

The module creates managed node groups with:

- Auto Scaling Groups for high availability
- Multiple instance types support
- Spot and On-Demand capacity support
- SSH access configuration (optional)
- Custom AMI support

## IRSA (IAM Roles for Service Accounts)

The module creates an OIDC provider to enable IRSA, allowing Kubernetes service accounts to assume IAM roles without storing credentials.

## Monitoring and Logging

- CloudWatch logging for control plane components
- Configurable log types (API, audit, authenticator, etc.)
- Integration with AWS CloudWatch for monitoring

## License

This module is released under the MIT License. See LICENSE for more details.