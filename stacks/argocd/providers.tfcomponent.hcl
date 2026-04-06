required_providers {
  aws = {
    source  = "hashicorp/aws"
    version = "~> 6.0"
  }
}

provider "aws" "this" {
  config {
    region = var.aws_region

    assume_role_with_web_identity {
      role_arn           = var.role_arn
      web_identity_token = var.identity_token
    }

    default_tags {
      tags = {
        EnterpriseAppID    = "<ENTERPRISE_APP_ID>"
        ManagedBy          = "Terraform Stacks"
        CreatedBy          = "github-actions"
        CostCentre         = "<COST_CENTRE>"
        Owner              = "<OWNER_TEAM>"
        Compliance         = "standard"
        DataClassification = "Confidential"
        Availability       = "24x7"
      }
    }
  }
}
