terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.63.0"
    }
  }
}

# Service Discovery Private DNS Namespace
resource "aws_service_discovery_private_dns_namespace" "medusa_namespace" {
  name = "medusa.local" 
  vpc  = aws_vpc.main.id  
}

# Service Discovery Service for Medusa Postgres
resource "aws_service_discovery_service" "medusa_service" {
  name = "medusa-postgres-service"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.medusa_namespace.id

    dns_records {
      type = "A"  # Can be "SRV" based on the need
      ttl  = 60
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

# ECS Task Definition for Medusa Postgres
resource "aws_ecs_task_definition" "medusa_postgres" {
  family                   = "medusa_postgres"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.role_for_the_ecs_tasks.arn
  task_role_arn            = aws_iam_role.role_for_the_ecs_tasks.arn
  
  container_definitions = jsonencode([{
    name      = "medusa_postgres"
    image     = var.postgres_container_name.name
    essential = true
    portMappings = [{
      containerPort = 5432
      protocol      = "tcp"
    }]
    environment = [
      { name = "POSTGRES_USER", value = "medusa" },
      { name = "POSTGRES_PASSWORD", value = "medusa_password" },
      { name = "POSTGRES_DB", value = "medusa_db" }
    ]
  }])
}

# ECS Service for Medusa Postgres
resource "aws_ecs_service" "postgres_service" {
  name                   = "medusa-postgres-service"
  cluster                = aws_ecs_cluster.cluster_to_deploy_the_containers.id
  task_definition        = aws_ecs_task_definition.medusa_postgres.arn
  desired_count          = 1
  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }

  network_configuration {
    subnets          = [aws_subnet.subnet_id.id]
    security_groups  = [aws_security_group.sg_id.id]
    assign_public_ip = true
  }

  service_registries {
    registry_arn = aws_service_discovery_service.medusa_service.arn
  }
}

# ECS Task Definition for Medusa Backend
resource "aws_ecs_task_definition" "medusa_backend_server" {
  family                   = "medusa_backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.role_for_the_ecs_tasks.arn
  task_role_arn            = aws_iam_role.role_for_the_ecs_tasks.arn
  
  container_definitions = jsonencode([{
    name      = "medusa_backend"
    image     = var.medusa_container_name.name
    essential = true
	"enableExecuteCommand": true
    portMappings = [{
      containerPort = 9000
    }]
    environment = [
      { name = "POSTGRES_USER", value = "medusa" },
      { name = "POSTGRES_PASSWORD", value = "medusa_password" },
      { name = "POSTGRES_DB", value = "medusa_db" },
      { name = "DATABASE_URL", value = "postgres://medusa:medusa_password@medusa-postgres-service.medusa.local:5432/medusa_db" }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/medusa_backend_logs"
        awslogs-region        = "us-east-1"
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

# ECS Service for Medusa Backend
resource "aws_ecs_service" "pearlthoughts_medusa" {
  name                   = "pearlthoughts_medusa-service"
  cluster                = aws_ecs_cluster.cluster_to_deploy_the_containers.id
  task_definition        = aws_ecs_task_definition.medusa_backend_server.arn
  enable_execute_command = true
  desired_count          = 1
  
  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  } 

  network_configuration {
    subnets          = [aws_subnet.subnet_id.id]
    security_groups  = [aws_security_group.sg_id.id]
    assign_public_ip = true
  }

  service_registries {
    registry_arn = aws_service_discovery_service.medusa_service.arn
  }
}

# CloudWatch Log Group for Medusa Backend
resource "aws_cloudwatch_log_group" "medusa_backend_logs" {
  name              = "/ecs/medusa_backend_logs"
  retention_in_days = 7
}


