output "api_url" {
  value = "${aws_api_gateway_stage.dev.invoke_url}/events"
}
output "frontend_url" {
  value = "http://${aws_s3_bucket.frontend.bucket}.s3-website-${data.aws_region.current.name}.amazonaws.com"
}