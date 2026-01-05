output "apigw_endpoint_url" {
  description = "Single APIGW (RVCGS-API) invoke URL."
  value       = aws_apigatewayv2_api.rvcgs-http-api.api_endpoint
}
