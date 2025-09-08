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
  default     = "nyc3"
  description = "Spaces region (e.g. nyc3, sgp1)"
}
