# CloudWatch Logs for Monitoring
resource "aws_cloudwatch_log_group" "fargate_logs" {
  name              = "/aws/fargate/process-transactions"
  retention_in_days = 14

  tags = var.tags
}