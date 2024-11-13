resource "aws_s3_bucket" "user_files" {
  bucket = var.bucket_name_primary
}

resource "aws_s3_bucket_versioning" "primary_versioning" {
  bucket = aws_s3_bucket.user_files.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_replication_configuration" "primary_replication" {
  depends_on = [aws_iam_role.replication_role]
  bucket     = aws_s3_bucket.user_files.id
  role       = aws_iam_role.replication_role.arn

  rule {
    id     = "Replicate-to-secondary-region"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.user_files_secondary.arn
      storage_class = "STANDARD"
    }
  }
}


resource "aws_s3_bucket" "user_files_secondary" {
  provider = aws.secondary
  bucket   = var.bucket_name_secondary
}

resource "aws_s3_bucket_versioning" "secondary_versioning" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.user_files_secondary.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "secondary_bucket_policy" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.user_files_secondary.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/s3-replication-role"
        },
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags",
          "s3:GetObjectVersionForReplication",
          "s3:ObjectOwnerOverrideToBucketOwner"
        ],
        Resource = "arn:aws:s3:::${aws_s3_bucket.user_files_secondary.id}/*"
      }
    ]
  })
}

resource "aws_iam_role" "replication_role" {
  name = "s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "s3.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "replication_policy" {
  role = aws_iam_role.replication_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags",
          "s3:GetObjectVersionTagging",
          "s3:GetObjectVersionForReplication"
        ],
        Resource = [
          "${aws_s3_bucket.user_files.arn}/*",
          "${aws_s3_bucket.user_files_secondary.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
          "s3:GetBucketVersioning",
          "s3:PutBucketVersioning",
          "s3:GetReplicationConfiguration",
          "s3:ReplicateObject"
        ],
        Resource = [
          aws_s3_bucket.user_files.arn,
          aws_s3_bucket.user_files_secondary.arn
        ]
      }
    ]
  })
}


data "aws_caller_identity" "current" {}