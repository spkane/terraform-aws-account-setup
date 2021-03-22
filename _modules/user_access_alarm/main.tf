resource "aws_cloudwatch_log_metric_filter" "filter" {
  name           = var.cloudwatch_filter_name
  pattern        = var.cloudwatch_filter_pattern
  log_group_name = var.cloudwatch_log_group

  metric_transformation {
    name          = var.cloudwatch_filter_name
    namespace     = "userAccess"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "alarm" {
  alarm_name          = var.alarm_name
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = aws_cloudwatch_log_metric_filter.filter.id
  namespace           = "userAccess"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = var.alarm_description
  alarm_actions       = [ var.alarm_actions ]
}
