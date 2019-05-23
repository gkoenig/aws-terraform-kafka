#################################################
# S3 Bucket for Kafka Connect S3 Sink
#################################################
resource "aws_s3_bucket" "kafka_s3_bucket" {
    count = "${var.s3sink ? 1 : 0}"
    bucket = "kafka-s3-sink.${var.env}.${var.domain}"
    acl = "private"
    versioning {
            enabled = true
    }
    tags {
        Name = "kafka-s3-sink.${var.env}.${var.domain}"
    }
}

#---------------------------------------------------------
# Create Policy for the S3 Bucket
#---------------------------------------------------------
resource "aws_s3_bucket_policy" "bucket_policy" {
  count = "${var.s3sink ? 1 : 0}"
  bucket = "${aws_s3_bucket.kafka_s3_bucket.id}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "DenyUnEncryptedObjectUploads",
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::kafka-s3-sink.${var.env}.${var.domain}/*",
            "Condition": {
                "Null": {
                    "s3:x-amz-server-side-encryption": "true"
                }
            }
        },
        {
            "Sid": "DenyIncorrectEncryptionHeader",
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::kafka-s3-sink.${var.env}.${var.domain}/*",
            "Condition": {
                "StringNotEquals": {
                    "s3:x-amz-server-side-encryption": [
                        "AES256",
                        "aws:kms"
                    ]
                }
            }
        }
    ]
}
EOF
}
#---------------------------------------------------------
# Create an IAM role for the Kafka Nodes 
#---------------------------------------------------------

resource "aws_iam_role" "kafka" {
  name               = "${var.env}-${var.domain}"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
EOF
}

resource "aws_iam_policy" "kafka" {
  name        = "${var.env}"
  description = "Policy for ${var.env}-${var.domain}"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": ["s3:ListBucket"],
        "Resource": [
            "arn:aws:s3:::kafka-s3-sink.${var.env}.${var.domain}",
            "arn:aws:s3:::terraform.${var.domain}"
        ]
      },
      {
        "Effect": "Allow",
        "Action": [
            "s3:PutObject",
            "s3:GetObject"
        ],
        "Resource": [
          "arn:aws:s3:::kafka-s3-sink.${var.env}.${var.domain}/*",
          "arn:aws:s3:::terraform.${var.domain}/*"
        ]
      }
    ]
  }
EOF
}

resource "aws_iam_policy_attachment" "test-attach" {
  name       = "${var.env}-kafka"
  roles      = ["${aws_iam_role.kafka.name}"]
  policy_arn = "${aws_iam_policy.kafka.arn}"
}

resource "aws_iam_instance_profile" "kafka" {
  name  = "${var.env}-kafka"
  role = "${aws_iam_role.kafka.name}"
}
