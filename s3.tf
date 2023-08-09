resource "aws_s3_bucket" "mongodb_backup" {
  bucket = "mongodb_backup"  
  acl    = "public-read"
}