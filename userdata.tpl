#!/bin/bash
echo ECS_CLUSTER=metrics >> /etc/ecs/ecs.config
echo ECS_AWSVPC_BLOCK_IMDS=true >> /etc/ecs/ecs.config
mkdir ${folder}
/usr/bin/s3fs -o iam_role=${instance_role} -o url=https://s3-${region}.amazonaws.com -o endpoint=${region} -o dbglevel=info -o curldbg -o allow_other -o use_cache=/tmp -o umask=0007,uid=65534,gid=65533 ${mnt_bucket} ${folder}
