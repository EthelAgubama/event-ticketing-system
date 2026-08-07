data "archive_file" "list_events_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambda/list_events/lambda_function.py"
  output_path = "${path.module}/../lambda/list_events/list_events.zip"
}

resource "aws_lambda_function" "list_events" {
  function_name = "list_events"
  filename      = data.archive_file.list_events_zip.output_path
  source_code_hash = data.archive_file.list_events_zip.output_base64sha256
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  role          = aws_iam_role.lambda_exec.arn
  timeout       = 10
}
data "archive_file" "register_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambda/register/lambda_function.py"
  output_path = "${path.module}/../lambda/register/register.zip"
}

resource "aws_lambda_function" "register" {
  function_name     = "register"
  filename          = data.archive_file.register_zip.output_path
  source_code_hash  = data.archive_file.register_zip.output_base64sha256
  handler           = "lambda_function.lambda_handler"
  runtime           = "python3.12"
  role              = aws_iam_role.lambda_exec.arn
  timeout           = 10
}
data "archive_file" "get_event_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambda/get_event/lambda_function.py"
  output_path = "${path.module}/../lambda/get_event/get_event.zip"
}

resource "aws_lambda_function" "get_event" {
  function_name     = "get_event"
  filename          = data.archive_file.get_event_zip.output_path
  source_code_hash  = data.archive_file.get_event_zip.output_base64sha256
  handler           = "lambda_function.lambda_handler"
  runtime           = "python3.12"
  role              = aws_iam_role.lambda_exec.arn
  timeout           = 10
}