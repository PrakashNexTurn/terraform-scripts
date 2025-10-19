# EKS Cluster Variables

# Required variables
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  
  validation {
    condition     = can(regex("^[0-9A-Za-z][A-Za-z0-9\\-_]*$", var.cluster_name))
    error_message = "Cluster name must be between 1-100 characters in length. Must begin with an alphanumeric character, and must only contain alphanumeric characters, dashes and underscores."
  }
}

variable "vpc_id" {
  description = "ID of the VPC where the cluster will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster (must be in at least two different availability zones)"
  type        = list(string)
  
  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least two subnet IDs must be provided for high availability."
  }
}

# Optional variables with defaults
variable "kubernetes_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.33"
}

variable "endpoint_private_access" {
  description = "Whether the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Whether the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks that can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_additional_security_group_ids" {
  description = "List of additional security group IDs to attach to the EKS cluster"
  type        = list(string)
  default     = []
}

variable "authentication_mode" {
  description = "The authentication mode for the cluster"
  type        = string
  default     = "API_AND_CONFIG_MAP"
  
  validation {
    condition     = contains(["CONFIG_MAP", "API", "API_AND_CONFIG_MAP"], var.authentication_mode)
    error_message = "Authentication mode must be one of: CONFIG_MAP, API, or API_AND_CONFIG_MAP."
  }
}

variable "bootstrap_cluster_creator_admin_permissions" {
  description = "Whether to bootstrap the access config values to the cluster"
  type        = bool
  default     = true
}

# Encryption variables
variable "enable_encryption" {
  description = "Whether to enable EKS cluster encryption"
  type        = bool
  default     = true
}

variable "kms_key_deletion_window" {
  description = "The waiting period, specified in number of days, after which the KMS key is deleted"
  type        = number
  default     = 10
  
  validation {
    condition     = var.kms_key_deletion_window >= 7 && var.kms_key_deletion_window <= 30
    error_message = "KMS key deletion window must be between 7 and 30 days."
  }
}

# Logging variables
variable "cluster_log_types" {
  description = "List of the desired control plane logging to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  
  validation {
    condition = alltrue([
      for log_type in var.cluster_log_types : contains(["api", "audit", "authenticator", "controllerManager", "scheduler"], log_type)
    ])
    error_message = "Valid log types are: api, audit, authenticator, controllerManager, scheduler."
  }
}

# Node Group variables
variable "create_node_group" {
  description = "Whether to create a managed node group"
  type        = bool
  default     = true
}

variable "node_group_name" {
  description = "Name of the EKS node group"
  type        = string
  default     = "main-nodes"
}

variable "node_group_subnet_ids" {
  description = "List of subnet IDs for the node group (if not provided, uses cluster subnet_ids)"
  type        = list(string)
  default     = []
}

variable "node_group_capacity_type" {
  description = "Type of capacity associated with the EKS Node Group. Valid values: ON_DEMAND, SPOT"
  type        = string
  default     = "ON_DEMAND"
  
  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.node_group_capacity_type)
    error_message = "Node group capacity type must be either ON_DEMAND or SPOT."
  }
}

variable "node_group_instance_types" {
  description = "List of instance types associated with the EKS Node Group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_group_ami_type" {
  description = "Type of Amazon Machine Image (AMI) associated with the EKS Node Group"
  type        = string
  default     = "AL2_x86_64"
  
  validation {
    condition = contains([
      "AL2_x86_64", 
      "AL2_x86_64_GPU", 
      "AL2_ARM_64", 
      "CUSTOM", 
      "BOTTLEROCKET_ARM_64", 
      "BOTTLEROCKET_x86_64",
      "BOTTLEROCKET_ARM_64_NVIDIA",
      "BOTTLEROCKET_x86_64_NVIDIA"
    ], var.node_group_ami_type)
    error_message = "AMI type must be a valid EKS node group AMI type."
  }
}

variable "node_group_disk_size" {
  description = "Disk size in GiB for worker nodes"
  type        = number
  default     = 20
  
  validation {
    condition     = var.node_group_disk_size >= 1 && var.node_group_disk_size <= 16384
    error_message = "Node group disk size must be between 1 and 16384 GiB."
  }
}

# Node Group scaling variables
variable "node_group_desired_size" {
  description = "Desired number of nodes in the node group"
  type        = number
  default     = 2
}

variable "node_group_max_size" {
  description = "Maximum number of nodes in the node group"
  type        = number
  default     = 4
}

variable "node_group_min_size" {
  description = "Minimum number of nodes in the node group"
  type        = number
  default     = 1
}

variable "node_group_max_unavailable_percentage" {
  description = "Maximum percentage of nodes unavailable during update"
  type        = number
  default     = 25
  
  validation {
    condition     = var.node_group_max_unavailable_percentage >= 1 && var.node_group_max_unavailable_percentage <= 100
    error_message = "Maximum unavailable percentage must be between 1 and 100."
  }
}

# Node Group remote access variables
variable "node_group_remote_access_ec2_ssh_key" {
  description = "EC2 Key Pair name that provides access for SSH communication with the worker nodes"
  type        = string
  default     = ""
}

variable "node_group_remote_access_source_security_group_ids" {
  description = "List of security group IDs that are allowed SSH access to the worker nodes"
  type        = list(string)
  default     = []
}

# Add-ons variables
variable "cluster_addons" {
  description = "Map of cluster addon configurations to enable for the cluster"
  type = map(object({
    version                    = optional(string)
    resolve_conflicts          = optional(string)
    service_account_role_arn   = optional(string)
  }))
  default = {
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
}

# Tags
variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default = {
    Terraform = "true"
    Module    = "eks"
  }
}