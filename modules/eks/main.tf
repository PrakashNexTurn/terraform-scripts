# EKS Cluster Module
# This module creates an EKS cluster with node groups and necessary IAM roles

# Data source for current AWS region
data "aws_region" "current" {}

# Data source for current AWS caller identity
data "aws_caller_identity" "current" {}

# Data source for EKS service account
data "aws_iam_policy_document" "eks_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

# Data source for node group service account
data "aws_iam_policy_document" "node_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Local values for computed configurations
locals {
  # Use node_group_subnet_ids if provided and not empty, otherwise fall back to cluster subnet_ids
  effective_node_group_subnet_ids = length(var.node_group_subnet_ids) > 0 ? var.node_group_subnet_ids : var.subnet_ids
}

# KMS key for EKS cluster encryption
resource "aws_kms_key" "eks" {
  count                   = var.enable_encryption ? 1 : 0
  description             = "EKS Secret Encryption Key for ${var.cluster_name}"
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.cluster_name}-eks-encryption-key"
    }
  )
}

# KMS key alias
resource "aws_kms_alias" "eks" {
  count         = var.enable_encryption ? 1 : 0
  name          = "alias/${var.cluster_name}-eks-encryption-key"
  target_key_id = aws_kms_key.eks[0].key_id
}

# IAM role for EKS cluster
resource "aws_iam_role" "cluster" {
  name               = "${var.cluster_name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role_policy.json

  tags = merge(
    var.common_tags,
    {
      Name = "${var.cluster_name}-cluster-role"
    }
  )
}

# Attach required policies to cluster role
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

# IAM role for EKS node group
resource "aws_iam_role" "node" {
  count              = var.create_node_group ? 1 : 0
  name               = "${var.cluster_name}-node-role"
  assume_role_policy = data.aws_iam_policy_document.node_assume_role_policy.json

  tags = merge(
    var.common_tags,
    {
      Name = "${var.cluster_name}-node-role"
    }
  )
}

# Attach required policies to node role
resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  count      = var.create_node_group ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node[0].name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  count      = var.create_node_group ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node[0].name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  count      = var.create_node_group ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node[0].name
}

# Security group for additional EKS cluster rules
resource "aws_security_group" "cluster_additional" {
  count       = length(var.cluster_additional_security_group_ids) > 0 ? 0 : 1
  name_prefix = "${var.cluster_name}-cluster-additional-"
  vpc_id      = var.vpc_id
  description = "Additional security group for ${var.cluster_name} EKS cluster"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.cluster_name}-cluster-additional"
    }
  )
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.public_access_cidrs
    security_group_ids      = var.cluster_additional_security_group_ids
  }

  access_config {
    authentication_mode                         = var.authentication_mode
    bootstrap_cluster_creator_admin_permissions = var.bootstrap_cluster_creator_admin_permissions
  }

  # Encryption configuration
  dynamic "encryption_config" {
    for_each = var.enable_encryption ? [1] : []
    content {
      provider {
        key_arn = aws_kms_key.eks[0].arn
      }
      resources = ["secrets"]
    }
  }

  # Enable cluster logging
  enabled_cluster_log_types = var.cluster_log_types

  # Ensure IAM roles are created first
  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
  ]

  tags = merge(
    var.common_tags,
    {
      Name = var.cluster_name
    }
  )
}

# EKS Node Group
resource "aws_eks_node_group" "main" {
  count           = var.create_node_group ? 1 : 0
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.node[0].arn
  subnet_ids      = local.effective_node_group_subnet_ids

  # Instance configuration
  capacity_type  = var.node_group_capacity_type
  instance_types = var.node_group_instance_types
  ami_type       = var.node_group_ami_type
  disk_size      = var.node_group_disk_size

  # Scaling configuration
  scaling_config {
    desired_size = var.node_group_desired_size
    max_size     = var.node_group_max_size
    min_size     = var.node_group_min_size
  }

  # Update configuration
  update_config {
    max_unavailable_percentage = var.node_group_max_unavailable_percentage
  }

  # Remote access configuration
  dynamic "remote_access" {
    for_each = var.node_group_remote_access_ec2_ssh_key != "" ? [1] : []
    content {
      ec2_ssh_key               = var.node_group_remote_access_ec2_ssh_key
      source_security_group_ids = var.node_group_remote_access_source_security_group_ids
    }
  }

  # Ensure IAM roles are created first
  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.cluster_name}-${var.node_group_name}"
    }
  )

  # Allow external changes without Terraform plan difference
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# EKS Add-ons
resource "aws_eks_addon" "addons" {
  for_each = var.cluster_addons

  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = each.key
  addon_version               = lookup(each.value, "version", null)
  resolve_conflicts_on_create = lookup(each.value, "resolve_conflicts", "OVERWRITE")
  resolve_conflicts_on_update = lookup(each.value, "resolve_conflicts", "OVERWRITE")
  service_account_role_arn    = lookup(each.value, "service_account_role_arn", null)

  tags = merge(
    var.common_tags,
    {
      Name = "${var.cluster_name}-${each.key}"
    }
  )

  depends_on = [
    aws_eks_node_group.main
  ]
}