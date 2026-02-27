# How to use `eurus-aws` for your own projects

Your circumstances are probably such that `eurus-aws` can't be
directly used within your organisation because it won't be compliant
with your compliance policies, or the way you do things in your
organisation. For example, you might use GitLab instead of GitHub,
or the security is not tight enough, etc. This all means that you will
likely need to take the code and adapt it to your situation.

I obviously can't cover all specific circumstances, so I will detail
here how `eurus-aws` can be used in exactly the same manner it is used
here.

Obviously, you will need to fork the repo or copy the code somehow.
You will also need to have fulfilled all the prerequisistes listed
in the top-level [README](../README.md) file.

## Allow GitHub workflows to call the AWS API

You will need to figure out how the GitHub workflows will authenticate
to AWS. This is highly dependent on your organisation, compliance
aspect, security aspects, etc.

In the case of this repo, I configured GitHub to be an identity
provider in the AWS management account. Then the bootstrap unit (see
next section) creates the necessary IAM policies and roles to allow
OpenTofu to do its job.

Finally I configured the GitHub workflows to assume the management
role created by the bootstrap unit.

## Bootstrap

The first step is to create backends (S3 and DynamoDB table) for the
OpenTofu states. There will be one bucket and one DynamoDB table per
AWS account. This is done by the [bootstrap](../bootstrap) unit. In
addition, the bootstrap unit will create IAM policies and roles to
give the GitHub workflows to necessary permissions to execute
Terragrunt and OpenTofu.

You will need to create a file named `accounts.hcl` in the
[bootstrap](bootstrap/) directory. This file should look like this:

```hcl
locals {
  accounts = {
    common-nonprod = {
      id    = "001122334455"
      type  = "common"
      realm = "nonprod"
    }
    common-prod = {
      id    = "001122334455"
      type  = "common"
      realm = "prod"
    }
    dev = {
      id    = "001122334455"
      type  = "app"
      realm = "nonprod"
    }
    prod = {
      id    = "001122334455"
      type  = "app"
      realm = "prod"
    }
  }
}
```

Obviously, use the real account IDs for your setup.

Then run the following manually:

```sh
$ cd bootstrap/common-nonprod
$ terragrunt init
$ terragrunt plan
$ terragrunt apply
```

You will then need to decide where to store the OpenTofu state file.
