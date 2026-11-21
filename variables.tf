variable "regions" {
  description = "List of regions (the first one is the primary region)"
  type        = list(string)

  validation {
    condition     = length(var.regions) > 0
    error_message = "The `regions` variable must be set"
  }

  validation {
    condition     = length(var.regions) == length(distinct(var.regions))
    error_message = "The `regions` variable must contain unique regions"
  }
}

variable "accounts" {
  description = "A map of AWS accounts to bootstrap"
  type = map(object({
    id    = string
    type  = string
    realm = string
  }))

  validation {
    condition     = length(var.accounts) > 0
    error_message = "The `accounts` variable must be set"
  }
}
