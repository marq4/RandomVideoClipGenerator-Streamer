# Single API for this project:
resource "aws_apigatewayv2_api" "rvcgs-http-api" {
  name          = var.apigw-api-name
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["https://${var.main-dot-com-apex-url}"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["content-type"]
  }

  tags = {
    Purpose = "HTTP API for Lambda functions"
  }

  description = "Version 2 (HTTP)."
}

# Single stage PROD:
resource "aws_apigatewayv2_stage" "prod-stage" {
  api_id      = aws_apigatewayv2_api.rvcgs-http-api.id
  name        = var.apigw-stage-name
  auto_deploy = true

  tags = {
    Environment = "Production"
  }
}


# Routes:

# To generate playlist:
resource "aws_apigatewayv2_route" "generate-playlist-route" {
  api_id    = aws_apigatewayv2_api.rvcgs-http-api.id
  route_key = "POST ${var.apigw-generate-route-path}"
  target    = "integrations/${aws_apigatewayv2_integration.core-integration.id}"
}

# To test clips, min, max with curl:
resource "aws_apigatewayv2_route" "test-values-route" {
  api_id    = aws_apigatewayv2_api.rvcgs-http-api.id
  route_key = "POST ${var.apigw-test-values-route-path}"
  target    = "integrations/${aws_apigatewayv2_integration.core-integration.id}"
}

# To retrieve project's GitHub Release version:
resource "aws_apigatewayv2_route" "get-version-route" {
  api_id    = aws_apigatewayv2_api.rvcgs-http-api.id
  route_key = "GET ${var.apigw-version-route-path}"
  target    = "integrations/${aws_apigatewayv2_integration.core-integration.id}"
}

# To retrieve list of suggested music videos:
resource "aws_apigatewayv2_route" "get-suggested-music-video-list-route" {
  api_id    = aws_apigatewayv2_api.rvcgs-http-api.id
  route_key = "GET ${var.apigw-list-route-path}"
  target    = "integrations/${aws_apigatewayv2_integration.list-integration.id}"
}

# To upload user's list of local videos with durations:
resource "aws_apigatewayv2_route" "upload-list-route" {
  api_id    = aws_apigatewayv2_api.rvcgs-http-api.id
  route_key = "GET ${var.apigw-upload-route-path}"
  target    = "integrations/${aws_apigatewayv2_integration.upload-integration.id}"
}


# Integrations (with Lambda):
# TODO: refactor (only function name changes).
resource "aws_apigatewayv2_integration" "core-integration" {
  api_id                 = aws_apigatewayv2_api.rvcgs-http-api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.core-function.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "list-integration" {
  api_id                 = aws_apigatewayv2_api.rvcgs-http-api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.list-function.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "upload-integration" {
  api_id                 = aws_apigatewayv2_api.rvcgs-http-api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.upload-function.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}


# Permissions for APIGW to invoke functions:

resource "aws_lambda_permission" "invoke-core" {
  statement_id  = "AllowAPIGWInvokeCore"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.core-function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.rvcgs-http-api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "invoke-list" {
  statement_id  = "AllowAPIGWInvokeList"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.list-function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.rvcgs-http-api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "invoke-upload" {
  statement_id  = "AllowAPIGatewayInvokePresignedURL"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.upload-function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.rvcgs-http-api.execution_arn}/*/*"
}
