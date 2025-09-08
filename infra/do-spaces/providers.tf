terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.66.0"
    }
  }
  required_version = ">= 1.4.0"
}

provider "digitalocean" {
  token = var.do_token
}
