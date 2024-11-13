# modules/api_gateway/outputs.tf

output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = "${aws_api_gateway_stage.stage.invoke_url}/transacciones"  # Changed from api_stage to stage
}

output "rest_api_id" {
  description = "ID of the REST API"
  value       = aws_api_gateway_rest_api.api.id  # Changed from transaction_api to api
}