{
    "Version": "2012-10-17",
    "Statement": [
%{ for account in split(",", accounts) }
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:ListBucket",
                "s3:GetObject",
                "s3:DeleteObject"
            ],
            "Resource": [
                "${monitoring_bucket_arn}/*",
                "${monitoring_bucket_arn}"
            ],
            "Principal": {"AWS": "${account}"}
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetBucketLocation"
            ],
            "Resource": [
                "${monitoring_bucket_arn}"
            ],
            "Principal": {"AWS": "${account}"}
        },
%{ endfor }
        {
            "Sid": "BlockHTTP",
            "Effect": "Deny",
            "Principal": {
                "AWS": "*"
            },
            "Action": "*",
            "Resource": [
                "${monitoring_bucket_arn}/*",
                "${monitoring_bucket_arn}"
            ],
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "false"
                }
            }
        }
    ]
}    

