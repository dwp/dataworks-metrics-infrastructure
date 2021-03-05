# Pushgateway

We use pushgateways to collate metrics for our long and short running services.  By pushing metrics to a pushgateway, this allows us to have access to metrics even if the service producing them is down.  By default we request each service, as its last action pushes it's metrics so we are able to capture everything.

# Creating a Pushgateway

We commonly create a Pushgateway per service, as these can get very busy and it allows us to reduce noise, and filter queries per job when refining our metrics.

Each pushgateway will need the following:

- An ECS Terraform file, containing it's `task_definition`, `container_definition`, `ecs_service` and `dns` entries. [Example](../adg_pushgateway_ecs.tf)
- An IAM Terraform file, defining what role to assume when running its task. [Example](../adg_pushgateway_iam.tf)
- A Security Group Terraform file, defining its own `security_group` and it's attachments to the service it is going to recieve metrics from.  We manage this here, and not from the service itself. [Example](../adg_pushgateway_sg.tf)

You will also need to add the above security group to the [cluster security groups](../cluster_sg.tf) in order for the cluster to have access to the Pushgateway container, as well as the [Prometheus security groups](../prometheus_sg.tf), for Prometheus itself can scrape the metrics from the Pushgateway.

