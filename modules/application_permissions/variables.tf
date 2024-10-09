variable "name" {
  description = "Will be used for IAM policy, and user"
}

variable "application_name" {
  description = "Name of the application we're creating permissions for. TODO: This should probably be the only name neded, and var.name deleted, but needs verifying"
  default     = null
}

variable "workspace_policy" {
  description = "Policy to attach to the IAM user created by this module"
}

variable "domain_account_role" {
  description = "Assumable role used to assume into account holding the Route53 zone"
  type        = string
  default     = null
}

variable "project" {
  description = "Can be thought of as the Organisational Unit. Used for naming and tagging. It is _not_ the application name"
  type        = string
  default     = null
}

variable "cdn_app" {
  description = "Values used when creating IAM resources for a CDN application"

  type = object({
    bucket_name = string
  })

  default = null
}

variable "api_app" {
  description = "Values used when creating IAM resources for an API application"

  type = object({
    firewall_ipset_arns = list(string),
    dynamodb_arns       = list(string),
    sqs_arns            = list(string),
    sns_arns            = list(string),
    event_arns          = list(string),
    ruleset_arns        = list(string)
  })

  default = null
}

variable "container_app" {
  description = "Values used when creating IAM resources for a container (ECS) application"

  type = object({
    targetgroup_arn           = string,
    loadbalancers             = list(string),
    loadbalancer_listener_arn = string,
    ecs_cluster_arn           = string,
    ecs_service_arn           = string
  })

  default = null
}

variable "ec2_app" {
  description = "Values used when creating IAM resources for an EC2 application type"

    type = object({
    targetgroup_arn : string,
    loadbalancers : list(string),
    loadbalancer_listener_arn : string,
  })
  
  default = null
}

variable "supporting_services" {
  description = "List of AWS services this application uses"
  default     = []

  validation {
    condition     = !contains([for this_service in var.supporting_services : contains(["sqs", "dynamodb"], this_service)], false)
    error_message = "Valid service supporting services are sqs or dynamodb"
  }
}

variable "application_policy" {
  description = "Optional IAM policy document to create and attach to the IAM role that the application can assume"
  default     = null
}

variable "application_policy_arns" {
  description = "Optional list of ARNs of IAM policies to attach to the IAM role that the application can assume"
  type        = list(string)
  default     = []
}

variable "application_role_arn_names" {
  description = "Ready-made roles to allow the IAM user to pass"
  type        = list(string)
  default     = []
}

variable "service_types" {
  description = "Needed in order to allow assumerole from these types"
  type        = list(string)
  default     = []

  validation {
    condition     = !contains([for this_type in var.service_types : contains(["lambda", "ec2", "ecs-tasks", "cloudfront", "edgelambda"], this_type)], false)
    error_message = "Valid service types are: lambda, ec2, ecs-tasks, cloudfront, edgelambda"
  }
}

variable "workspace_id" {
  description = "Which workspace to put populate"
}

variable "aws_region" {
  description = "Region in which the secret can be found"
}
