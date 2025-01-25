#DynamoDB Table
resource "aws_dynamodb_table" "transactions" {
  name           = "${var.customer_name}-transactions-table-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "transaction_id"

  attribute {
    name = "transaction_id"
    type = "S"
  }

  tags = var.tags
}