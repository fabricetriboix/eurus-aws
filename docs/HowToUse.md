# How to use `eurus-aws` for your own projects

Your circumstances are probably such that `eurus-aws` can't be
directly used within your organisation because it won't be compliant
with your compliance policies, or the way things are done in your
organisation. For example, you might use GitLab instead of GitHub, or
the security is not tight enough, etc. This all means that you will
likely need to take the code and adapt it to your situation.

I obviously can't cover all specific circumstances, so I will detail
here how `eurus-aws` can be used in exactly the same manner it is used
here.

## Prerequisites

Fork the [eurus-aws](https://github.com/fabricetriboix/eurus-aws)
repo. Instructions are
[here](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo).
It seems tags are not copied anymore, so here is how to get the tags
(this is necessary, otherwise nothing will work):

```bash
$ git remote add upstream https://github.com/fabricetriboix/eurus-aws
$ git fetch --tags upstream
$ git push --tags
```

You will also need to have fulfilled all the prerequisistes listed
in the top-level [README](../README.md) file.

## Setup GitHub

### Create environments and variables/secrets

Create environments in GitHub for each environment, plus a `bootstrap`
environment (which is used only for bootstrap CI). Example for this
project:
  - common-nonprod
  - common-prod
  - dev
  - prod
  - bootstrap

For each environment, add an `AWS_ACCOUNT_ID` variable which holds the
ID of the AWS account that hosts this particular environment. You also
need to create the following repository variables:
  - `AWS_MANAGEMENT_ACCOUNT_ID`: ID of the management account
  - `AWS_REGION`: Region where the platform is deployed

You can customise environments to your liking, for example by
requesting certain users to approve the workflows before being
deployed, etc.

### Allow GitHub workflows to call the AWS API

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

It should be noted that, as it stands, the IAM roles deployed by the
`bootstrap` have `AdministratorAccess` permissions. This is obviously
unacceptable and you should give these roles appropriate permissions
based on the least privilege principle, according to your compliance
and security needs. You should do this in the [bootstrap
module](../module/bootstrap/tf-iam.tf).

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

## Create the infrastructure

First, you will need to decide on your network topology and your
CIDRs. You will also need to modify the code and add any necessary
resources to access your on-prem services (if any). This typically
takes the form of a Transit Gateway with VPNs, but every
infrastructure is different and it's not possible for `eurus-aws` to
cater for every possible scenario.

Generally speaking, you should avoid any overlap in CIDRs. This is
because you might want to create routes between VPCs and overlapping
CIDRs will make this impossible.

Every environment has a `config.yaml` file that fully describes it. As
far as possible, every configuration parameter should go into this
file in order to make it easy to review and modify the configuration
of a given environment.
