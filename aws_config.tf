resource "aws_config_configuration_recorder" "aws_config_recorder" {
  count = var.enable_aws_config ? 1 : 0
  name  = "terraform_config_recorder"

  recording_group {
    include_global_resource_types = true
  }

  role_arn = aws_iam_role.aws_config_iam_role[0].arn
}

resource "aws_config_configuration_recorder_status" "aws_config_recorder_status" {
  count      = var.enable_aws_config ? 1 : 0
  name       = aws_config_configuration_recorder.aws_config_recorder[0].name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.aws_config_delivery_channel]
}

resource "aws_s3_bucket" "aws_config_configuration_bucket" {
  count  = var.enable_aws_config ? 1 : 0
  bucket = "${data.aws_caller_identity.current.account_id}-terraform-aws-config-bucket"

  tags = merge(
    {
      "Project" = "shared",
      "ManagedBy" = "Terraform",
    },
    var.tags
  )
}

resource "aws_sns_topic" "aws_config_updates_topic" {
  count = var.enable_aws_config ? 1 : 0
  name  = "${data.aws_caller_identity.current.account_id}-terraform-aws-config-updates"
}

resource "aws_sns_topic_subscription" "sns_subscribe" {
  count = length(var.aws_config_notification_emails) != 0 && var.enable_aws_config ? length(var.aws_config_notification_emails) : 0

  topic_arn = aws_sns_topic.aws_config_updates_topic[0].arn
  protocol  = "email"
  endpoint  = element(var.aws_config_notification_emails, count.index)
}

resource "aws_config_delivery_channel" "aws_config_delivery_channel" {
  count          = var.enable_aws_config ? 1 : 0
  name           = "terraform_aws_config_delivery_channel"
  s3_bucket_name = aws_s3_bucket.aws_config_configuration_bucket[0].bucket
  sns_topic_arn  = aws_sns_topic.aws_config_updates_topic[0].arn
  depends_on     = [aws_s3_bucket.aws_config_configuration_bucket, aws_sns_topic.aws_config_updates_topic]
}

resource "aws_iam_role" "aws_config_iam_role" {
  count = var.enable_aws_config ? 1 : 0
  name  = "terraform-awsconfig-role"

  assume_role_policy = templatefile("${path.module}/policies/aws_config_assume_role_policy.tpl", {})
}

resource "aws_iam_role_policy_attachment" "aws_config_iam_policy_attachment" {
  count      = var.enable_aws_config ? 1 : 0
  role       = aws_iam_role.aws_config_iam_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_iam_role_policy" "aws_config_iam_policy" {
  count = var.enable_aws_config ? 1 : 0
  name  = "terraform-awsconfig-policy"
  role  = aws_iam_role.aws_config_iam_role[0].id

  policy = templatefile("${path.module}/policies/aws_config_policy.tpl", {
    sns_topic_arn = aws_sns_topic.aws_config_updates_topic[0].arn
    s3_bucket_arn = aws_s3_bucket.aws_config_configuration_bucket[0].arn
  })
}
