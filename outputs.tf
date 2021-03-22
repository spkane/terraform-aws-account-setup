output "mfa_policy_arn" {
  description = "MFA Policy ARN"
  value       = element(concat(aws_iam_policy.mfa.*.arn, list("")), 0)
}

output "trail_arn" {
  description = "Cloud trail ARN"
  value       = element(concat(aws_cloudtrail.cloudtrail.*.arn, list("")), 0)
}

output "nr_infra_policy_arn" {
  description = "New Relic Infraastructure Policy ARN"
  value       = aws_iam_role.nr_integration_role.arn
}

output "monitor_readonly_user_arn" {
  description = "ARN for the monitor readonly user"
  value       = element(concat(aws_iam_user.monitor_readonly_user.*.arn, list("")), 0)
}

output "monitor_readonly_user_access_key_id" {
  description = "Access key id for the monitor readonly user"
  value       = element(concat(aws_iam_access_key.monitor_readonly_user_access_key.*.id, list("")), 0)
}

output "monitor_readonly_user_secret_access_key" {
  description = "Secret access key for the monitor readonly user"
  value       = element(concat(aws_iam_access_key.monitor_readonly_user_access_key.*.secret, list("")), 0)
}

output "admin_group_name" {
  description = "admin group name"
  value       = element(concat(aws_iam_group.admin.*.name, list("")), 0)
}

