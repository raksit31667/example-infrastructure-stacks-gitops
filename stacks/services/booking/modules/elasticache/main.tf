resource "random_password" "default_password" {
  length  = 32
  special = false
}

resource "random_password" "service_password" {
  length  = 32
  special = false

  keepers = {
    rotation_id = var.service_password_rotation_id
  }
}

resource "aws_elasticache_user" "default_disabled" {
  engine    = var.engine
  user_id   = "${var.service_name}-${var.environment}-default"
  user_name = "${var.service_name}-${var.environment}-default"
  # Default user is disabled — no permissions
  access_string = "off -@all"
  passwords     = [random_password.default_password.result]

  tags = merge(var.tags, {
    Name = "${var.service_name}-${var.environment}-default"
    Type = "default-disabled"
  })
}

resource "aws_elasticache_user" "service" {
  engine    = var.engine
  user_id   = "${var.service_name}-${var.environment}-service"
  user_name = "${var.service_name}-${var.environment}-service"
  # Service user has full key permissions
  access_string = "on ~* +@all"
  passwords     = [random_password.service_password.result]

  tags = merge(var.tags, {
    Name = "${var.service_name}-${var.environment}-service"
    Type = "service"
  })
}

resource "aws_elasticache_user_group" "main" {
  engine        = var.engine
  user_group_id = "${var.service_name}-${var.environment}"
  user_ids      = [aws_elasticache_user.service.user_id]

  tags = merge(var.tags, {
    Name = "${var.service_name}-${var.environment}"
  })
}

resource "aws_elasticache_serverless_cache" "main" {
  engine = var.engine
  name   = "${var.service_name}-${var.environment}-cache"

  major_engine_version = var.engine == "redis" ? "7" : "8"
  security_group_ids   = [var.security_group_id]
  subnet_ids           = var.subnets
  user_group_id        = aws_elasticache_user_group.main.user_group_id

  cache_usage_limits {
    data_storage {
      maximum = 10
      unit    = "GB"
    }
    ecpu_per_second {
      maximum = 5000
    }
  }

  description = "${var.environment} ElastiCache for ${var.service_name}"

  tags = merge(var.tags, {
    Name = "${var.service_name}-${var.environment}-cache"
  })
}
