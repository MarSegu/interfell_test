# API Gateway REST API
resource "aws_api_gateway_rest_api" "transaction_api" {
  name        = "${var.customer_name}-transaction-api-2-${var.environment}"
  description = "API Gateway for the transaction processor service"
}

# API Gateway Resource
resource "aws_api_gateway_resource" "fargate_resource" {
  rest_api_id = aws_api_gateway_rest_api.transaction_api.id
  parent_id   = aws_api_gateway_rest_api.transaction_api.root_resource_id
  path_part   = "transaction"
}

# API Gateway Method
resource "aws_api_gateway_method" "fargate_method" {
  rest_api_id   = aws_api_gateway_rest_api.transaction_api.id
  resource_id   = aws_api_gateway_resource.fargate_resource.id
  http_method   = "POST" # Use POST or GET based on your requirement
  authorization = "NONE"
}

# API Gateway Integration with Fargate Service
resource "aws_api_gateway_integration" "fargate_integration" {
  rest_api_id             = aws_api_gateway_rest_api.transaction_api.id
  resource_id             = aws_api_gateway_resource.fargate_resource.id
  http_method             = aws_api_gateway_method.fargate_method.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri                     = "http://${aws_lb.transaction_nlb.dns_name}"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.transaction_vpc_link.id
}


# VPC Link for API Gateway
resource "aws_api_gateway_vpc_link" "transaction_vpc_link" {
  name        = "transaction-vpc-link"
  target_arns = [aws_lb.transaction_nlb.arn]
}

# Update Integration to use VPC Link
resource "aws_api_gateway_integration" "fargate_vpc_integration" {
  rest_api_id             = aws_api_gateway_rest_api.transaction_api.id
  resource_id             = aws_api_gateway_resource.fargate_resource.id
  http_method             = aws_api_gateway_method.fargate_method.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri                     = "http://${aws_lb.transaction_nlb.dns_name}" 
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.transaction_vpc_link.id
}

# Deployment
resource "aws_api_gateway_deployment" "transaction_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.transaction_api.id
  depends_on  = [aws_api_gateway_integration.fargate_vpc_integration]

  stage_name = "prod"
}

# API Gateway Stage
resource "aws_api_gateway_stage" "transaction_api_stage" {
  deployment_id = aws_api_gateway_deployment.transaction_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.transaction_api.id
  stage_name    = "prod"
}

# API Gateway Security Group
resource "aws_security_group" "apigateway_sg" {
  name_prefix = "apigateway-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Load Balancer Security Group
resource "aws_security_group" "alb_sg" {
  name_prefix = "alb-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow public HTTP traffic
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Network Load Balancer
resource "aws_lb" "transaction_nlb" {
  name               = "transaction-nlb"
  internal           = false
  load_balancer_type = "network"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

# Target Group for NLB
resource "aws_lb_target_group" "transaction_tg_2" {
  name        = "transaction-tg-nlb"
  port        = 80
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
}

# NLB Listener
resource "aws_lb_listener" "nlb_http_listener" {
  load_balancer_arn = aws_lb.transaction_nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.transaction_tg_2.arn
  }
}

