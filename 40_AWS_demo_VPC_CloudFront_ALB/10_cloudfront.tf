resource "aws_cloudfront_distribution" "demo40" {
  origin {
    domain_name = aws_lb.demo40_alb.dns_name
    origin_id   = "ALBOrigin"

    # add custom header expected by ALB
    custom_header {
      name  = "X-Origin-Verify"
      value = local.demo40_secret
    }

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Demo40 CloudFront Distribution with ALB"
  default_root_object = "index.php"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "ALBOrigin"

    forwarded_values {
      query_string = true
      headers      = ["Host", "Origin"]

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
      # restriction_type = "whitelist"
      # locations        = ["US", "CA", "GB", "DE", "FR"]
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.demo40_cloudfront_logs.bucket_regional_domain_name
    prefix          = "cloudfront-logs/"
  }
}

# ------ S3 bucket for CloudFront logs
resource "aws_s3_bucket" "demo40_cloudfront_logs" {
  bucket_prefix = "cpa-cloudfront-logs-bucket"
}

resource "aws_s3_bucket_ownership_controls" "demo40_cloudfront_logs" {
  bucket = aws_s3_bucket.demo40_cloudfront_logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "demo40_cloudfront_logs" {
  depends_on = [aws_s3_bucket_ownership_controls.demo40_cloudfront_logs]

  bucket = aws_s3_bucket.demo40_cloudfront_logs.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "demo40_cloudfront_logs" {
  bucket = aws_s3_bucket.demo40_cloudfront_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------ S3 bucket policy to allow CloudFront to write logs
data "aws_iam_policy_document" "demo40_cloudfront_logs" {
  statement {
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.demo40_cloudfront_logs.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudfront_distribution.demo40.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "demo40_cloudfront_logs" {
  bucket = aws_s3_bucket.demo40_cloudfront_logs.id
  policy = data.aws_iam_policy_document.demo40_cloudfront_logs.json
}
