variable "name" {
  description = "cluster name, used in dns"
  type        = string
  default     = "monitoring"
}

variable "prometheus_version" {
  description = "prometheus version to use"
  type        = string
  default     = "2.23.0"
}

variable "parent_domain_name" {
  description = "parent domain name for monitoring"
  type        = string
}

variable "whitelist_cidr_blocks" {
  description = "list of allowed cidr blocks"
  type        = list(string)
}

variable "primary" {
  description = "Name used for primary role"
  type        = string
  default     = "master"
}

variable "secondary" {
  description = "Name used for secondary role"
  type        = string
  default     = "slave"
}

variable "platform_version" {
  description = "ECS Service platform version"
  type        = string
  default     = "1.4.0"
}

variable "prometheus_task_cpu" {
  default = {
    development    = "4096"
    qa             = "4096"
    integration    = "4096"
    preprod        = "4096"
    production     = "10240"
    management     = "4096"
    management-dev = "4096"
  }
}

variable "cert_metrics_task_cpu" {
  default = {
    development    = "2048"
    qa             = "2048"
    integration    = "2048"
    preprod        = "2048"
    production     = "2048"
    management     = "2048"
    management-dev = "2048"
  }
}

variable "ingest_pushgateway_task_cpu" {
  default = {
    development = "512"
    qa          = "512"
    integration = "512"
    preprod     = "512"
    production  = "1024"
  }
}

variable "prometheus_task_memory" {
  default = {
    development    = "16384"
    qa             = "16384"
    integration    = "16384"
    preprod        = "16384"
    production     = "49152"
    management     = "16384"
    management-dev = "16384"
  }
}

variable "cert_metrics_task_memory" {
  default = {
    development    = "2048"
    qa             = "2048"
    integration    = "2048"
    preprod        = "2048"
    production     = "2048"
    management     = "2048"
    management-dev = "2048"
  }
}

variable "store_cpu" {
  default = {
    management     = "4096"
    management-dev = "4096"
  }
}

variable "store_memory" {
  default = {
    management     = "30720"
    management-dev = "30720"
  }
}

variable "store_task_cpu" {
  default = {
    management     = "4096"
    management-dev = "4096"
  }
}

variable "store_task_memory" {
  default = {
    management     = "30720"
    management-dev = "30720"
  }
}

variable "query_cpu" {
  default = {
    management     = "4096"
    management-dev = "4096"
  }
}

variable "query_memory" {
  default = {
    management     = "8192"
    management-dev = "8192"
  }
}

variable "query_task_cpu" {
  default = {
    management     = "4096"
    management-dev = "4096"
  }
}

variable "query_task_memory" {
  default = {
    management     = "8192"
    management-dev = "8192"
  }
}

variable "fargate_cpu" {
  default = "512"
}

variable "fargate_memory" {
  default = "512"
}

variable "ec2_memory" {
  default = "1024"
}

variable "prometheus_cpu" {
  default = {
    development    = "1024"
    qa             = "1024"
    integration    = "1024"
    preprod        = "1024"
    production     = "8192"
    management     = "1024"
    management-dev = "1024"
  }
}

variable "cert_retriever_cpu" {
  default = {
    development    = "512"
    qa             = "512"
    integration    = "512"
    preprod        = "512"
    production     = "512"
    management     = "512"
    management-dev = "512"
  }
}

variable "cert_exporter_cpu" {
  default = {
    development    = "1024"
    qa             = "1024"
    integration    = "1024"
    preprod        = "1024"
    production     = "1024"
    management     = "1024"
    management-dev = "1024"
  }
}

variable "receiver_cpu" {
  default = {
    development    = "1024"
    qa             = "1024"
    integration    = "1024"
    preprod        = "1024"
    production     = "1024"
    management     = "1024"
    management-dev = "1024"
  }
}

variable "receiver_memory" {
  default = {
    development    = "8192"
    qa             = "8192"
    integration    = "8192"
    preprod        = "8192"
    production     = "8192"
    management     = "8192"
    management-dev = "8192"
  }
}

variable "prometheus_memory" {
  default = {
    development    = "8192"
    qa             = "8192"
    integration    = "8192"
    preprod        = "8192"
    production     = "32768"
    management     = "8192"
    management-dev = "8192"
  }
}

