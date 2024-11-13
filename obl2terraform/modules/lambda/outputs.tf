output "invoke_arn" {
  description = "ARN for invoking the Lambda Function"
  value       = aws_lambda_function.transaction_processor.invoke_arn
}

output "function_name" {
  description = "Name of the Lambda Function"
  value       = aws_lambda_function.transaction_processor.function_name
}

output "function_arn" {
  description = "ARN of the Lambda Function"
  value       = aws_lambda_function.transaction_processor.arn
}