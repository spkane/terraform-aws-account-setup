# This section holds the New  Relic infrastructure integraiton role
resource "aws_iam_role" "nr_integration_role" {
  name = "NewRelicInfrastructure-Integrations"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::754728514883:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "01"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_policy" "integration_budget" {
  name        = "NewRelicIntegrationBudget"
  description = "policy to attach to the Integration role"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "budgets:ViewBudget"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach-budget-policy" {
  role       = "${aws_iam_role.nr_integration_role.name}"
  policy_arn = "${aws_iam_policy.integration_budget.arn}"
}

resource "aws_iam_role_policy_attachment" "attach-readonly-policy" {
  role       = "${aws_iam_role.nr_integration_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
