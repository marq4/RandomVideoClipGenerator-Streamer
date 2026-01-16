output "apigw_endpoint_as_templated_for_js" {
  description = "To quickly see if JavaScripts will get the correct values for APIGW endpoint using an example route/path."
  value       = "${aws_apigatewayv2_api.apigw_http_api.api_endpoint}/${aws_apigatewayv2_stage.apigw_prod_stage.name}${local.apigw_generate_route_path}"
}
