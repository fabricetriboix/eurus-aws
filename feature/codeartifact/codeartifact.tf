# AWS CodeArtifact domain

resource "aws_codeartifact_domain" "this" {
  domain         = "${var.org}-${var.project}-${var.realm}"
  region         = var.region
  encryption_key = module.key.key_arn

  tags = {
    Name    = "staging"
    Purpose = "CodeArtifact domain for ${var.org}-${var.project}-${var.realm}"
  }
}

# AWS CodeArtifact repositories

resource "aws_codeartifact_repository" "public" {
  for_each = toset(var.public_repositories)

  domain      = aws_codeartifact_domain.this.domain
  region      = var.region
  repository  = "public:${each.value}"
  description = "CodeArtifact public repository for public:${each.value}"

  external_connections {
    external_connection_name = "public:${each.value}"
  }

  tags = {
    Name    = "public:${each.value}"
    Purpose = "CodeArtifact `public` repository for `public:${each.value}`"
  }
}

resource "aws_codeartifact_repository" "staging" {
  domain      = aws_codeartifact_domain.this.domain
  region      = var.region
  repository  = "staging"
  description = "CodeArtifact staging repository for ${var.org}-${var.project}-${var.realm}"

  tags = {
    Name    = "staging"
    Purpose = "CodeArtifact `staging` repository for ${var.org}-${var.project}-${var.realm}"
  }
}

resource "aws_codeartifact_repository" "approved" {
  domain      = aws_codeartifact_domain.this.domain
  region      = var.region
  repository  = "approved"
  description = "CodeArtifact `approved` repository for ${var.org}-${var.project}-${var.realm}"

  dynamic "upstream" {
    for_each = toset(var.public_repositories)

    content {
      repository_name = "public:${upstream.value}"
    }
  }

  tags = {
    Name    = "approved"
    Purpose = "CodeArtifact approved repository for ${var.org}-${var.project}-${var.realm}"
  }
}

# AWS CodeArtifact package groups

locals {
  public_repo_to_format = {
    "npmjs"               = "npm"
    "pypi"                = "pypi"
    "nuget-org"           = "nuget"
    "maven-central"       = "maven"
    "maven-googleandroid" = "maven"
    "maven-gradleplugins" = "maven"
    "maven-commonsware"   = "maven"
    "maven-clojars"       = "maven"
    "ruby-gems-org"       = "ruby"
    "crates-io"           = "cargo"
  }

  format_has_namespace = {
    "npm"     = true
    "pypi"    = false
    "nuget"   = false
    "maven"   = true
    "ruby"    = false
    "cargo"   = false
    "generic" = true
  }

  public_formats = toset([
    for repo in var.public_repositories : local.public_repo_to_format[repo]
  ])

  namespace = var.internal_packages_namespace == null ? var.org : var.internal_packages_namespace
}

resource "awscc_codeartifact_package_group" "public" {
  for_each = local.public_formats

  domain_name = aws_codeartifact_domain.this.domain_name
  pattern     = "/${each.value}/*"
  description = "CodeArtifact package group for `${each.value}`"

  origin_configuration = {
    restrictions = {
      publish = {
        restriction_mode = "BLOCK"
        repositories     = []
      }
      external_upstream = {
        restriction_mode = "ALLOW_SPECIFIC_REPOSITORIES`"
        repositories     = [for repo in var.public_repositories : "public:${repo}" if local.public_repo_to_format[repo] == each.value]
      }
      internal_upstream = {
        restriction_mode = "BLOCK"
        repositories     = []
      }
    }
  }

  tags = merge(local.default_tags, {
    Name    = "/${each.value}/*"
    Purpose = "CodeArtifact package group for external upstream /${each.value}/*"
  })
}

resource "awscc_codeartifact_package_group" "internal" {
  for_each = local.internal_formats

  domain_name = aws_codeartifact_domain.this.domain_name
  pattern     = local.format_has_namespace[each.value] ? "/${each.value}//${local.namespace}~" : "/${each.value}/${local.namespace}/*"
  description = "CodeArtifact package group for internal packages `${each.value}`"

  origin_configuration = {
    restrictions = {
      publish = {
        restriction_mode = "ALLOW_SPECIFIC_REPOSITORIES"
        repositories     = ["staging"]
      }
      external_upstream = {
        restriction_mode = "BLOCK"
        repositories     = []
      }
      internal_upstream = {
        restriction_mode = "BLOCK"
        repositories     = []
      }
    }
  }

  tags = merge(local.default_tags, {
    Name    = local.format_has_namespace[each.value] ? "/${each.value}//${local.namespace}~" : "/${each.value}/${local.namespace}/*"
    Purpose = "CodeArtifact package group for internal upstream /${each.value}/*"
  })
}
