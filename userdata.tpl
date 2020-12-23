#!/bin/bash
echo ECS_CLUSTER=metrics >> /etc/ecs/ecs.config
echo ECS_AWSVPC_BLOCK_IMDS=true >> /etc/ecs/ecs.config
