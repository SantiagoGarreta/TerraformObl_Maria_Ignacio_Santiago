# modules/api_gateway/variables.tf

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "lambda_invoke_arn" {
  description = "ARN for invoking the Lambda function"
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "lambda_arn" {
  description = "ARN of the Lambda function"
  type        = string
}

variable "api_name" {
  description = "Name of the API"
  type        = string
  default     = "transaction_api"
}