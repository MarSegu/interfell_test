 # Step Functions State Machine
resource "aws_sfn_state_machine" "transaction_flow" {
  name     = "${var.customer_name}-transaction-step-function-${var.environment}"
  role_arn = aws_iam_role.step_functions_exec.arn

  definition = <<EOF
{
  "Comment": "State machine for processing transactions",
  "StartAt": "ProcessTransaction",
  "States": {
    "ProcessTransaction": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.process_transactions.arn}",
      "End": true
    }
  }
}
EOF
}

# Step Functions Execution Role
resource "aws_iam_role" "step_functions_exec" {
  name = "${var.customer_name}-step-functions-exec-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = { Service = "states.amazonaws.com" }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "step_functions_policy" {
  role       = aws_iam_role.step_functions_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AWSStepFunctionsFullAccess"
}

