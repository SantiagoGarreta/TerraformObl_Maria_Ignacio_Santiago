output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.postgresql.endpoint
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.postgresql.port
}

output "rds_database_name" {
  description = "RDS database name"
  value       = aws_db_instance.postgresql.db_name
}

output "rds_security_group_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds_sg.id
}