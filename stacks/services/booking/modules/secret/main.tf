locals {
  secret_name = "${var.service_name}-${var.environment}-secret"
}

resource "aws_secretsmanager_secret" "main" {
  name                    = local.secret_name
  recovery_window_in_days = var.recovery_window_in_days
  description             = "${var.environment} secret for ${var.service_name} service"

  tags = merge(var.tags, {
    Name        = local.secret_name
    Application = var.service_name
    Environment = var.environment
  })
}

resource "aws_secretsmanager_secret_version" "main" {
  secret_id     = aws_secretsmanager_secret.main.id
  secret_string = var.secret_string
}
