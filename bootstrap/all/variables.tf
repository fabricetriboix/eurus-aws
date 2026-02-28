variable "region" {
  description = "The region where to run the boostrap"
  type        = string

  validation {
    condition     = length(var.region) > 0
    error_message = "The `region` variable must be set"
  }
}

variable "accounts" {
  description = "A map of AWS accounts to bootstrap"
  type        = map(object({
    id    = string
    type  = string
    realm = string
  }))

  validation {
    condition     = length(var.accounts) > 0
    error_message = "The `accounts` variable must be set"
  }
}
