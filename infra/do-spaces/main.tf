resource "digitalocean_spaces_bucket" "backups" {
  name   = var.space_name
  region = var.region

  acl    = "private"
}

resource "digitalocean_spaces_bucket_cors_configuration" "example" {
  bucket = digitalocean_spaces_bucket.backups.name
  region = "nyc3"

  cors_rule {
    allowed_methods = ["GET", "PUT", "POST", "HEAD", "DELETE"]
    allowed_origins = ["*"]
    allowed_headers = ["*"]
    max_age_seconds = 3000
  }
}
