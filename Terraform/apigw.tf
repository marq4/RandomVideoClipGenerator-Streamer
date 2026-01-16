locals {
  # Route paths:
  # (Keep here as the resource's route_key argument includes the method).
  apigw_generate_route_path    = "/generate"
  apigw_version_route_path     = "/version"
  apigw_upload_route_path      = "/upload"
  apigw_list_route_path        = "/list"
  apigw_test_values_route_path = "/testvalues"
}


resource "aws_apigatewayv2_api" "apigw_http_api" {
  name          = "RVCGS-API"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["https://${var.dns_domain_main_apex_dot_com_url}"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["content-type"]
  }

  tags = {
    Purpose = "HTTP API for Lambda functions"
  }

  description = "Single API for this project (for now). Version 2 (HTTP)."
}

# Single stage PROD (for now):
resource "aws_apigatewayv2_stage" "apigw_prod_stage" {
  api_id      = aws_apigatewayv2_api.apigw_http_api.id
  name        = "prod"
  auto_deploy = true

  tags = {
    Environment = "Production"
  }
}


# Routes:

# To generate playlist:
resource "aws_apigatewayv2_route" "apigw_generate_playlist_route" {
  api_id    = aws_apigatewayv2_api.apigw_http_api.id
  route_key = "POST ${local.apigw_generate_route_path}"
  target    = "integrations/${aws_apigatewayv2_integration.apigw_lambda_integrations["core"].id}"
}

# To test clips, min, max with curl:
resource "aws_apigatewayv2_route" "apigw_test_values_route" {
  api_id    = aws_apigatewayv2_api.apigw_http_api.id
  route_key = "POST ${local.apigw_test_values_route_path}"
  target    = "integrations/${aws_apigatewayv2_integration.apigw_lambda_integrations["core"].id}"
}

# To retrieve project's GitHub Release version:
resource "aws_apigatewayv2_route" "apigw_get_version_route" {
  api_id    = aws_apigatewayv2_api.apigw_http_api.id
  route_key = "GET ${local.apigw_version_route_path}"
  target    = "integrations/${aws_apigatewayv2_integration.apigw_lambda_integrations["core"].id}"
}

# To retrieve list of suggested music videos:
resource "aws_apigatewayv2_route" "apigw_get_suggested_music_video_list_route" {
  api_id    = aws_apigatewayv2_api.apigw_http_api.id
  route_key = "GET ${local.apigw_list_route_path}"
  target    = "integrations/${aws_apigatewayv2_integration.apigw_lambda_integrations["list"].id}"
}

# To upload user's list of local videos with durations:
resource "aws_apigatewayv2_route" "apigw_upload_route" {
  api_id    = aws_apigatewayv2_api.apigw_http_api.id
  route_key = "GET ${local.apigw_upload_route_path}"
  target    = "integrations/${aws_apigatewayv2_integration.apigw_lambda_integrations["upload"].id}"
}


# Integrations (with Lambda):
resource "aws_apigatewayv2_integration" "apigw_lambda_integrations" {
  for_each = aws_lambda_function.lambda_functions

  integration_uri = each.value.invoke_arn

  api_id                 = aws_apigatewayv2_api.apigw_http_api.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# Permissions for APIGW to invoke functions:
resource "aws_lambda_permission" "lambda_apigw_invoke_permissions" {
  for_each = aws_lambda_function.lambda_functions

  function_name = each.value.function_name
  statement_id  = "AllowAPIGWToInvoke${title(each.key)}"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.apigw_http_api.execution_arn}/*/*"
}
