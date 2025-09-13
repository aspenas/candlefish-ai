terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }
  
  backend "s3" {
    bucket         = "candlefish-terraform-state"
    key            = "production/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "candlefish-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = var.environment
      Project     = "Candlefish"
      ManagedBy   = "Terraform"
      Owner       = "DevOps"
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"
  
  environment         = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = data.aws_availability_zones.available.names
  
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  
  enable_nat_gateway = true
  enable_vpn_gateway = false
  enable_dns_hostnames = true
  enable_dns_support = true
  
  tags = local.common_tags
}

# ECS Cluster
module "ecs" {
  source = "../../modules/ecs"
  
  environment = var.environment
  cluster_name = "${var.project_name}-${var.environment}"
  
  vpc_id = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  
  enable_container_insights = true
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
  
  tags = local.common_tags
}

# RDS Database
module "rds" {
  source = "../../modules/rds"
  
  environment = var.environment
  identifier = "${var.project_name}-${var.environment}"
  
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = var.rds_instance_class
  
  allocated_storage     = 100
  max_allocated_storage = 1000
  storage_encrypted     = true
  
  database_name = "candlefish"
  username      = "candlefish_admin"
  
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids
  allowed_cidr_blocks = [var.vpc_cidr]
  
  backup_retention_period = 30
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  multi_az               = true
  deletion_protection    = true
  skip_final_snapshot    = false
  
  tags = local.common_tags
}

# ElastiCache Redis
module "redis" {
  source = "../../modules/elasticache"
  
  environment = var.environment
  cluster_id = "${var.project_name}-${var.environment}"
  
  engine         = "redis"
  engine_version = "7.0"
  node_type      = var.redis_node_type
  num_cache_nodes = 2
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  
  automatic_failover_enabled = true
  multi_az_enabled          = true
  
  snapshot_retention_limit = 7
  snapshot_window         = "03:00-05:00"
  
  tags = local.common_tags
}

# S3 Buckets
module "s3" {
  source = "../../modules/s3"
  
  environment = var.environment
  
  buckets = {
    assets = {
      name = "${var.project_name}-${var.environment}-assets"
      versioning = true
      lifecycle_rules = [
        {
          id      = "expire-old-versions"
          enabled = true
          noncurrent_version_expiration_days = 90
        }
      ]
    }
    backups = {
      name = "${var.project_name}-${var.environment}-backups"
      versioning = true
      lifecycle_rules = [
        {
          id      = "transition-to-glacier"
          enabled = true
          transition_days = 30
          storage_class = "GLACIER"
        }
      ]
    }
  }
  
  tags = local.common_tags
}

# Application Load Balancer
module "alb" {
  source = "../../modules/alb"
  
  environment = var.environment
  name = "${var.project_name}-${var.environment}"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids
  
  enable_deletion_protection = true
  enable_http2              = true
  enable_cross_zone_load_balancing = true
  
  ssl_certificate_arn = var.ssl_certificate_arn
  
  tags = local.common_tags
}

# ECS Services
module "clos_service" {
  source = "../../modules/ecs-service"
  
  environment = var.environment
  service_name = "clos-orchestrator"
  
  cluster_id = module.ecs.cluster_id
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  
  task_definition = {
    family = "clos-orchestrator"
    cpu    = "1024"
    memory = "2048"
    
    container_definitions = jsonencode([
      {
        name  = "clos"
        image = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/candlefish-clos:${var.image_tag}"
        
        portMappings = [
          {
            containerPort = 8000
            protocol      = "tcp"
          }
        ]
        
        environment = [
          { name = "ENVIRONMENT", value = var.environment },
          { name = "AWS_REGION", value = var.aws_region }
        ]
        
        secrets = [
          { name = "DATABASE_URL", valueFrom = aws_secretsmanager_secret.database_url.arn },
          { name = "REDIS_URL", valueFrom = aws_secretsmanager_secret.redis_url.arn },
          { name = "SECRET_KEY", valueFrom = aws_secretsmanager_secret.secret_key.arn },
          { name = "JWT_SECRET", valueFrom = aws_secretsmanager_secret.jwt_secret.arn }
        ]
        
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            "awslogs-group"         = "/ecs/clos-orchestrator"
            "awslogs-region"        = var.aws_region
            "awslogs-stream-prefix" = "ecs"
          }
        }
        
        healthCheck = {
          command     = ["CMD-SHELL", "curl -f http://localhost:8000/health || exit 1"]
          interval    = 30
          timeout     = 5
          retries     = 3
          startPeriod = 60
        }
      }
    ])
  }
  
  desired_count = var.clos_desired_count
  
  autoscaling = {
    min_capacity = 2
    max_capacity = 10
    
    target_tracking_cpu = {
      target_value = 70
    }
    
    target_tracking_memory = {
      target_value = 80
    }
  }
  
  load_balancer = {
    target_group_arn = module.alb.target_group_arns["clos"]
    container_name   = "clos"
    container_port   = 8000
  }
  
  tags = local.common_tags
}

