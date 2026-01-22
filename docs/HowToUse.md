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

## Bootstrap

The first step is to create backends (S3 and DynamoDB table) for the
Terraform states. This has to be done manually. There will be one
bucket and one DynamoDB table per AWS account.

If the account where you want to deploy is different from the account
from where you have credentials, you might first need to run something
like this:

```sh
$ creds=$(aws sts assume-role \
  --role-arn arn:aws:iam::<CHILD_ACCOUNT_ID>:role/<ROLE_NAME> \
  --role-session-name tf \
  --output json)
$ export AWS_ACCESS_KEY_ID=$(echo "$creds" | jq -r .Credentials.AccessKeyId)
$ export AWS_SECRET_ACCESS_KEY=$(echo "$creds" | jq -r .Credentials.SecretAccessKey)
$ export AWS_SESSION_TOKEN=$(echo "$creds" | jq -r .Credentials.SessionToken)
$ aws sts get-caller-identity
```

NB: There are more elegant ways to achieve the same result using AWS
Identity Center, or even in `~/.aws/config`, but this is outside the
scope of this project.

Example commands for the common-nonprod backend:

```sh
$ cd bootstrap/common-nonprod
$ terragrunt init
$ terragrunt plan
$ terragrunt apply
```

You will then need to decide where to store the Terraform state file.
