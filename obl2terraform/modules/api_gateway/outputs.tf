output "api_endpoint" {
  description = "API Gateway invocation URL"
  value       = "${aws_api_gateway_stage.api_stage.invoke_url}/transacciones"
}

output "execution_arn" {
  description = "API Gateway execution ARN"
  value       = aws_api_gateway_rest_api.api.execution_arn
}

output "rest_api_id" {
  description = "ID of the REST API"
  value       = aws_api_gateway_rest_api.api.id
}