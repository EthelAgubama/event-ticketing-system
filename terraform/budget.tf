resource "aws_budgets_budget" "monthly_cost" {
  name         = "event-ticketing-monthly-budget"
  budget_type  = "COST"
  limit_amount = "20"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type              = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = ["akanzirethyl@gmail.com"]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type              = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = ["akanzirethyl@gmail.com"]
  }
}