resource "aws_api_gateway_rest_api" "transaction_api" {
  name = "${var.customer_name}-transaction-api-${var.environment}"
}

resource "aws_api_gateway_resource" "transaction_resource" {
  rest_api_id = aws_api_gateway_rest_api.transaction_api.id
  parent_id   = aws_api_gateway_rest_api.transaction_api.root_resource_id
  path_part   = "transaction"
}

resource "aws_api_gateway_method" "transaction_method" {
  rest_api_id   = aws_api_gateway_rest_api.transaction_api.id
  resource_id   = aws_api_gateway_resource.transaction_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "step_function_integration" {
  rest_api_id            = aws_api_gateway_rest_api.transaction_api.id
  resource_id            = aws_api_gateway_resource.transaction_resource.id
  http_method            = aws_api_gateway_method.transaction_method.http_method
  integration_http_method = "POST"
  type                   = "AWS"

  uri = "arn:aws:apigateway:${var.region}:states:action/StartExecution"

  credentials = aws_iam_role.apigateway_execution_role.arn

  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-amz-json-1.0'"
    "integration.request.header.X-Amz-Target" = "'AWSStepFunctions.StartExecution'"
  }

  request_templates = {
    "application/json" = <<EOF
{
  "input": "$util.escapeJavaScript($input.body)",
  "stateMachineArn": "${aws_sfn_state_machine.transaction_flow.arn}"
}
EOF
  }
}

resource "aws_api_gateway_deployment" "transaction_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.transaction_api.id
  stage_name  = "dev"

  depends_on = [aws_api_gateway_integration.step_function_integration]
}

resource "aws_iam_role" "apigateway_execution_role" {
  name               = "${var.customer_name}-apigateway-execution-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "apigateway.amazonaws.com"
        },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "apigateway_step_functions_policy" {
  role = aws_iam_role.apigateway_execution_role.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "states:StartExecution",
        Resource = aws_sfn_state_machine.transaction_flow.arn
      }
    ]
  })
}

resource "aws_api_gateway_vpc_link" "vpc_link" {
  name        = "transaction-api-vpc-link"
  target_arns = [aws_lb.transaction_lb.arn]
}

resource "aws_api_gateway_integration" "step_function_vpc_integration" {
  rest_api_id             = aws_api_gateway_rest_api.transaction_api.id
  resource_id             = aws_api_gateway_resource.transaction_resource.id
  http_method             = aws_api_gateway_method.transaction_method.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri                     = "http://${aws_lb.transaction_lb.dns_name}" 
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.vpc_link.id
}


resource "aws_security_group" "apigateway_sg" {
  name_prefix = "apigateway-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "transaction_lb" {
  name               = "transaction-lb"
  internal           = false
  load_balancer_type = "network"
  security_groups    = [aws_security_group.apigateway_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id] 

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "transaction_tg" {
  name     = "transaction-tg"
  port     = 80
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id
  target_type = "ip"
}

resource "aws_lb_listener" "transaction_listener" {
  load_balancer_arn = aws_lb.transaction_lb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.transaction_tg.arn
  }
}
