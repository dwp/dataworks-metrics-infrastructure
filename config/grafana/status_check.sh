#!/bin/sh

http_code="000"

while [[ $http_code != "200" ]]; do
    sleep 2
    curl -sL -w '%{http_code}' http://localhost:3000 -o /dev/null;
done

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
