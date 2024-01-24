provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      owner       = var.owner_name
      owner_email = var.owner_email
    }
  }
}

################################################################################
##   ___ _                    _ 
##  / __| |_  __ _ _ _ ___ __| |
##  \__ \ ' \/ _` | '_/ -_) _` |
##  |___/_||_\__,_|_| \___\__,_|
##                             
################################################################################

################################################################################
## Infra: Confluent Cloud Secrets
################################################################################
resource "aws_secretsmanager_secret" "cc_api_key" {
  name        = "${var.resource_prefix}-cc-api-key-${var.secret_name_suffix}"
  description = "CC API KEY"
}

resource "aws_secretsmanager_secret_version" "cc_api_key_version" {
  secret_id     = aws_secretsmanager_secret.cc_api_key.id
  secret_string = var.prometheus_confluent_cloud_api_key
}

resource "aws_secretsmanager_secret" "cc_api_secret" {
  name        = "${var.resource_prefix}-t-cc-api-secret-${var.secret_name_suffix}"
  description = "CC API KEY"
}

resource "aws_secretsmanager_secret_version" "cc_api_secret_version" {
  secret_id     = aws_secretsmanager_secret.cc_api_secret.id
  secret_string = var.prometheus_confluent_cloud_api_secret
}

################################################################################
## Infra: VPC and Subnets
################################################################################
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.resource_prefix}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-southeast-2c", "ap-southeast-2b"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
  private_subnets = ["10.0.201.0/24", "10.0.202.0/24"]

  # nat for private instances
  enable_nat_gateway = true
  enable_vpn_gateway = false

  enable_dns_hostnames = true
  enable_dns_support   = true
}

################################################################################
## ALB: Application Load Balancer in Public Subnets
################################################################################

resource "aws_alb" "alb" {
  name            = "${var.resource_prefix}-alb"
  security_groups = [aws_security_group.alb.id]
  subnets         = module.vpc.public_subnets
}

################################################################################
## ALB: Listener with Default Routing
################################################################################
resource "aws_alb_listener" "alb_default_listener" {
  load_balancer_arn = aws_alb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Access denied"
      status_code  = "403"
    }
  }

  depends_on = [aws_alb.alb]
}

################################################################################
## ALB: Create Security Group
################################################################################
resource "aws_security_group" "alb" {
  name        = "${var.resource_prefix}_alb_sg"
  description = "Security group for ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow ingress traffic to ALB"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all egress traffic"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

################################################################################
## ECS: Create ECS Cluster
################################################################################

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.resource_prefix}-cluster"
}

################################################################################
## CloudWatch: Create log group for ECS containers
################################################################################

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/${var.resource_prefix}/ecs"
  retention_in_days = 7
}

#################################################################################
## ECS: IAM Role for ECS Task execution
#################################################################################

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.resource_prefix}-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.task_assume_role_policy.json
}

data "aws_iam_policy_document" "task_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

################################################################################
##   ___                   _   _                
##  | _ \_ _ ___ _ __  ___| |_| |_  ___ _  _ ___
##  |  _/ '_/ _ \ '  \/ -_)  _| ' \/ -_) || (_-<
##  |_| |_| \___/_|_|_\___|\__|_||_\___|\_,_/__/
##
################################################################################


################################################################################
## Prometheus: Create ECR Repository
################################################################################
resource "aws_ecr_repository" "prometheus" {
  name         = var.prometheus_repo
  force_delete = true
}

################################################################################
## Prometheus: Creates ECS Task
################################################################################
resource "aws_ecs_task_definition" "prometheus" {
  family                   = "${var.resource_prefix}-prometheus-td"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = var.prometheus_cpu
  memory                   = var.prometheus_mem

  container_definitions = jsonencode([
    {
      name      = "prometheus"
      image     = "${aws_ecr_repository.prometheus.repository_url}:${var.prometheus_image_version}"
      cpu       = "${var.prometheus_cpu}"
      memory    = "${var.prometheus_mem}"
      essential = true
      portMappings = [
        {
          containerPort = "${var.prometheus_port}"
          hostPort      = "${var.prometheus_port}"
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "${aws_cloudwatch_log_group.log_group.name}"
          "awslogs-region"        = "${var.aws_region}"
          "awslogs-stream-prefix" = "${var.resource_prefix}-prometheus-log-stream"
        }
      }
      environment = [
        {
          name  = "CONFLUENT_CLOUD_API_KEY",
          value = "${aws_secretsmanager_secret_version.cc_api_key_version.secret_string}"
        },
        {
          name  = "CONFLUENT_CLOUD_API_SECRET",
          value = "${aws_secretsmanager_secret_version.cc_api_secret_version.secret_string}"
        },
        {
          name  = "PROMETHEUS_ALERTMANAGER_URL",
          value = "${var.prometheus_alertmanager_url}"
        },
        {
          name  = "PROMETHEUS_ADMIN_PASSWORD",
          value = "${var.prometheus_admin_password}"
        },
        {
          name  = "PROMETHEUS_DEBUG",
          value = "true"
        }
      ]
    }
  ])
}

