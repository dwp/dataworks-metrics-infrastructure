#!/bin/bash
echo ECS_CLUSTER=metrics >> /etc/ecs/ecs.config
echo ECS_AWSVPC_BLOCK_IMDS=true >> /etc/ecs/ecs.config
echo ECS_INSTANCE_ATTRIBUTES='${ecs_attributes}' >> /etc/ecs/ecs.config

# rename ec2 instance to be unique
export AWS_DEFAULT_REGION=${region}
export INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
UUID=$(dbus-uuidgen | cut -c 1-8)
export HOSTNAME=${name}-$UUID
hostnamectl set-hostname $HOSTNAME
aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Name,Value=$HOSTNAME

# extend relevant vga
# for /var/lib/docker
lvextend -l 75%FREE /dev/rootvg/varvol
xfs_growfs /dev/mapper/rootvg-varvol

# root vol
lvextend -l 100%FREE /dev/rootvg/rootvol
xfs_growfs /dev/mapper/rootvg-rootvol

mkdir ${folder}
/usr/bin/s3fs -o iam_role=${instance_role} -o url=https://s3-${region}.amazonaws.com -o endpoint=${region} -o dbglevel=info -o curldbg -o allow_other -o use_cache=/tmp -o umask=0007,uid=65534,gid=65533 ${mnt_bucket} ${folder}

echo "Creating directories"
mkdir -p /var/log/metrics
mkdir -p /opt/metrics


echo "Downloading startup scripts"
S3_LOGROTATE="s3://${s3_scripts_bucket}/${s3_script_logrotate}"
S3_CLOUDWATCH_SHELL="s3://${s3_scripts_bucket}/${s3_script_cloudwatch_shell}"
S3_LOGGING_SHELL="s3://${s3_scripts_bucket}/${s3_script_logging_shell}"
S3_CONFIG_HCS_SHELL="s3://${s3_scripts_bucket}/${s3_script_config_hcs_shell}"

echo "Copying scripts"
$(which aws) s3 cp "$S3_LOGROTATE"     /etc/logrotate.d/dks/dks.logrotate
$(which aws) s3 cp "$S3_CLOUDWATCH_SHELL"  /opt/metrics/cloudwatch.sh
$(which aws) s3 cp "$S3_LOGGING_SHELL"     /opt/metrics/logging.sh
$(which aws) s3 cp "$S3_CONFIG_HCS_SHELL"  /opt/metrics/config_hcs.sh

echo "Setup cloudwatch logs"
chmod u+x /opt/metrics/cloudwatch.sh
/opt/metrics/cloudwatch.sh \
    "${cwa_metrics_collection_interval}" "${cwa_namespace}" "${cwa_cpu_metrics_collection_interval}" \
    "${cwa_disk_measurement_metrics_collection_interval}" "${cwa_disk_io_metrics_collection_interval}" \
    "${cwa_mem_metrics_collection_interval}" "${cwa_netstat_metrics_collection_interval}" "${cwa_log_group_name}" \
    "$AWS_DEFAULT_REGION"

echo "Setup hcs pre-requisites"
chmod u+x /opt/metrics/config_hcs.sh
/opt/metrics/config_hcs.sh "${hcs_environment}" "${proxy_host}" "${proxy_port}"

echo "Creating metrics user"
useradd metrics -m

echo "Changing permissions"
chown metrics:metrics -R  /opt/metrics
chown metrics:metrics -R  /var/log/metrics