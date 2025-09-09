space_name  = "alaris-takehome-karthik"
region      = "nyc3"
tenants = {
  tenant-a = {
    name         = "tenant-a"
    storage_size = 10
  }
  tenant-b = {
    name         = "tenant-b" 
    storage_size = 10
  }
}
project_name            = "alaris-takehome-task"
cluster_name            = "alaris-takehome-cluster"
cluster_version         = "latest"
node_size               = "s-1vcpu-2gb"
node_pool_name          = "default-pool"
node_count              = 2
subscription_tier_slug  = "basic"
acl                     = "private"
