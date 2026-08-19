# AWS CodeArtifact domain

resource "aws_codeartifact_domain" "this" {
  domain         = local.domain_name
  region         = var.region
  encryption_key = module.key.key_arn

  tags = {
    Name    = local.domain_name
    Purpose = "CodeArtifact domain for ${local.domain_name}"
  }
}

data "aws_iam_policy_document" "domain" {
  count = length(var.accounts_with_pull_access) > 0 ? 1 : 0

  statement {
    sid = "BasicDomainPolicy"
    actions = [
      "codeartifact:GetDomainPermissionsPolicy",
      "codeartifact:ListRepositoriesInDomain",
      "codeartifact:GetAuthorizationToken",
      "codeartifact:DescribeDomain"
    ]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = [for account in var.accounts_with_pull_access : "arn:aws:iam::${account}:root"]
    }
  }
}

resource "aws_codeartifact_domain_permissions_policy" "this" {
  count = length(var.accounts_with_pull_access) > 0 ? 1 : 0

  domain          = aws_codeartifact_domain.this.domain
  policy_document = data.aws_iam_policy_document.domain[0].json
}

# AWS CodeArtifact repositories

resource "aws_codeartifact_repository" "public" {
  for_each = toset(var.public_repositories)

  domain      = aws_codeartifact_domain.this.domain
  region      = var.region
  repository  = "public-${each.value}"
  description = "CodeArtifact public repository for `public-${each.value}`"

  external_connections {
    external_connection_name = "public:${each.value}"
  }

  tags = {
    Name    = "public-${each.value}"
    Purpose = "CodeArtifact public repository for public:${each.value}"
  }
}

resource "aws_codeartifact_repository" "staging" {
  domain      = aws_codeartifact_domain.this.domain
  region      = var.region
  repository  = "staging"
  description = "CodeArtifact `staging` repository for `${local.domain_name}`"

  tags = {
    Name    = "staging"
    Purpose = "CodeArtifact staging repository for domain ${local.domain_name}"
  }
}

resource "aws_codeartifact_repository" "approved" {
  domain      = aws_codeartifact_domain.this.domain
  region      = var.region
  repository  = "approved"
  description = "CodeArtifact `approved` repository for `${local.domain_name}`"

  dynamic "upstream" {
    for_each = toset(var.public_repositories)

    content {
      repository_name = aws_codeartifact_repository.public[upstream.value].repository
    }
  }

  tags = {
    Name    = "approved"
    Purpose = "CodeArtifact approved repository for domain ${local.domain_name}"
  }
}

data "aws_iam_policy_document" "approved" {
  count = length(var.accounts_with_pull_access) > 0 ? 1 : 0

  statement {
    sid = "AllowPullingPackages"
    actions = [
      "codeartifact:DescribePackageVersion",
      "codeartifact:DescribeRepository",
      "codeartifact:GetPackageVersionReadme",
      "codeartifact:GetRepositoryEndpoint",
      "codeartifact:ListPackages",
      "codeartifact:ListPackageVersions",
      "codeartifact:ListPackageVersionAssets",
      "codeartifact:ListPackageVersionDependencies",
      "codeartifact:ReadFromRepository"
    ]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = [for account in var.accounts_with_pull_access : "arn:aws:iam::${account}:root"]
    }
  }
}

resource "aws_codeartifact_repository_permissions_policy" "approved" {
  count = length(var.accounts_with_pull_access) > 0 ? 1 : 0

  domain          = aws_codeartifact_domain.this.domain
  repository      = aws_codeartifact_repository.approved.repository
  policy_document = data.aws_iam_policy_document.approved[0].json
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
    "swift"   = true
  }

  public_formats = toset([
    for repo in var.public_repositories : local.public_repo_to_format[repo]
  ])

  namespace = var.internal_packages_namespace == null ? var.org : var.internal_packages_namespace

  maven_namespace = var.internal_maven_namespace == null ? "com.${var.org}" : var.internal_maven_namespace
}

resource "awscc_codeartifact_package_group" "public" {
  for_each = local.public_formats

  domain_name = aws_codeartifact_domain.this.domain
  pattern     = "/${each.value}/*"
  description = "CodeArtifact package group for `${each.value}`"

  origin_configuration = {
    restrictions = {
      publish = {
        restriction_mode = "BLOCK"
        repositories     = []
      }
      external_upstream = {
        restriction_mode = "ALLOW_SPECIFIC_REPOSITORIES"
        repositories     = [for repo in var.public_repositories : "public-${repo}" if local.public_repo_to_format[repo] == each.value]
      }
      internal_upstream = {
        restriction_mode = "ALLOW_SPECIFIC_REPOSITORIES"
        repositories     = ["approved"]
      }
    }
  }

  tags = concat(
    [for key, value in local.default_tags : {
      key   = key
      value = value
    }],
    [
      {
        key   = "Name"
        value = "/${each.value}/"
      },
      {
        key   = "Purpose"
        value = "CodeArtifact package group for public repositories /${each.value}/"
      }
    ]
  )
}

resource "awscc_codeartifact_package_group" "internal" {
  for_each = toset(var.internal_formats)

  domain_name = aws_codeartifact_domain.this.domain
  pattern     = each.value == "maven" ? "/${each.value}/${local.maven_namespace}/*" : local.format_has_namespace[each.value] ? "/${each.value}/${local.namespace}/*" : "/${each.value}//${local.namespace}~"
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

  tags = concat(
    [for key, value in local.default_tags : {
      key   = key
      value = value
    }],
    [
      {
        key   = "Name"
        value = each.value == "maven" ? "/${each.value}/${local.maven_namespace}/" : local.format_has_namespace[each.value] ? "/${each.value}/${local.namespace}/" : "/${each.value}//${local.namespace}"
      },
      {
        key   = "Purpose"
        value = "CodeArtifact package group for internal packages /${each.value}/"
      }
    ]
  )
}
