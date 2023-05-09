resource "aws_apigatewayv2_api" "ipam-helper-slack-api" {
  name          = "ipam-helper-slack-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "ipam-get-menu-integration" {
  api_id           = aws_apigatewayv2_api.ipam-helper-slack-api.id
  integration_type = "AWS_PROXY"

  connection_type = "INTERNET"
  # content_handling_strategy = "CONVERT_TO_TEXT"
  description          = "Ipam Helper Get Menu Integration"
  integration_method   = "POST"
  integration_uri      = aws_lambda_function.ipam_get_menu.invoke_arn
  passthrough_behavior = "WHEN_NO_MATCH"
}

resource "aws_apigatewayv2_integration" "ipam-return-action-integration" {
  api_id           = aws_apigatewayv2_api.ipam-helper-slack-api.id
  integration_type = "AWS_PROXY"

  connection_type = "INTERNET"
  # content_handling_strategy = "CONVERT_TO_TEXT"
  description          = "Ipam Helper Return Action Integration"
  integration_method   = "POST"
  integration_uri      = aws_lambda_function.ipam_return_action.invoke_arn
  passthrough_behavior = "WHEN_NO_MATCH"
}


resource "aws_apigatewayv2_route" "ipam-get-menu-route" {
  api_id    = aws_apigatewayv2_api.ipam-helper-slack-api.id
  route_key = "ANY /ipam_get_menu"

  target = "integrations/${aws_apigatewayv2_integration.ipam-get-menu-integration.id}"
}

resource "aws_apigatewayv2_route" "ipam-return-action-route" {
  api_id    = aws_apigatewayv2_api.ipam-helper-slack-api.id
  route_key = "ANY /ipam_return_action"

  target = "integrations/${aws_apigatewayv2_integration.ipam-return-action-integration.id}"
}

resource "aws_apigatewayv2_stage" "ipam-helper-slack-api-deploy" {
  api_id      = aws_apigatewayv2_api.ipam-helper-slack-api.id
  name        = "default"
  auto_deploy = true
}
