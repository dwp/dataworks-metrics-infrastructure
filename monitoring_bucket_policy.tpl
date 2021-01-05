{
    "Version": "2012-10-17",
    "Statement": [
%{ for account in split(",", accounts) }
        {
            "Effect": "Allow",
            "Action": [
                "s3:List*",
                "s3:Get*",
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
        {
            "Sid": "BucketOwnerFullControl",
            "Action": [
                "s3:PutObject",
                "s3:PutObjectAcl"
            ],
            "Effect": "Allow",
            "Resource": "${monitoring_bucket_arn}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            },
            "Principal": {"AWS": "${account}"}
        }
%{ endfor }
        {
            "Effect": "Allow",
            "Action": [
                "s3:*"
            ],
            "Resource": [
                "${monitoring_bucket_arn}/*",
                "${monitoring_bucket_arn}"
            ],
            "Principal": {"AWS": "${mgmt-env}"}
        },
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

