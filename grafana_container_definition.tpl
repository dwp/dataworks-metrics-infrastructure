{
  "cpu": ${cpu},
  "image": "${image_url}",
  "memory": ${memory},
  "volumesFrom": ${volumes_from},
  "name": "${name}",
  "networkMode": "awsvpc",
  "user": "${user}",
  "essential": true,
  "portMappings": ${jsonencode([
    for port in jsondecode(ports) : {
      containerPort = port,
      hostPort = port,
      protocol = "tcp"
    }
  ])},
  "ulimits": ${jsonencode([
    for limit in jsondecode(ulimits) :
    {
      name      = "nofile",
      hardLimit = limit,
      softLimit = limit
    }
  ])},
  "mountPoints": ${jsonencode([
    for mount in jsondecode(mount_points) : {
      containerPath = mount.container_path,
      sourceVolume = mount.source_volume
    }
  ])},
  "logConfiguration": {
    "logDriver": "awslogs",
    "options": {
      "awslogs-group": "${log_group}",
      "awslogs-region": "${region}",
      "awslogs-stream-prefix": "${name}"
    }
  },
  "placementStrategy": [
    {
      "field": "attribute:ecs.availability-zone",
      "type": "spread"
    }
  ],
  "environment": ${jsonencode(concat([
      {
        "name": join("", [upper(group_name), "_CONFIG_S3_BUCKET"]),
        "value": config_bucket
      },
      {
        "name": join("", [upper(group_name), "_CONFIG_S3_PREFIX"]),
        "value": "monitoring/${group_name}"
      }
    ],
    [
      for variable in jsondecode(environment_variables) : {
        name = variable.name,
        value = variable.value
      }
    ]
  ))}
}
