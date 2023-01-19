resource aws_s3_bucket demo05 {
  bucket = "demo05-bucket"
  tags  = { Name = "demo05" }
}

resource aws_s3_bucket_acl demo05 {
  bucket = aws_s3_bucket.demo05.id
  acl    = "private"
}