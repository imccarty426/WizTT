resource "aws_s3_bucket" "mongodb_backup" {
  bucket = "mongodb_backup"  
  acl    = "public-read"

  block_public_acls       = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}