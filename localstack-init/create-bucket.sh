#!/bin/sh
# Runs automatically once LocalStack is ready (mounted at
# /etc/localstack/init/ready.d). Idempotent — safe to re-run on every start.
set -e

BUCKET="${S3_BUCKET_NAME:-delite-hr-local}"

if awslocal s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  echo "S3 bucket '$BUCKET' already exists."
else
  awslocal s3 mb "s3://$BUCKET"
  echo "Created S3 bucket '$BUCKET'."
fi