variable "cert_retriever_memory" {
  default = {
    development    = "1024"
    qa             = "1024"
    integration    = "1024"
    preprod        = "1024"
    production     = "1024"
    management     = "1024"
    management-dev = "1024"
  }
}

variable "cert_exporter_memory" {
  default = {
    development    = "1024"
    qa             = "1024"
    integration    = "1024"
    preprod        = "1024"
    production     = "1024"
    management     = "1024"
    management-dev = "1024"
  }
}

variable "https_port" {
  default = 443
}

variable "ulimits" {
  default = 999999
}

variable "internet_proxy_port" {}
variable "grafana_port" {}
variable "prometheus_port" {}
variable "thanos_port_grpc" {}
variable "thanos_port_remote_write" {}
variable "thanos_port_http" {}
variable "alertmanager_port" {}
variable "cloudwatch_exporter_port" {}
variable "pushgateway_port" {}
variable "json_exporter_port" {}
variable "jmx_port" {}
variable "cert_metrics_port" {
  default = 8080
}

variable "subnets" {
  description = "define sizes for subnets using Terraform cidrsubnet function. For an empty /24 VPC, the defaults will create /28 public subnets and /26 private subnets, one of each in each AZ."
  type        = map(map(number))
  default = {
    public = {
      newbits = 4
      netnum  = 0
    }
    private = {
      newbits = 2
      netnum  = 1
    }
  }
}

variable "metrics_ecs_cluster_asg_max" {
  description = "Max metrics asg size"
  default = {
    development    = 3
    qa             = 3
    integration    = 3
    preprod        = 3
    production     = 3
    management     = 3
    management-dev = 3
  }
}

variable "desired_capacity" {
  description = "Desired asg size"
  default = {
    development    = 3
    qa             = 3
    integration    = 3
    preprod        = 3
    production     = 3
    management     = 3
    management-dev = 3
  }
}

variable "additional_metrics_ecs_cluster_asg_max" {
  description = "Max metrics asg size"
  default = {
    development    = 1
    qa             = 1
    integration    = 1
    preprod        = 1
    production     = 1
    management     = 1
    management-dev = 1
  }
}

variable "additional_cluster_desired_capacity" {
  description = "Desired asg size"
  default = {
    development    = 1
    qa             = 1
    integration    = 1
    preprod        = 1
    production     = 1
    management     = 1
    management-dev = 1
  }
}

variable "image_versions" {
  description = "pinned image versions to use"
  default = {
    prometheus            = "0.0.19"
    thanos                = "0.0.34"
    alertmanager          = "0.0.5"
    ecs-service-discovery = "0.0.8"
    grafana               = "0.0.12"
    cloudwatch-exporter   = "0.0.5"
    prom-pushgateway      = "0.0.65"
    hive-exporter         = "0.0.4"
    awscli                = "0.0.10"
    blackbox              = "0.0.3"
    cert_retriever        = "0.0.17"
    cert_exporter         = "0.0.1"
  }
}


variable "metrics_ecs_cluster_ec2_size" {
  default = {
    development    = "t3.2xlarge"
    qa             = "t3.2xlarge"
    integration    = "t3.2xlarge"
    preprod        = "t3.2xlarge"
    production     = "c5.9xlarge"
    management     = "t3.2xlarge"
    management-dev = "t3.2xlarge"
  }
}

variable "additional_metrics_ecs_cluster_ec2_size" {
  default = {
    development    = "t3.medium"
    qa             = "t3.medium"
    integration    = "t3.medium"
    preprod        = "t3.medium"
    production     = "t3.medium"
    management     = "t3.medium"
    management-dev = "t3.medium"
  }
}

variable "dw_al2_ecs_ami_id" {
  description = "The AMI ID of the latest/pinned ECS Hardened AMI Image"
  type        = string
}

variable "test_ami" {
  description = "Defines if cluster should test untested ECS AMI"
  type        = bool
  default     = false
}

variable "proxy_port" {
  description = "proxy port"
  type        = string
  default     = "3128"
}

variable "tanium_port_1" {
  description = "tanium port 1"
  type        = string
  default     = "16563"
}

variable "tanium_port_2" {
  description = "tanium port 2"
  type        = string
  default     = "16555"
}