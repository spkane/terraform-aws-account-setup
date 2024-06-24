output "mfa_policy_arn" {
  description = "MFA Policy arn."
  value       = element(concat(aws_iam_policy.mfa.*.arn, [""]), 0)
}

output "trail_arn" {
  description = "Cloud trail arn."
  value       = element(concat(aws_cloudtrail.cloudtrail.*.arn, [""]), 0)
}

output "monitor_readonly_user_arn" {
  description = "ARN for the monitor readonly user"
  value       = element(concat(aws_iam_user.monitor_readonly_user.*.arn, [""]), 0)
}

output "monitor_readonly_user_access_key_id" {
  description = "Access key id for the monitor readonly user"
  value       = element(concat(aws_iam_access_key.monitor_readonly_user_access_key.*.id, [""]), 0)
}

output "monitor_readonly_user_secret_access_key" {
  description = "Secret access key for the monitor readonly user"
  value       = element(concat(aws_iam_access_key.monitor_readonly_user_access_key.*.secret, [""]), 0)
}

output "admin_group_name" {
  description = "admin group name"
  value       = element(concat(aws_iam_group.admin.*.name, [""]), 0)
}

