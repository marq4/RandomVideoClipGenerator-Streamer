# Using data sources for now (required for APIGW integrations).

data "aws_lambda_function" "generate_playlist" {
  function_name = "generate_xml_playlist_lambda"
}

data "aws_lambda_function" "send_suggested_music_video_list" {
  function_name = "respond_with_listmd_as_json"
}
