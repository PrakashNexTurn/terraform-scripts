# EKS Cluster Outputs

# Cluster information
output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = aws_eks_cluster.main.arn
}

output "cluster_id" {
  description = "The ID of the EKS cluster"
  value       = aws_eks_cluster.main.id
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  description = "The Kubernetes version for the EKS cluster"
  value       = aws_eks_cluster.main.version
}

output "cluster_platform_version" {
  description = "Platform version for the EKS cluster"
  value       = aws_eks_cluster.main.platform_version
}

output "cluster_status" {
  description = "Status of the EKS cluster. One of `CREATING`, `ACTIVE`, `DELETING`, `FAILED`"
  value       = aws_eks_cluster.main.status
}

# Certificate Authority
output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

# VPC Configuration
output "cluster_vpc_id" {
  description = "ID of the VPC associated with the cluster"
  value       = aws_eks_cluster.main.vpc_config[0].vpc_id
}

output "cluster_security_group_id" {
  description = "Cluster security group that was created by Amazon EKS for the cluster"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

# OIDC
output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider if enabled"
  value       = try(aws_iam_openid_connect_provider.oidc[0].arn, null)
}

# IAM Roles
output "cluster_iam_role_name" {
  description = "IAM role name associated with EKS cluster"
  value       = aws_iam_role.cluster.name
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN associated with EKS cluster"
  value       = aws_iam_role.cluster.arn
}

output "node_group_iam_role_name" {
  description = "IAM role name associated with EKS node group"
  value       = var.create_node_group ? aws_iam_role.node[0].name : null
}

output "node_group_iam_role_arn" {
  description = "IAM role ARN associated with EKS node group"
  value       = var.create_node_group ? aws_iam_role.node[0].arn : null
}

# Node Group information
output "node_group_arn" {
  description = "Amazon Resource Name (ARN) of the EKS Node Group"
  value       = var.create_node_group ? aws_eks_node_group.main[0].arn : null
}

output "node_group_id" {
  description = "EKS cluster name and EKS node group name separated by a colon (:)"
  value       = var.create_node_group ? aws_eks_node_group.main[0].id : null
}

output "node_group_status" {
  description = "Status of the EKS Node Group"
  value       = var.create_node_group ? aws_eks_node_group.main[0].status : null
}

output "node_group_capacity_type" {
  description = "Type of capacity associated with the EKS Node Group"
  value       = var.create_node_group ? aws_eks_node_group.main[0].capacity_type : null
}

output "node_group_instance_types" {
  description = "List of instance types associated with EKS Node Group"
  value       = var.create_node_group ? aws_eks_node_group.main[0].instance_types : null
}

output "node_group_ami_type" {
  description = "Type of Amazon Machine Image (AMI) associated with the EKS Node Group"
  value       = var.create_node_group ? aws_eks_node_group.main[0].ami_type : null
}

# Security
output "cluster_encryption_config" {
  description = "Cluster encryption configuration"
  value       = aws_eks_cluster.main.encryption_config
}

output "kms_key_arn" {
  description = "The Amazon Resource Name (ARN) of the KMS key"
  value       = var.enable_encryption ? aws_kms_key.eks[0].arn : null
}

output "kms_key_id" {
  description = "The globally unique identifier for the KMS key"
  value       = var.enable_encryption ? aws_kms_key.eks[0].key_id : null
}

# Add-ons
output "cluster_addons" {
  description = "Map of attribute maps for all EKS cluster addons enabled"
  value       = aws_eks_addon.addons
}

# OIDC Provider (for service accounts)
resource "aws_iam_openid_connect_provider" "oidc" {
  count = var.enable_irsa ? 1 : 0

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster[0].certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = merge(
    var.common_tags,
    {
      Name = "${var.cluster_name}-eks-irsa"
    }
  )
}

# Data source to get the certificate for OIDC
data "tls_certificate" "cluster" {
  count = var.enable_irsa ? 1 : 0
  url   = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# Additional variable for IRSA
variable "enable_irsa" {
  description = "Whether to create an OpenID Connect Provider for EKS to enable IRSA"
  type        = bool
  default     = true
}

# Kubeconfig
output "kubeconfig" {
  description = "kubectl config as generated by the module"
  value = {
    apiVersion      = "v1"
    kind            = "Config"
    current-context = "terraform"
    contexts = [{
      name = "terraform"
      context = {
        cluster = "terraform"
        user    = "terraform"
      }
    }]
    clusters = [{
      name = "terraform"
      cluster = {
        certificate-authority-data = aws_eks_cluster.main.certificate_authority[0].data
        server                     = aws_eks_cluster.main.endpoint
      }
    }]
    users = [{
      name = "terraform"
      user = {
        exec = {
          apiVersion = "client.authentication.k8s.io/v1beta1"
          command    = "aws"
          args = [
            "eks",
            "get-token",
            "--cluster-name",
            aws_eks_cluster.main.name,
          ]
        }
      }
    }]
  }
}