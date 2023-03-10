data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = [
        "transfer.amazonaws.com",
        "ec2.amazonaws.com"
      ]
      type = "Service"
    }
  }
}

resource "aws_iam_role" "bucket_role" {
  name               = "${var.environment}-${var.ecosystem}-sftp-s3-bucket-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "bucket_policy_document" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:GetObject",
      "s3:DeleteObjectVersion",
      "s3:DeleteObject",
      "s3:GetObjectVersion",
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [
      "${data.aws_s3_bucket.bucket.arn}/*",
      data.aws_s3_bucket.bucket.arn
    ]
  }
}

resource "aws_iam_policy" "bucket_policy" {
  policy = data.aws_iam_policy_document.bucket_policy_document.json
  name   = "${var.environment}-${var.ecosystem}-sftp-s3-bucket-policy"
}

resource "aws_iam_role_policy_attachment" "bucket_attach" {
  policy_arn = aws_iam_policy.bucket_policy.arn
  role       = aws_iam_role.bucket_role.name
}

data "aws_iam_policy_document" "logs_role_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:CreateLogGroup",
      "logs:PutLogEvents"
    ]
    resources = [
      format("arn:aws:logs:%s:%s:*", data.aws_region.current.name, data.aws_caller_identity.current.account_id)
    ]
  }
}

resource "aws_iam_role" "logs_role" {
  name               = "${var.environment}-${var.ecosystem}-sftp-cloudwatch-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_policy" "logs_role_policy" {
  name   = "${var.environment}-${var.ecosystem}-sftp-cloudwatch-policy"
  policy = data.aws_iam_policy_document.logs_role_policy.json
}

resource "aws_iam_role_policy_attachment" "logs_attach" {
  policy_arn = aws_iam_policy.logs_role_policy.arn
  role       = aws_iam_role.logs_role.name
}

# --------- user --------------------------

resource "aws_iam_role" "user_role" {
  name               = "${var.environment}-${var.ecosystem}-sftp-user-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "user_policy_create" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",      
      "s3:PutObjectAcl"
    ]
    resources = [
      "${data.aws_s3_bucket.bucket.arn}/*",
      data.aws_s3_bucket.bucket.arn.arn
    ]
  }
}
resource "aws_iam_policy" "users_policy" {
  policy = data.aws_iam_policy_document.user_policy_create.json
  name   = "${var.environment}-${var.ecosystem}-sftp-users-policy"
}

resource "aws_iam_role_policy_attachment" "users_attach" {
  policy_arn = aws_iam_policy.users_policy.arn
  role       = aws_iam_role.user_role.name
}
