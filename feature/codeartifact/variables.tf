variable "feature_version" {
  description = "Version of the feature"
  type        = string
}

variable "org" {
  description = "Name of the organization"
  type        = string
}

variable "project" {
  description = "Name of the project"
  type        = string
}

variable "region" {
  description = "Region where the CodeArtifact domain will be configured"
  type        = string
}

variable "realm" {
  description = "Name of the realm this CodeArtifact domain will be configured for (eg: nonprod, prod)"
  type        = string

  validation {
    condition     = length(var.realm) > 0 && length(var.realm) <= 64
    error_message = "The `realm` variable must be set and must have at most 64 characters."
  }
}

variable "env" {
  description = "Name of the environment this CodeArtifact domain will be configured for (eg: dev, stg, prd)"
  type        = string

  validation {
    condition     = length(var.env) > 0 && length(var.env) <= 16
    error_message = "The `env` variable must be set and must have at most 16 characters."
  }
}

variable "public_repositories" {
  description = "List of public repositories that should be made available; eg: [\"npmjs\", \"pypi\"]"
  type        = list(string)

  validation {
    condition = alltrue([
      for repo in var.public_repositories : contains([
        "npmjs",
        "pypi",
        "nuget-org",
        "maven-central",
        "maven-googleandroid",
        "maven-gradleplugins",
        "maven-commonsware",
        "maven-clojars",
        "ruby-gems-org",
        "crates-io",
      ], repo)
    ])
    error_message = "Each item in `public_repositories` must be one of: npmjs, pypi, nuget-org, maven-central, maven-googleandroid, maven-gradleplugins, maven-commonsware, maven-clojars, ruby-gems-org, crates-io."
  }
}

variable "internal_formats" {
  description = "List of internal package formats that should be made available; eg: [\"npm\", \"pypi\", \"maven\", \"nuget\"]"
  type        = list(string)

  validation {
    condition = alltrue([
      for format in var.internal_formats : contains([
        "npm",
        "pypi",
        "maven",
        "nuget",
        "generic",
        "ruby",
        "swift",
        "cargo",
      ], format)
    ])
    error_message = "Each item in `internal_formats` must be one of: npm, pypi, maven, nuget, generic, ruby, swift, cargo."
  }
}

variable "internal_packages_namespace" {
  description = "Namespace (or prefix) to use for internal packages. This can be either `null`, in which case the organisation name will be used as the namespace, or a non-empty string of at most 16 characters."
  type        = string
  default     = null

  validation {
    condition     = var.internal_packages_namespace == null || (length(var.internal_packages_namespace) > 0 && length(var.internal_packages_namespace) <= 16)
    error_message = "The `internal_packages_namespace` variable must be either `null` or a non-empty string of at most 16 characters."
  }
}

variable "internal_maven_namespace" {
  description = "Namespace to use for internal Maven packages. This can be either `null`, in which case `com.{org}` will be used, or a non-empty string of at most 16 characters. This parameter is ignored if `internal_formats` does not contain `maven`."
  type        = string
  default     = null

  validation {
    condition     = var.internal_maven_namespace == null || (length(var.internal_maven_namespace) > 0 && length(var.internal_maven_namespace) <= 16)
    error_message = "The `internal_maven_namespace` variable must be either `null` or a non-empty string of at most 16 characters."
  }
}

variable "accounts_with_pull_access" {
  description = "List of IDs of AWS accounts that should be granted pull access to the approved repository; eg: [\"123456789012\", \"123456789013\"]"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for account in var.accounts_with_pull_access : length(account) == 12
    ])
    error_message = "Each item in `accounts_with_pull_access` must be a 12-digit string."
  }
}