################################################################################
## Prometheus: Create Target Group
################################################################################
resource "aws_alb_target_group" "prometheus_target_group" {
  name                 = "${var.resource_prefix}-prometheus-tg"
  port                 = var.prometheus_port
  protocol             = "HTTP"
  vpc_id               = module.vpc.vpc_id
  deregistration_delay = 5
  target_type          = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 60
    matcher             = "401"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 30
  }

  depends_on = [aws_alb.alb]
}

################################################################################
## Prometheus: Create Security Group
################################################################################
resource "aws_security_group" "sg_ecs_prometheus" {
  name        = "${var.resource_prefix}_ecs_prometheus_sg"
  description = "Security group for ECS prometheus running on Fargate"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow ingress traffic from ALB"
    from_port   = var.prometheus_port
    to_port     = var.prometheus_port
    protocol    = "tcp"
    # cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all egress traffic"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

################################################################################
## Prometheus: Create ECS Service
################################################################################
resource "aws_ecs_service" "prometheus_service" {
  name            = "${var.resource_prefix}_prometheus_svc"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.prometheus.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  enable_execute_command = true

  load_balancer {
    target_group_arn = aws_alb_target_group.prometheus_target_group.arn
    container_name   = "prometheus"
    container_port   = var.prometheus_port
  }

  network_configuration {
    security_groups  = [aws_security_group.sg_ecs_prometheus.id]
    subnets          = module.vpc.private_subnets
    assign_public_ip = false

    # security_groups  = []
    # subnets          = module.vpc.public_subnets
    # assign_public_ip = true
  }
}

################################################################################
## Prometheus: Create ALB Routing Rule
################################################################################
resource "aws_alb_listener_rule" "prometheus_listener_rule" {
  listener_arn = aws_alb_listener.alb_default_listener.arn

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.prometheus_target_group.arn
  }

  condition {
    host_header {
      values = ["prometheus.${var.dns_suffix}"]
    }
  }
}

################################################################################
## Prometheus: Create Route53 DNS Record
################################################################################
resource "aws_route53_record" "prometheus_record" {
  zone_id = var.dns_hosted_zone_id
  name    = "prometheus.${var.dns_suffix}"
  type    = "A"
  alias {
    name                   = aws_alb.alb.dns_name
    zone_id                = aws_alb.alb.zone_id
    evaluate_target_health = true
  }
}



################################################################################
##   ___           __                
##  / __|_ _ __ _ / _|__ _ _ _  __ _ 
## | (_ | '_/ _` |  _/ _` | ' \/ _` |
##  \___|_| \__,_|_| \__,_|_||_\__,_|
##
################################################################################


################################################################################
## Grafana: Create ECR Repository
################################################################################
resource "aws_ecr_repository" "grafana" {
  name         = var.grafana_repo
  force_delete = true
}

################################################################################
## Grafana: Creates ECS Task
################################################################################
resource "aws_ecs_task_definition" "grafana" {
  family                   = "${var.resource_prefix}-grafana-td"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = var.grafana_cpu
  memory                   = var.grafana_mem

  container_definitions = jsonencode([
    {
      name      = "grafana"
      image     = "${aws_ecr_repository.grafana.repository_url}:${var.grafana_image_version}"
      cpu       = "${var.grafana_cpu}"
      memory    = "${var.grafana_mem}"
      essential = true
      portMappings = [
        {
          containerPort = "${var.grafana_port}"
          hostPort      = "${var.grafana_port}"
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "${aws_cloudwatch_log_group.log_group.name}"
          "awslogs-region"        = "${var.aws_region}"
          "awslogs-stream-prefix" = "${var.resource_prefix}-grafana-log-stream"
        }
      }
      environment = [
        {
          name  = "GRAFANA_PROMETHEUS_URL",
          value = "${var.grafana_prometheus_url}"
        },
        {
          name  = "GRAFANA_ADMIN_PASSWORD",
          value = "${var.grafana_admin_password}"
        }
      ]
    }
  ])
}

################################################################################
## Grafana: Create Target Group
################################################################################
resource "aws_alb_target_group" "grafana_target_group" {
  name                 = "${var.resource_prefix}-grafana-tg"
  port                 = var.grafana_port
  protocol             = "HTTP"
  vpc_id               = module.vpc.vpc_id
  deregistration_delay = 5
  target_type          = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 60
    matcher             = "200"
    path                = "/api/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 30
  }

  depends_on = [aws_alb.alb]
}

################################################################################
## Grafana: Create Security Group
################################################################################
resource "aws_security_group" "sg_ecs_grafana" {
  name        = "${var.resource_prefix}_ecs_grafana_sg"
  description = "Security group for ECS grafana running on Fargate"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow ingress traffic from ALB"
    from_port   = var.grafana_port
    to_port     = var.grafana_port
    protocol    = "tcp"
    # cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all egress traffic"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

################################################################################
## Grafana: Create ECS Service
################################################################################
resource "aws_ecs_service" "grafana_service" {
  name            = "${var.resource_prefix}_grafana_svc"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.grafana.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_alb_target_group.grafana_target_group.arn
    container_name   = "grafana"
    container_port   = var.grafana_port
  }

  network_configuration {
    security_groups  = [aws_security_group.sg_ecs_grafana.id]
    subnets          = module.vpc.private_subnets
    assign_public_ip = false
  }
}

