variable "bucket_name" {}

resource "aws_s3_bucket" "infnet_website_bucket" {
  bucket = var.bucket_name
  
  
  tags = {
    Name = "infnet-aws-compute-project-website-bucket"
  }
}

resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.infnet_website_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.infnet_website_bucket.id
    
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = aws_s3_bucket.infnet_website_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}
resource "aws_s3_bucket_acl" "bucket_acl" {
  depends_on = [aws_s3_bucket_public_access_block.public_access]
    
  bucket = aws_s3_bucket.infnet_website_bucket.id
  acl    = "public-read"
}

resource "aws_s3_object" "index_html" {
  bucket = aws_s3_bucket.infnet_website_bucket.id
  key    = "index.html"
  source = "./template/index.html"
  content_type = "text/html"
  acl    = "public-read"
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.infnet_website_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}