variable "lambda_function_name" {
  type        = string
  description = "Name of the Lambda function"
}

variable "environment" {
  type        = string
  description = "Environment for the Lambda function"
  default     = "prod"
}