################################################################################
## Grafana: Create ALB Routing Rule
################################################################################
resource "aws_alb_listener_rule" "grafana_listener_rule" {
  listener_arn = aws_alb_listener.alb_default_listener.arn

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.grafana_target_group.arn
  }

  condition {
    host_header {
      values = ["grafana.${var.dns_suffix}"]
    }
  }
}

################################################################################
## Grafana: Create Route53 DNS Record
################################################################################
resource "aws_route53_record" "grafana_record" {
  zone_id = var.dns_hosted_zone_id
  name    = "grafana.${var.dns_suffix}"
  type    = "A"
  alias {
    name                   = aws_alb.alb.dns_name
    zone_id                = aws_alb.alb.zone_id
    evaluate_target_health = true
  }
}

################################################################################
##     _   _         _                                     
##    /_\ | |___ _ _| |_ _ __  __ _ _ _  __ _ __ _ ___ _ _ 
##   / _ \| / -_) '_|  _| '  \/ _` | ' \/ _` / _` / -_) '_|
##  /_/ \_\_\___|_|  \__|_|_|_\__,_|_||_\__,_\__, \___|_|  
##                                           |___/         
################################################################################


################################################################################
## Alertmanager: Create ECR Repository
################################################################################
resource "aws_ecr_repository" "alertmanager" {
  name         = var.alertmanager_repo
  force_delete = true
}

################################################################################
## Alertmanager: Creates ECS Task
################################################################################
resource "aws_ecs_task_definition" "alertmanager" {
  family                   = "${var.resource_prefix}-alertmanager-td"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = var.alertmanager_cpu
  memory                   = var.alertmanager_mem

  container_definitions = jsonencode([
    {
      name      = "alertmanager"
      image     = "${aws_ecr_repository.alertmanager.repository_url}:${var.alertmanager_image_version}"
      cpu       = "${var.alertmanager_cpu}"
      memory    = "${var.alertmanager_mem}"
      essential = true
      portMappings = [
        {
          containerPort = "${var.alertmanager_port}"
          hostPort      = "${var.alertmanager_port}"
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "${aws_cloudwatch_log_group.log_group.name}"
          "awslogs-region"        = "${var.aws_region}"
          "awslogs-stream-prefix" = "${var.resource_prefix}-prometheus-log-stream"
        }
      }
      environment = [
        {
          name  = "ALERTMANAGER_WEBHOOK_URL",
          value = "${var.alertmanager_webhook_url}"
        }
      ]
    }
  ])
}

################################################################################
## Alertmanager: Create Target Group
################################################################################
resource "aws_alb_target_group" "alertmanager_target_group" {
  name                 = "${var.resource_prefix}-alertmanager-tg"
  port                 = var.alertmanager_port
  protocol             = "HTTP"
  vpc_id               = module.vpc.vpc_id
  deregistration_delay = 5
  target_type          = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 60
    matcher             = "200"
    path                = "/-/healthy"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 30
  }

  depends_on = [aws_alb.alb]
}

################################################################################
## Alertmanager: Create Security Group
################################################################################
resource "aws_security_group" "sg_ecs_alertmanager" {
  name        = "${var.resource_prefix}_ecs_alertmanager_sg"
  description = "Security group for ECS alertmanager running on Fargate"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow ingress traffic from ALB"
    from_port   = var.alertmanager_port
    to_port     = var.alertmanager_port
    protocol    = "tcp"
    # cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all egress traffic"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

################################################################################
## Alertmanager: Create ECS Service
################################################################################
resource "aws_ecs_service" "alertmanager_service" {
  name            = "${var.resource_prefix}_alertmanager_svc"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.alertmanager.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_alb_target_group.alertmanager_target_group.arn
    container_name   = "alertmanager"
    container_port   = var.alertmanager_port
  }

  network_configuration {
    security_groups  = [aws_security_group.sg_ecs_alertmanager.id]
    subnets          = module.vpc.private_subnets
    assign_public_ip = false
  }
}

################################################################################
## Alertmanager: Create ALB Routing Rule
################################################################################
resource "aws_alb_listener_rule" "alertmanager_listener_rule" {
  listener_arn = aws_alb_listener.alb_default_listener.arn

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.alertmanager_target_group.arn
  }

  condition {
    host_header {
      values = ["alertmanager.${var.dns_suffix}"]
    }
  }
}

################################################################################
## Alertmanager: Create Route53 DNS Record
################################################################################
resource "aws_route53_record" "alertmanager_record" {
  zone_id = var.dns_hosted_zone_id
  name    = "alertmanager.${var.dns_suffix}"
  type    = "A"
  alias {
    name                   = aws_alb.alb.dns_name
    zone_id                = aws_alb.alb.zone_id
    evaluate_target_health = true
  }
}
