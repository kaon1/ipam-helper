data "archive_file" "ipam_return_action" {
  type        = "zip"
  source_dir  = abspath("${path.root}/../../lambda_ipam_return_action")
  output_path = abspath("${path.root}/../modules/ipam-helper/lambda_ipam_return_action.zip")
}

resource "aws_iam_role" "iam_for_ipam_return_action" {
  name = "iam_for_ipam_return_action"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "ipam_return_action" {
  filename      = data.archive_file.ipam_return_action.output_path
  function_name = "ipam_return_action"
  role          = aws_iam_role.iam_for_ipam_return_action.arn
  handler       = "lambda_function.lambda_handler"


  source_code_hash = filebase64sha256(data.archive_file.ipam_return_action.output_path)
  runtime          = "python3.8"
  timeout          = 30  # Time out in second, default value is 3
  memory_size      = 128 # Default value in MB

  vpc_config {
    subnet_ids         = ["<subnet1>", "<subnet2>"]
    security_group_ids = [aws_security_group.lambda_slackbot_sg.id]
  }

  environment {
    variables = {
      kmsEncryptedToken = "replacelater"
      NETBOX_TOKEN      = "replacelater"
    }
  }
  depends_on = [aws_cloudwatch_log_group.cw_ipam_return_action]
  tags       = var.tags
}

resource "aws_cloudwatch_log_group" "cw_ipam_return_action" {
  name              = "/aws/lambda/ipam_return_action"
  retention_in_days = 180
}

# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
resource "aws_iam_policy" "ipam_return_action_lambda_logging" {
  name        = "ipam_return_action_lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    },
    {
        "Sid": "VisualEditor0",
        "Effect": "Allow",
        "Action": "kms:*",
        "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ipam_return_action_lambda_logs" {
  role       = aws_iam_role.iam_for_ipam_return_action.name
  policy_arn = aws_iam_policy.ipam_return_action_lambda_logging.arn
}

resource "aws_lambda_permission" "apigw_2" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ipam_return_action.function_name
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_apigatewayv2_api.ipam-helper-slack-api.execution_arn}/*/*/ipam_return_action"
}

resource "aws_iam_role_policy_attachment" "iam_role_policy_attachment_lambda_vpc_access_execution" {
  role       = aws_iam_role.iam_for_ipam_return_action.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_security_group" "lambda_slackbot_sg" {
  # provider    = aws.us-east-1
  name        = "lambda_slackbot_sg"
  description = "Security Group to manage lambda_slackbot access"
  vpc_id      = data.terraform_remote_state.account_base.outputs.vpc_east_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
