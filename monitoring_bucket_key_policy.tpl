{
    "Version": "2012-10-17",
    "Statement": [
%{ for account in split(",", accounts) }
        {
            "Effect": "Allow",
            "Action": [
                "kms:Decrypt",
                "kms:Describe*",
                "kms:List*",
                "kms:Get*"
            ],
            "Resource": ["*"],
            "Principal": { "AWS": "arn:aws:iam::${account}:root" }
        },
%{ endfor }
        {
            "Sid": "EnableIAMPermissionsBreakglass",
            "Effect": "Allow",
            "Action": ["kms:*"],
            "Resource": ["*"],
            "Principal": { "AWS": "${breakglass_arn}" }
        },
        {
            "Sid": "EnableIAMPermissionsCI",
            "Effect": "Allow",
            "Action": ["kms:*"],
            "Resource": ["*"],
            "Principal": { "AWS": "${ci_arn}" }
        },
        {
            "Sid": "EnableIAMPermissionsAdministrator",
            "Effect": "Allow",
            "Action": [
                "kms:Decrypt",
                "kms:Describe*",
                "kms:List*",
                "kms:Get*"
            ],
            "Resource": ["*"],
            "Principal": { "AWS": "${administrator_arn}" }
        },
        {
            "Sid": "EnableAWSConfigManagerScanForSecurityHub",
            "Effect": "Allow",
            "Action": [
                "kms:Decrypt",
                "kms:Describe*",
                "kms:List*",
                "kms:Get*"
            ],
            "Resource": ["*"],
            "Principal": { "AWS": "${aws_config_role_arn}" }
        }
    ]
}
