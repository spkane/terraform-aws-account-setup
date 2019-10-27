resource "aws_config_configuration_recorder" "aws_config_recorder" {
  count = "${var.enable_aws_config ? 1 : 0}"
  name  = "terraform_config_recorder"

  recording_group {
    all_supported = true
    include_global_resource_types = true
  }

  role_arn = aws_iam_role.aws_config_iam_role[count.index].arn
}

resource "aws_config_configuration_recorder_status" "aws_config_recorder_status" {
  count      = "${var.enable_aws_config ? 1 : 0}"
  name       = aws_config_configuration_recorder.aws_config_recorder[count.index].name
  is_enabled = true
  depends_on = ["aws_config_delivery_channel.aws_config_delivery_channel"]
}

resource "aws_s3_bucket" "aws_config_configuration_bucket" {
  count  = "${var.enable_aws_config ? 1 : 0}"
  bucket = "${data.aws_caller_identity.current.account_id}-terraform-aws-config-bucket"

  tags = "${merge(map("Project","shared"),
            map("ManagedBy","Terraform"),
            var.tags)}"
}

resource "aws_sns_topic" "aws_config_updates_topic" {
  count = "${var.enable_aws_config ? 1 : 0}"
  name  = "${data.aws_caller_identity.current.account_id}-terraform-aws-config-updates"
}

resource "aws_config_delivery_channel" "aws_config_delivery_channel" {
  count          = "${var.enable_aws_config ? 1 : 0}"
  name           = "terraform_aws_config_delivery_channel"
  s3_bucket_name = aws_s3_bucket.aws_config_configuration_bucket[count.index].bucket
  sns_topic_arn  = aws_sns_topic.aws_config_updates_topic[count.index].arn
  depends_on     = ["aws_s3_bucket.aws_config_configuration_bucket", "aws_sns_topic.aws_config_updates_topic"]
}

data "template_file" "aws_config_iam_assume_role_policy_document" {
  template = "${file("${path.module}/policies/aws_config_assume_role_policy.tpl")}"
}

resource "aws_iam_role" "aws_config_iam_role" {
  count              = "${var.enable_aws_config ? 1 : 0}"
  name               = "terraform-awsconfig-role"
  assume_role_policy = data.template_file.aws_config_iam_assume_role_policy_document.rendered
}

resource "aws_iam_role_policy_attachment" "aws_config_iam_policy_attachment" {
  count      = "${var.enable_aws_config ? 1 : 0}"
  role       = aws_iam_role.aws_config_iam_role[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

data "template_file" "aws_config_iam_policy_document" {
  template = "${file("${path.module}/policies/aws_config_policy.tpl")}"
  count    = "${var.enable_aws_config ? 1 : 0}"

  vars = {
    sns_topic_arn = aws_sns_topic.aws_config_updates_topic[count.index].arn
    s3_bucket_arn = aws_s3_bucket.aws_config_configuration_bucket[count.index].arn
  }
}

resource "aws_iam_role_policy" "aws_config_iam_policy" {
  count  = "${var.enable_aws_config ? 1 : 0}"
  name   = "terraform-awsconfig-policy"
  role   = aws_iam_role.aws_config_iam_role[count.index].id
  policy = data.template_file.aws_config_iam_policy_document[count.index].rendered
}

resource "null_resource" "sns_subscribe" {
  depends_on = ["aws_sns_topic.aws_config_updates_topic"]

  triggers = {
    sns_topic_arn = aws_sns_topic.aws_config_updates_topic[count.index].arn
  }

  count = "${length(var.aws_config_notification_emails) != 0 && var.enable_aws_config  ? length(var.aws_config_notification_emails) : 0 }"

  provisioner "local-exec" {
    command = "aws sns subscribe --profile ${var.config_sns_profile} --topic-arn ${aws_sns_topic.aws_config_updates_topic[count.index].arn} --protocol email --notification-endpoint ${element(var.aws_config_notification_emails, count.index)}"
  }
}

module "alarm_root_console_login" {
  source                    = "./_modules/user_access_alarm"
  alarm_name                = "Root Console Login"
  alarm_description         = "A root user has logged into the account"
  alarm_actions             = ["${aws_sns_topic.aws_config_updates_topic[count.index].arn}"]
  cloudwatch_log_group      = aws_cloudwatch_log_group.cloudtrail.name
  cloudwatch_filter_name    = "rootConsoleLogins"
  cloudwatch_filter_pattern = "{ ($.userIdentity.type = \"Root\") && ($.eventName = \"ConsoleLogin\") && ($.responseElements.ConsoleLogin = \"Success\") }"
}

module "alarm_root_api_used" {
  source                    = "./_modules/user_access_alarm"
  alarm_name                = "Root API Used"
  alarm_description         = "A root user has used the API"
  alarm_actions             = ["${aws_sns_topic.aws_config_updates_topic[count.index].arn}"]
  cloudwatch_log_group      = aws_cloudwatch_log_group.cloudtrail.name
  cloudwatch_filter_name    = "rootApiUsage"
  cloudwatch_filter_pattern = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" }"
}

module "alarm_root_api_key_generated" {
  source                    = "./_modules/user_access_alarm"
  alarm_name                = "Root API Key Generated"
  alarm_description         = "A root user API key has been generated"
  alarm_actions             = ["${aws_sns_topic.aws_config_updates_topic[count.index].arn}"]
  cloudwatch_log_group      = aws_cloudwatch_log_group.cloudtrail.name
  cloudwatch_filter_name    = "rootApiKeyGeneration"
  cloudwatch_filter_pattern = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" && $.eventName = \"CreateAccessKey\" }"
}

module "alarm_root_mfa_removed" {
  source                    = "./_modules/user_access_alarm"
  alarm_name                = "Root MFA Removed/Disabled"
  alarm_description         = "MFA was removed/disabled for the root user"
  alarm_actions             = ["${aws_sns_topic.aws_config_updates_topic[count.index].arn}"]
  cloudwatch_log_group      = aws_cloudwatch_log_group.cloudtrail.name
  cloudwatch_filter_name    = "rootMfaRemoved"
  cloudwatch_filter_pattern = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" && ($.eventName = \"DeleteVirtualMFADevice\" || $.eventName = \"DeactivateMFADevice\") }"
}

module "alarm_root_mfa_added" {
  source                    = "./_modules/user_access_alarm"
  alarm_name                = "Root MFA Added/Enabled"
  alarm_description         = "MFA was added/enabled for the root user"
  alarm_actions             = ["${aws_sns_topic.aws_config_updates_topic[count.index].arn}"]
  cloudwatch_log_group      = aws_cloudwatch_log_group.cloudtrail.name
  cloudwatch_filter_name    = "rootMfaAdded"
  cloudwatch_filter_pattern = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" && ($.eventName = \"CreateVirtualMFADevice\" || $.eventName = \"EnableMFADevice\") }"
}

module "alarm_root_mfa_resynced" {
  source                    = "./_modules/user_access_alarm"
  alarm_name                = "Root MFA Resynced"
  alarm_description         = "MFA was resynced for the root user"
  alarm_actions             = ["${aws_sns_topic.aws_config_updates_topic[count.index].arn}"]
  cloudwatch_log_group      = "${aws_cloudwatch_log_group.cloudtrail.name}"
  cloudwatch_filter_name    = "rootMfaResynced"
  cloudwatch_filter_pattern = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" && $.eventName = \"ResyncMFADevice\" }"
}

