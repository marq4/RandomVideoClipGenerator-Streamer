output "apigw-endpoint-as-templated-for-js" {
  description = "Verify JavaScripts should have correct values for APIGW endpoint (example route-path)."
  value       = "${aws_apigatewayv2_api.rvcgs-http-api.api_endpoint}/${var.apigw-stage-name}${var.apigw-generate-route-path}"
}
