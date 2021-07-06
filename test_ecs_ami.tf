resource "aws_ecs_task_definition" "test_ecs_ami" {
  count                    = local.environment == "development" ? 1 : 0 # TODO: change to qa before committing
  family                   = "test_ecs_ami"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  task_role_arn            = aws_iam_role.cert_metrics.arn
  execution_role_arn       = "arn:aws:iam::${local.account[local.environment]}:role/ecsTaskExecutionRole"
  container_definitions    = "[${data.template_file.test_ecs_ami_definition[local.primary_role_index].rendered}]"
  tags                     = merge(local.tags, { Name = var.name })
}

data "template_file" "test_ecs_ami_definition" {
  count    = local.environment == "development" ? 1 : 0 # TODO: change to qa before committing
  template = file("${path.module}/container_definition.tpl")
  vars = {
    name          = "test-ecs-ami"
    group_name    = "test-ecs-ami"
    cpu           = 128
    image_url     = data.terraform_remote_state.management.outputs.ecr_awscli_url
    memory        = 512
    user          = "root"
    ports         = jsonencode({})
    ulimits       = jsonencode([])
    log_group     = aws_cloudwatch_log_group.monitoring_metrics.name
    region        = data.aws_region.current.name
    config_bucket = local.is_management_env ? data.terraform_remote_state.management.outputs.config_bucket.id : data.terraform_remote_state.common.outputs.config_bucket.id

    mount_points = jsonencode([])

    environment_variables = jsonencode([])
  }
}
