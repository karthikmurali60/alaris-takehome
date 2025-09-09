data "digitalocean_project" "alaris_project" {
  name = var.project_name
}

resource "digitalocean_kubernetes_cluster" "alaris_cluster" {
  name = var.cluster_name
  region  = var.region
  version = var.cluster_version

  node_pool {
    name       = var.node_pool_name
    size       = var.node_size
    node_count = var.node_count
  }
}

resource "digitalocean_spaces_bucket" "backups" {
  name   = var.space_name
  region = var.region

  acl    = var.acl
}

resource "digitalocean_spaces_bucket_cors_configuration" "example" {
  bucket = digitalocean_spaces_bucket.backups.name
  region = var.region

  cors_rule {
    allowed_methods = ["GET", "PUT", "POST", "HEAD", "DELETE"]
    allowed_origins = ["*"]
    allowed_headers = ["*"]
    max_age_seconds = 3000
  }
}

resource "digitalocean_volume" "tenant_volumes" {
  for_each = var.tenants

  name                    = "pg-${each.value.name}-volume"
  region                  = var.region
  size                    = each.value.storage_size
  initial_filesystem_type = "ext4"
  description             = "PostgreSQL storage for ${each.value.name}"
}

resource "digitalocean_container_registry" "main" {
  name                   = "${data.digitalocean_project.alaris_project.name}-registry"
  subscription_tier_slug = var.subscription_tier_slug
  region                 = var.region
}

resource "digitalocean_container_registry_docker_credentials" "main" {
  registry_name = digitalocean_container_registry.main.name
}

resource "digitalocean_project_resources" "alaris_project_resources" {
  project = data.digitalocean_project.alaris_project.id

  resources = concat(
    [for volume in digitalocean_volume.tenant_volumes : volume.urn],
    [digitalocean_spaces_bucket.backups.urn],
    [digitalocean_kubernetes_cluster.alaris_cluster.urn],
    [digitalocean_container_registry.main.urn]
  )
}
