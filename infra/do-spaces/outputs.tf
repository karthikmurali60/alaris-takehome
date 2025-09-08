output "bucket_name" {
  value = digitalocean_spaces_bucket.backups.name
}

output "region" {
  value = digitalocean_spaces_bucket.backups.region
}

output "endpoint" {
  value = "https://${digitalocean_spaces_bucket.backups.region}.digitaloceanspaces.com"
}
