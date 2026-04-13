data aws_caller_identity current {}

# -- S3 bucket to store canary artifacts
resource aws_s3_bucket demo33_canary {
  bucket        = "demo33-canary-artifacts-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

resource aws_s3_bucket_public_access_block demo33_canary {
  bucket                  = aws_s3_bucket.demo33_canary.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -- IAM role for the canary
data aws_iam_policy_document demo33_canary_assume {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data aws_iam_policy_document demo33_canary {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetBucketLocation",
    ]
    resources = [
      aws_s3_bucket.demo33_canary.arn,
      "${aws_s3_bucket.demo33_canary.arn}/*",
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"
      values   = ["CloudWatchSynthetics"]
    }
  }
}

resource aws_iam_role demo33_canary {
  name               = "demo33_iam_for_canary"
  assume_role_policy = data.aws_iam_policy_document.demo33_canary_assume.json
}

resource aws_iam_role_policy demo33_canary {
  name   = "demo33_canary_policy"
  role   = aws_iam_role.demo33_canary.id
  policy = data.aws_iam_policy_document.demo33_canary.json
}

# -- Canary script (inline via local file)
resource aws_synthetics_canary demo33_api {
  name                 = "demo33-api-check"
  artifact_s3_location = "s3://${aws_s3_bucket.demo33_canary.bucket}/canary/"
  execution_role_arn   = aws_iam_role.demo33_canary.arn
  handler              = "apicheck.handler"
  runtime_version      = "syn-nodejs-puppeteer-9.1"
  start_canary         = true

  schedule {
    expression = "rate(1 minute)"
  }

  artifact_config {
    s3_encryption {
      encryption_mode = "SSE_S3"
    }
  }

  zip_file = data.archive_file.demo33_canary.output_path
}

data archive_file demo33_canary {
  type        = "zip"
  output_path = "${path.module}/canary_payload.zip"

  source {
    content  = <<-JS
      const synthetics = require('Synthetics');
      const log = require('SyntheticsLogger');
      const https = require('https');

      const handler = async () => {
        const url = '${aws_api_gateway_stage.demo33_stage1.invoke_url}/${var.apigw_path1}';
        log.info('Checking URL: ' + url);

        await synthetics.executeStep('Check API alive', async () => {
          await new Promise((resolve, reject) => {
            https.get(url, (res) => {
              log.info('Status: ' + res.statusCode);
              if (res.statusCode !== 200) {
                reject(new Error('Expected 200 but got ' + res.statusCode));
              } else {
                res.resume();
                resolve();
              }
            }).on('error', reject);
          });
        });
      };

      module.exports = { handler };
    JS
    filename = "nodejs/node_modules/apicheck.js"
  }
}

output canary_console_url {
  value = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#synthetics:canary/detail/demo33-api-check"
}
