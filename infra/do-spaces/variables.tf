variable "do_token" {
  type        = string
  sensitive   = true
  description = "DigitalOcean API token"
}

variable "space_name" {
  type        = string
  description = "Name of the DO Spaces bucket"
}

variable "region" {
  type        = string
  description = "Spaces region (e.g. nyc3, sgp1)"
}

variable "tenants" {
  description = "List of tenant configurations"
  type = map(object({
    name         = string
    storage_size = number
  }))
  default = {
    tenant-a = {
      name         = "tenant-a"
      storage_size = 20
    }
    tenant-b = {
      name         = "tenant-b"
      storage_size = 20
    }
  }
}

variable "project_name" {
  type        = string
  description = "Name of the DigitalOcean Project"
}

variable "cluster_name" {
  type        = string
  description = "Name of the Kubernetes Cluster"
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes version for the cluster"
}

variable "node_pool_name" {
  type        = string
  description = "Name of the default node pool"
}

variable "node_size" {
  type        = string
  description = "Size of the nodes in the default pool"
}

variable "node_count" {
  type        = number
  description = "Number of nodes in the default pool"
}

variable "acl" {
  type        = string
  description = "Access control list for the Spaces bucket"
}

variable "subscription_tier_slug" {
  type        = string
  description = "Subscription tier for the Container Registry"
}
