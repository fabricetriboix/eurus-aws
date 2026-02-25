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
provider in the AWS management account. I then created an IAM policy
that allows assuming roles in the children accounts with necessary
permissions to allow Terraform to do its job. Then I created an IAM
role in the AWS management account and attached the above IAM policy.
Then I created IAM roles in each of the children account to allow
Terraform to do its job, and set their trust policies to allow the IAM
role in the AWS management account to assume them. This is all done in
the bootstrap (see next section).

Finally I configured the GitHub workflows to assume this role.

## Bootstrap

The first step is to create backends (S3 and DynamoDB table) for the
Terraform states. This has to be done manually. There will be one
bucket and one DynamoDB table per AWS account. This is done by the
[bootstrap](../bootstrap) component. In addition, the bootstrap
component will create IAM policies and roles to allow Terraform to do
its job.

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
Identity Center, but this is outside the scope of this project.

Example commands for the common-nonprod backend:

```sh
$ cd bootstrap/common-nonprod
$ terragrunt init
$ terragrunt plan
$ terragrunt apply
```

You will then need to decide where to store the Terraform state file.
