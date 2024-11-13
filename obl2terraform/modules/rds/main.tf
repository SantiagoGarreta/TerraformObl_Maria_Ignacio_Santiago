# modules/rds/main.tf

resource "aws_security_group" "rds_sg" {
  name        = "${var.environment}-rds-security-group"
  description = "Security group for RDS PostgreSQL instance"
  vpc_id      = var.vpc_id

  # Allow PostgreSQL access from anywhere (for development only!)
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # In production, restrict this to your IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-rds-security-group"
    Environment = var.environment
  }
}

# Create a subnet group for RDS
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.environment}-rds-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name        = "${var.environment}-rds-subnet-group"
    Environment = var.environment
  }
}


resource "aws_db_instance" "postgresql" {
  identifier = "${var.environment}-banking-db"

  engine               = "postgres"
  engine_version       = "15.4"  # Updated directly here
  instance_class       = var.instance_class
  allocated_storage    = var.allocated_storage
  storage_encrypted    = true

  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
vpc_security_group_ids = [aws_security_group.rds_sg.id]
publicly_accessible    = true  # Make it publicly accessible
  skip_final_snapshot    = true
  port                  = 5432

  db_name  = var.database_name
  username = var.database_username
  password = var.database_password

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "Mon:04:00-Mon:05:00"


  tags = {
    Name        = "${var.environment}-banking-db"
    Environment = var.environment
  }
}

locals {
  schema_sql = <<-EOF
    CREATE TABLE IF NOT EXISTS transactions (
        id SERIAL PRIMARY KEY,
        transaction_id VARCHAR(100) UNIQUE NOT NULL,
        sender_bank_code VARCHAR(50) NOT NULL,
        sender_account_number VARCHAR(50) NOT NULL,
        receiver_account_number VARCHAR(50) NOT NULL,
        amount DECIMAL(15,2) NOT NULL,
        currency VARCHAR(3) NOT NULL,
        transaction_date TIMESTAMP NOT NULL,
        description TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE INDEX IF NOT EXISTS idx_transaction_id ON transactions(transaction_id);
    CREATE INDEX IF NOT EXISTS idx_transaction_date ON transactions(transaction_date);
    CREATE INDEX IF NOT EXISTS idx_sender_bank_code ON transactions(sender_bank_code);
  EOF
}

# Create a temporary file containing the schema
resource "local_file" "schema" {
  content  = local.schema_sql
  filename = "${path.module}/schema.sql"
}

resource "null_resource" "db_verify" {
  triggers = {
    instance_id = aws_db_instance.postgresql.id
  }

  provisioner "local-exec" {
    command = <<-EOF
      echo "Waiting for database to be ready..."
      for i in {1..30}; do
        if PGPASSWORD='${var.database_password}' psql \
          -h ${split(":", aws_db_instance.postgresql.endpoint)[0]} \
          -p ${aws_db_instance.postgresql.port} \
          -U ${var.database_username} \
          -d ${var.database_name} \
          -c '\l' >/dev/null 2>&1; then
          echo "Database is ready!"
          exit 0
        fi
        echo "Attempt $i: Database not ready yet..."
        sleep 10
      done
      echo "Database connection timeout"
      exit 1
    EOF
  }

  depends_on = [aws_db_instance.postgresql]
}

resource "null_resource" "schema_exec" {
  triggers = {
    schema_hash = sha256(local.schema_sql)
    instance_id = aws_db_instance.postgresql.id
  }

  provisioner "local-exec" {
    command = <<-EOF
      PGPASSWORD='${var.database_password}' psql \
      -h ${split(":", aws_db_instance.postgresql.endpoint)[0]} \
      -p ${aws_db_instance.postgresql.port} \
      -U ${var.database_username} \
      -d ${var.database_name} \
      -f ${local_file.schema.filename}
    EOF
  }

  depends_on = [
    aws_db_instance.postgresql,
    local_file.schema,
    null_resource.db_verify
  ]
}
