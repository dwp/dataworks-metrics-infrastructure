#!/bin/bash
echo ECS_CLUSTER=${cluster_name} >> /etc/ecs/ecs.config
echo ECS_AWSVPC_BLOCK_IMDS=true >> /etc/ecs/ecs.config
