#!/bin/sh
http_code="000"

# Checks Grafana service is available.
while [[ $http_code != "200" ]]; do
    sleep 2
    curl -sL -w '%{http_code}' http://localhost:3000 -o /dev/null;
done

set -e
# If either of the AWS credentials variables were provided, validate them
if [ -n "${AWS_ACCESS_KEY_ID}${AWS_SECRET_ACCESS_KEY}" ]; then
    if [ -z "${AWS_ACCESS_KEY_ID}" -o -z "${AWS_SECRET_ACCESS_KEY}" ]; then
        echo "ERROR: You must provide both AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY variables if you want to use access key based authentication"
        exit 1
    else
        echo "INFO: Using supplied access key for authentication"
    fi
    
    # If either of the ASSUMEROLE variables were provided, validate them and configure a shared credentials fie
    if [ -n "${AWS_ASSUMEROLE_ACCOUNT}${AWS_ASSUMEROLE_ROLE}" ]; then
        if [ -z "${AWS_ASSUMEROLE_ACCOUNT}" -o -z "${AWS_ASSUMEROLE_ROLE}" ]; then
            echo "ERROR: You must provide both the AWS_ASSUMEROLE_ACCOUNT and AWS_ASSUMEROLE_ROLE variables if you want to assume role"
            exit 1
        else
            ASSUME_ROLE="arn:aws:iam::${AWS_ASSUMEROLE_ACCOUNT}:role/${AWS_ASSUMEROLE_ROLE}"
            echo "INFO: Configuring AWS credentials for assuming role to ${ASSUME_ROLE}..."
            mkdir ~/.aws
      cat > ~/.aws/credentials << EOF
[default]
aws_access_key_id=${AWS_ACCESS_KEY_ID}
aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}

[${AWS_ASSUMEROLE_ROLE}]
role_arn=${ASSUME_ROLE}
source_profile=default
EOF
            PROFILE_OPTION="--profile ${AWS_ASSUMEROLE_ROLE}"
        fi
    fi
    if [ -n "${AWS_SESSION_TOKEN}" ]; then
        sed -i -e "/aws_secret_access_key/a aws_session_token=${AWS_SESSION_TOKEN}" ~/.aws/credentials
    fi
else
    echo "INFO: Using attached IAM roles/instance profiles to authenticate with S3 as no AWS_ACCESS_KEY_ID or AWS_SECRET_ACCESS_KEY have been provided"
fi

echo "INFO: Fetching grafana credentials from $SECRET_ID"
GRAFANA_CREDENTIALS=$(aws secretsmanager get-secret-value --secret-id $SECRET_ID --query SecretString --output text | jq .grafana)
GRAFANA_USERNAME=$(echo $GRAFANA_CREDENTIALS | jq -r .username)
GRAFANA_PASSWORD=$(echo $GRAFANA_CREDENTIALS | jq -r .password)

# update private folder permissions
folders=$(curl https://$GRAFANA_USERNAME:$GRAFANA_PASSWORD@localhost:3000/api/folders)
for row in $(echo "${folders}" | jq -r '.[] | @base64'); do
    _jq() {
        echo ${row} | base64 --decode | jq -r ${1}
    }
    if [ $(_jq '.title') = "private" ]; then
        FOLDER_UID=$(_jq '.uid')
    fi
done
if [ -z $FOLDER_UID ]; then
    echo "Updating folder permissions"
    curl -X POST -H "Content-Type: application/json" -H "Accept: application/json" -d '{"items": [{"role": "Editor","permission": 2}]}' https://$GRAFANA_USERNAME:$GRAFANA_PASSWORD@localhost:3000/api/folders/$FOLDER_UID/permissions
else
    echo "No folder UID found, permissions not updated"
fi
