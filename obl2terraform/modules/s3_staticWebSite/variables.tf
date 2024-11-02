variable "bucket_name" {
  description = "Bucket S3 para el sitio web estático"
  type        = string
}

variable "tags" {
  description = "Bucket S3 para el sitio web estático"
  type        = map(string)
  default     = {
    Environment = "Dev"
    Project     = "Static Website"
  }
}
