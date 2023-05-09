data "archive_file" "ipam_get_menu" {
  type        = "zip"
  source_dir  = abspath("${path.root}/../../lambda_ipam_get_menu")
  output_path = abspath("${path.root}/../modules/ipam-helper/lambda_ipam_get_menu.zip")
}

resource "aws_iam_role" "iam_for_ipam_get_menu" {
  name = "iam_for_ipam_get_menu"

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

resource "aws_lambda_function" "ipam_get_menu" {
  filename      = data.archive_file.ipam_get_menu.output_path
  function_name = "ipam_get_menu"
  role          = aws_iam_role.iam_for_ipam_get_menu.arn
  handler       = "lambda_function.lambda_handler"


  source_code_hash = filebase64sha256(data.archive_file.ipam_get_menu.output_path)
  runtime          = "python3.8"
  timeout          = 30  # Time out in second, default value is 3
  memory_size      = 128 # Default value in MB

  environment {
    variables = {
      kmsEncryptedToken = "replacelater"
    }
  }
  depends_on = [aws_cloudwatch_log_group.cw_ipam_get_menu]
  tags       = var.tags
}

resource "aws_cloudwatch_log_group" "cw_ipam_get_menu" {
  name              = "/aws/lambda/ipam_get_menu"
  retention_in_days = 180
}

# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
resource "aws_iam_policy" "ipam_get_menu_lambda_logging" {
  name        = "ipam_get_menu_lambda_logging"
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

resource "aws_iam_role_policy_attachment" "ipam_get_menu_lambda_logs" {
  role       = aws_iam_role.iam_for_ipam_get_menu.name
  policy_arn = aws_iam_policy.ipam_get_menu_lambda_logging.arn
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ipam_get_menu.function_name
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_apigatewayv2_api.ipam-helper-slack-api.execution_arn}/*/*/ipam_get_menu"
}
