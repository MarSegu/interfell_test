# CloudWatch Logs for Monitoring
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/process-transactions"
  retention_in_days = 14

  tags = var.tags
}