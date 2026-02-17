# -------------------------------------------
# Docker Image Tag Variable
# This will be passed from GitHub Actions
# Example: aabd94f207acf8d27edda81b6e07c81b4ded29e5
# -------------------------------------------
variable "image_tag" {
  description = "Docker image tag"
  type        = string
}
