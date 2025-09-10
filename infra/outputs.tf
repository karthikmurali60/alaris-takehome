output "bucket_name" {
  value = digitalocean_spaces_bucket.backups.name
}

output "region" {
  value = digitalocean_spaces_bucket.backups.region
}

output "endpoint" {
  value = "https://${digitalocean_spaces_bucket.backups.region}.digitaloceanspaces.com"
}

output "registry_endpoint" {
  description = "Container registry endpoint"
  value       = digitalocean_container_registry.main.endpoint
}

output "registry_name" {
  description = "Container registry name"
  value       = digitalocean_container_registry.main.name
}

output "docker_credentials" {
  description = "Docker credentials for registry access"
  value       = digitalocean_container_registry_docker_credentials.main.docker_credentials
  sensitive   = true
}
