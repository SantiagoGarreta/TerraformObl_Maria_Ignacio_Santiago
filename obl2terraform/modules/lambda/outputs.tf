output "lambda_arn" {
  description = "The ARN of the Lambda function"
  value       = aws_lambda_function.transaction_processor.arn
}

output "lambda_function_name" {
  description = "The name of the Lambda function"
  value       = aws_lambda_function.transaction_processor.function_name
}