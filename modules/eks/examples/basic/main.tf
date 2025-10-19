# Basic EKS Cluster Example
# This example shows how to create a basic EKS cluster with managed node groups

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data sources for existing VPC and subnets
data "aws_vpc" "main" {
  id = var.vpc_id
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  tags = {
    Type = "Private"
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  tags = {
    Type = "Public"
  }
}

# EKS Cluster
module "eks" {
  source = "../../"

  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  vpc_id            = var.vpc_id
  subnet_ids        = data.aws_subnets.private.ids

  # Network configuration
  endpoint_private_access = true
  endpoint_public_access  = true
  public_access_cidrs    = var.allowed_cidr_blocks

  # Security
  enable_encryption   = true
  authentication_mode = "API_AND_CONFIG_MAP"

  # Node group configuration
  create_node_group               = true
  node_group_name                = "main-nodes"
  node_group_subnet_ids          = data.aws_subnets.private.ids
  node_group_instance_types      = var.node_instance_types
  node_group_capacity_type       = var.node_capacity_type
  node_group_desired_size        = var.node_desired_size
  node_group_max_size           = var.node_max_size
  node_group_min_size           = var.node_min_size
  node_group_disk_size          = var.node_disk_size

  # Add-ons with specific versions for Kubernetes 1.33
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
  }

  # Logging
  cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    Terraform   = "true"
    Example     = "basic"
  }
}

# Optional: Create an IRSA role for AWS Load Balancer Controller
module "aws_load_balancer_controller_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "${var.cluster_name}-aws-load-balancer-controller"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Security group rule for node group to allow communication with load balancers
resource "aws_security_group_rule" "node_group_ingress_self" {
  description       = "Allow nodes to communicate with each other"
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = [data.aws_vpc.main.cidr_block]
  security_group_id = module.eks.cluster_security_group_id
}