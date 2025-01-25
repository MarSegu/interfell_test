# Fargate Task Definition
resource "aws_ecs_task_definition" "fargate_task" {
  family                   = "transaction-processor"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.fargate_execution_role.arn
  task_role_arn            = aws_iam_role.fargate_task_role.arn
  container_definitions = jsonencode([
    {
      name      = "processor"
      image     = var.processor_image
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "DB_HOST", value = aws_rds_cluster.aurora_cluster.endpoint },
        { name = "DB_PORT", value = "3306" },
        { name = "DB_NAME", value = aws_rds_cluster.aurora_cluster.database_name },
        { name = "DB_USER", value = aws_rds_cluster.aurora_cluster.master_username },
        { name = "DB_PASS", value = var.aurora_password }
      ]
    }
  ])
}

# Fargate Service
# ECS Service
resource "aws_ecs_service" "fargate_service" {
  name            = "transaction-processor-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.fargate_task.arn
  desired_count   = 1

  launch_type = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private.id]
    security_groups  = [aws_security_group.fargate_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.transaction_tg_2.arn
    container_name   = "processor"
    container_port   = 80
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "transaction-cluster"
}

# Fargate Security Group
resource "aws_security_group" "fargate_sg" {
  name_prefix = "fargate-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.apigateway_sg.id] # Allow traffic from API Gateway
  }

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.aurora_sg.id] # Allow DB traffic
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Fargate Task Role
resource "aws_iam_role" "fargate_task_role" {
  name = "fargate-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Fargate Execution Role
resource "aws_iam_role" "fargate_execution_role" {
  name = "fargate-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "fargate_execution_policy" {
  role       = aws_iam_role.fargate_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
