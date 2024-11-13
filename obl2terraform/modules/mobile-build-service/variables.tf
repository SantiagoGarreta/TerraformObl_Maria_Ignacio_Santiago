variable "github_owner" {
  description = "Nombre del propietario del repositorio de GitHub"
  type        = string
}

variable "github_repo" {
  description = "Nombre del repositorio en GitHub"
  type        = string
}

variable "github_branch" {
  description = "Nombre de la rama para el pipeline"
  type        = string
  default     = "main"
}

variable "github_token" {
  description = "Token de OAuth para GitHub"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "ecr_repository_name" {
  description = "Nombre del repositorio de ECR"
  type        = string
  default     = "my-app-repo"
}