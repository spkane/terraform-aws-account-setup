# create CloudWatch log group
resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "CloudTrail/UserAccessLogs"
  retention_in_days = "14"
}

# create CloudWatch log stream
resource "aws_cloudwatch_log_stream" "cloudtrail" {
  name           = "${data.aws_caller_identity.current.account_id}_CloudTrail"
  log_group_name = "${aws_cloudwatch_log_group.cloudtrail.name}"
}

# FIXME: We should not be using index [0] below, 
# becuase some people may not have this reqs enabled.
# but it is fine for us.
module "alarm_root_console_login" {
  source                    = "./_modules/user_access_alarm"
  alarm_name                = "Root Console Login"
  alarm_description         = "A root user has logged into the account"
  alarm_actions             = aws_sns_topic.aws_config_updates_topic[0].arn
  cloudwatch_log_group      = aws_cloudwatch_log_group.cloudtrail.name
  cloudwatch_filter_name    = "rootConsoleLogins"
  cloudwatch_filter_pattern = "{ ($.userIdentity.type = \"Root\") && ($.eventName = \"ConsoleLogin\") && ($.responseElements.ConsoleLogin = \"Success\") }"
}

module "alarm_root_api_used" {
  source                    = "./_modules/user_access_alarm"
  alarm_name                = "Root API Used"
  alarm_description         = "A root user has used the API"
  alarm_actions             = aws_sns_topic.aws_config_updates_topic[0].arn}
  cloudwatch_log_group      = aws_cloudwatch_log_group.cloudtrail.name
  cloudwatch_filter_name    = "rootApiUsage"
  cloudwatch_filter_pattern = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" }"
}

module "alarm_root_api_key_generated" {
  source                    = "./_modules/user_access_alarm"
  alarm_name                = "Root API Key Generated"
  alarm_description         = "A root user API key has been generated"
  alarm_actions             = aws_sns_topic.aws_config_updates_topic[0].arn
  cloudwatch_log_group      = aws_cloudwatch_log_group.cloudtrail.name
  cloudwatch_filter_name    = "rootApiKeyGeneration"
  cloudwatch_filter_pattern = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" && $.eventName = \"CreateAccessKey\" }"
}

module "alarm_root_mfa_removed" {
  source                    = "./_modules/user_access_alarm"
  alarm_name                = "Root MFA Removed/Disabled"
  alarm_description         = "MFA was removed/disabled for the root user"
  alarm_actions             = aws_sns_topic.aws_config_updates_topic[0].arn
  cloudwatch_log_group      = aws_cloudwatch_log_group.cloudtrail.name
  cloudwatch_filter_name    = "rootMfaRemoved"
  cloudwatch_filter_pattern = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" && ($.eventName = \"DeleteVirtualMFADevice\" || $.eventName = \"DeactivateMFADevice\") }"
}

module "alarm_root_mfa_added" {
  source                    = "./_modules/user_access_alarm"
  alarm_name                = "Root MFA Added/Enabled"
  alarm_description         = "MFA was added/enabled for the root user"
  alarm_actions             = aws_sns_topic.aws_config_updates_topic[0].arn
  cloudwatch_log_group      = aws_cloudwatch_log_group.cloudtrail.name
  cloudwatch_filter_name    = "rootMfaAdded"
  cloudwatch_filter_pattern = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" && ($.eventName = \"CreateVirtualMFADevice\" || $.eventName = \"EnableMFADevice\") }"
}

module "alarm_root_mfa_resynced" {
  source                    = "./_modules/user_access_alarm"
  alarm_name                = "Root MFA Resynced"
  alarm_description         = "MFA was resynced for the root user"
  alarm_actions             = aws_sns_topic.aws_config_updates_topic[0].arn
  cloudwatch_log_group      = aws_cloudwatch_log_group.cloudtrail.name
  cloudwatch_filter_name    = "rootMfaResynced"
  cloudwatch_filter_pattern = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" && $.eventName = \"ResyncMFADevice\" }"
}
