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
            "Principal": { "AWS": [
                "arn:aws:iam::${account}:role/prometheus",
                "arn:aws:iam::${account}:role/outofband",
                "arn:aws:iam::${account}:role/thanos_store",
                "arn:aws:iam::${account}:role/thanos_ruler"
            ]
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetBucketLocation"
            ],
            "Resource": [
                "${monitoring_bucket_arn}"
            ],
            "Principal": { "AWS": [
                "arn:aws:iam::${account}:role/prometheus",
                "arn:aws:iam::${account}:role/outofband",
                "arn:aws:iam::${account}:role/thanos_store",
                "arn:aws:iam::${account}:role/thanos_ruler"
            ]
            }
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
