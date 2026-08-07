resource "aws_api_gateway_rest_api" "event_api" {
  name        = "event-ticketing-api"
  description = "REST API for Event Registration and Ticketing System"
}

resource "aws_api_gateway_resource" "events" {
  rest_api_id = aws_api_gateway_rest_api.event_api.id
  parent_id   = aws_api_gateway_rest_api.event_api.root_resource_id
  path_part   = "events"
}

resource "aws_api_gateway_method" "get_events" {
  rest_api_id   = aws_api_gateway_rest_api.event_api.id
  resource_id   = aws_api_gateway_resource.events.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_events_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.event_api.id
  resource_id             = aws_api_gateway_resource.events.id
  http_method             = aws_api_gateway_method.get_events.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.list_events.invoke_arn
}

resource "aws_lambda_permission" "apigw_list_events" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.list_events.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.event_api.execution_arn}/*/*"
}

resource "aws_api_gateway_resource" "event_id" {
  rest_api_id = aws_api_gateway_rest_api.event_api.id
  parent_id   = aws_api_gateway_resource.events.id
  path_part   = "{eventId}"
}

resource "aws_api_gateway_resource" "register" {
  rest_api_id = aws_api_gateway_rest_api.event_api.id
  parent_id   = aws_api_gateway_resource.event_id.id
  path_part   = "register"
}

resource "aws_api_gateway_method" "post_register" {
  rest_api_id   = aws_api_gateway_rest_api.event_api.id
  resource_id   = aws_api_gateway_resource.register.id
  http_method   = "POST"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.eventId" = true
  }
}

resource "aws_api_gateway_integration" "post_register_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.event_api.id
  resource_id             = aws_api_gateway_resource.register.id
  http_method             = aws_api_gateway_method.post_register.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.register.invoke_arn
}

resource "aws_lambda_permission" "apigw_register" {
  statement_id  = "AllowAPIGatewayInvokeRegister"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.register.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.event_api.execution_arn}/*/*"
}

resource "aws_api_gateway_method" "get_event" {
  rest_api_id   = aws_api_gateway_rest_api.event_api.id
  resource_id   = aws_api_gateway_resource.event_id.id
  http_method   = "GET"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.eventId" = true
  }
}

resource "aws_api_gateway_integration" "get_event_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.event_api.id
  resource_id             = aws_api_gateway_resource.event_id.id
  http_method             = aws_api_gateway_method.get_event.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_event.invoke_arn
}

resource "aws_lambda_permission" "apigw_get_event" {
  statement_id  = "AllowAPIGatewayInvokeGetEvent"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_event.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.event_api.execution_arn}/*/*"
}

resource "aws_api_gateway_resource" "registrations" {
  rest_api_id = aws_api_gateway_rest_api.event_api.id
  parent_id   = aws_api_gateway_resource.event_id.id
  path_part   = "registrations"
}

resource "aws_api_gateway_method" "get_registrations" {
  rest_api_id   = aws_api_gateway_rest_api.event_api.id
  resource_id   = aws_api_gateway_resource.registrations.id
  http_method   = "GET"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.eventId" = true
  }
}

resource "aws_api_gateway_integration" "get_registrations_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.event_api.id
  resource_id             = aws_api_gateway_resource.registrations.id
  http_method             = aws_api_gateway_method.get_registrations.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.list_registrations.invoke_arn
}

resource "aws_lambda_permission" "apigw_list_registrations" {
  statement_id  = "AllowAPIGatewayInvokeListRegistrations"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.list_registrations.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.event_api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "event_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.event_api.id

  depends_on = [
    aws_api_gateway_integration.get_events_lambda,
    aws_api_gateway_integration.post_register_lambda,
    aws_api_gateway_integration.get_event_lambda,
    aws_api_gateway_integration.get_registrations_lambda
  ]

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.events.id,
      aws_api_gateway_method.get_events.id,
      aws_api_gateway_integration.get_events_lambda.id,
      aws_api_gateway_resource.event_id.id,
      aws_api_gateway_resource.register.id,
      aws_api_gateway_method.post_register.id,
      aws_api_gateway_integration.post_register_lambda.id,
      aws_api_gateway_method.get_event.id,
      aws_api_gateway_integration.get_event_lambda.id,
      aws_api_gateway_resource.registrations.id,
      aws_api_gateway_method.get_registrations.id,
      aws_api_gateway_integration.get_registrations_lambda.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "dev" {
  deployment_id = aws_api_gateway_deployment.event_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.event_api.id
  stage_name    = "dev"
}