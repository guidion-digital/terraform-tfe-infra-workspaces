terraform {
  required_version = ">= 1.6.1, < 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.26.0"
    }

    github = {
      source  = "integrations/github"
      version = "6.0.0"
    }

    tfe = {
      source = "hashicorp/tfe"
      version = "0.58.1"
    }
  }
}