# Lambda Functions
module "lambda_agents" {
  source = "../../modules/lambda"
  
  environment = var.environment
  
  functions = {
    ticket_analyzer = {
      name          = "${var.project_name}-${var.environment}-ticket-analyzer"
      handler       = "handler.main"
      runtime       = "python3.12"
      memory_size   = 1024
      timeout       = 300
      
      environment_variables = {
        ENVIRONMENT = var.environment
        AWS_REGION  = var.aws_region
      }
    }
    
    venue_matcher = {
      name          = "${var.project_name}-${var.environment}-venue-matcher"
      handler       = "handler.main"
      runtime       = "python3.12"
      memory_size   = 512
      timeout       = 120
      
      environment_variables = {
        ENVIRONMENT = var.environment
        AWS_REGION  = var.aws_region
      }
    }
    
    price_optimizer = {
      name          = "${var.project_name}-${var.environment}-price-optimizer"
      handler       = "handler.main"
      runtime       = "python3.12"
      memory_size   = 2048
      timeout       = 300
      
      environment_variables = {
        ENVIRONMENT = var.environment
        AWS_REGION  = var.aws_region
      }
    }
  }
  
  tags = local.common_tags
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "ecs_logs" {
  for_each = toset([
    "/ecs/clos-orchestrator",
    "/ecs/promoteros-api",
    "/ecs/paintbox"
  ])
  
  name              = each.value
  retention_in_days = 30
  
  tags = local.common_tags
}

# Secrets Manager
resource "aws_secretsmanager_secret" "database_url" {
  name = "${var.project_name}-${var.environment}-database-url"
  
  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "database_url" {
  secret_id = aws_secretsmanager_secret.database_url.id
  secret_string = "postgresql://${module.rds.username}:${module.rds.password}@${module.rds.endpoint}/${module.rds.database_name}"
}

resource "aws_secretsmanager_secret" "redis_url" {
  name = "${var.project_name}-${var.environment}-redis-url"
  
  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "redis_url" {
  secret_id = aws_secretsmanager_secret.redis_url.id
  secret_string = "redis://${module.redis.primary_endpoint}"
}

resource "aws_secretsmanager_secret" "secret_key" {
  name = "${var.project_name}-${var.environment}-secret-key"
  
  tags = local.common_tags
}

resource "aws_secretsmanager_secret" "jwt_secret" {
  name = "${var.project_name}-${var.environment}-jwt-secret"
  
  tags = local.common_tags
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "${var.project_name}-${var.environment}-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ECS CPU utilization"
  
  dimensions = {
    ClusterName = module.ecs.cluster_name
  }
  
  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${var.project_name}-${var.environment}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "75"
  alarm_description   = "This metric monitors RDS CPU utilization"
  
  dimensions = {
    DBInstanceIdentifier = module.rds.db_instance_id
  }
  
  tags = local.common_tags
}

# Outputs
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "alb_dns_name" {
  value = module.alb.dns_name
}

output "rds_endpoint" {
  value = module.rds.endpoint
}

output "redis_endpoint" {
  value = module.redis.primary_endpoint
}

# Local variables
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Owner       = "DevOps"
    CostCenter  = "Engineering"
  }
}