# modules/api_gateway/variables.tf

variable "api_name" {
  type        = string
  description = "Name of the API Gateway"
}

variable "lambda_arn" {
  type        = string
  description = "ARN of the Lambda function"
}

variable "lambda_function_name" {
  type        = string
  description = "Name of the Lambda function"
}

variable "environment" {
  type        = string
  description = "Environment name (e.g., prod, dev)"
  default     = "prod"
}