# -------------------------------------------
# Docker Image Tag (Passed from GitHub Actions)
# -------------------------------------------
variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
}
