resource "aws_iam_group" "admin" {
  count = "${var.enable_admin_group ? 1 : 0}"

  name = var.admin_group_name
}

resource "aws_iam_group_policy_attachment" "mfa" {
  count = "${var.enable_admin_group && var.enable_mfa ? 1 : 0}"

  group      = aws_iam_group.admin.name[count.index]
  policy_arn = aws_iam_policy.mfa.arn
}

resource "aws_iam_group_policy_attachment" "admin" {
  count = "${var.enable_admin_group ? 1 : 0}"

  group      = aws_iam_group.admin.name[count.index]
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
