{
    "Version": "2012-10-17",
    "Statement": [
%{ for account in split(",", accounts) }
        {
            "Effect": "Allow",
            "Action": [
                "s3:Put*",
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
%{ endfor }
        {
            "Effect": "Allow",
            "Action": [
                "s3:*"
            ],
            "Resource": ["*"],
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

