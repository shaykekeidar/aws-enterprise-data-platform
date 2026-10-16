output "office_a_validator_role_arn" {
  description = "IAM role ARN for Office A validation Lambda"
  value       = aws_iam_role.office_a_validator.arn
}

output "office_a_validator_role_name" {
  value = aws_iam_role.office_a_validator.name
}
