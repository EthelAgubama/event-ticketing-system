resource "aws_dynamodb_table" "events" {
  name         = "Events"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "eventId"

  attribute {
    name = "eventId"
    type = "S"
  }

  tags = {
    Project = "EventTicketingSystem"
  }
}

resource "aws_dynamodb_table" "registrations" {
  name         = "Registrations"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "eventId"
  range_key    = "email"

  attribute {
    name = "eventId"
    type = "S"
  }

  attribute {
    name = "email"
    type = "S"
  }

  tags = {
    Project = "EventTicketingSystem"
  }
}