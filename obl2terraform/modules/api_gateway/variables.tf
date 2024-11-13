variable "api_name" {
  type        = string
  description = "Name of the API Gateway"
}

variable "lambda_arn" {
  type        = string
  description = "ARN of the Lambda function to integrate with API Gateway"
}

variable "lambda_function_name" {
  type        = string
  description = "Name of the Lambda function"
}

variable "environment" {
  type        = string
  description = "Environment name for the API Gateway stage"
  default     = "prod"
}