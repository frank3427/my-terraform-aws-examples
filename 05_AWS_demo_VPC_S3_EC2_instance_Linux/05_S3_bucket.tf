resource aws_s3_bucket demo05 {
  bucket = var.s3_bucket_name
  tags  = { Name = "demo05" }
}

# ------ Create an S3 bucket policyt to allow access to the S2 bucket only thru S3 gateway endpoint 
#        (blocks access from Internet)
resource aws_s3_bucket_policy demo05 {
  bucket = aws_s3_bucket.demo05.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "${aws_s3_bucket.demo05.arn}",
        "${aws_s3_bucket.demo05.arn}/*"
      ],
      "Condition": {
        "StringNotEquals": {
          "aws:sourceVpce": "${aws_vpc_endpoint.demo05_s3_gateway.id}"
        }
      }
    }
  ]
}
POLICY
}

#        "s3:ListBucket",
