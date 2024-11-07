variable "bucket_name" {
  description = "Nombre del bucket S3"
  type        = string
}

variable "lambda_function_name" {
  description = "Nombre de la función Lambda"
  type        = string
}

variable "lambda_runtime" {
  description = "Runtime de la función Lambda"
  type        = string
}

variable "lambda_handler" {
  description = "Handler de la función Lambda"
  type        = string
}

variable "lambda_zip_file" {
  description = "Ruta al archivo ZIP de Lambda"
  type        = string
}

variable "authorized_user_arn" {
  description = "ARN del usuario autorizado para subir archivos"
  type        = string
}
