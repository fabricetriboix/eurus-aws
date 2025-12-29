# How to use `eurus-aws` for your own projects

Your circumstances are probably such that `eurus-aws` can't be
directly used within your organisation because it won't be compliant
with your compliance policies, or the way you do things in your
organisation. For example, you might use GitLab instead of GitHub, or
you might be required to store Terraform modules in separate
repositories, or you won't be allowed to store the bootstrap Terraform
states in the repo, etc. This all means that you will need to take the
code and adapt it to your situation.

I obviously can't cover all specific circumstances, so I will detail
here how `eurus-aws` can be used in exactly the same manner it is used
here.

Obviously, you will need to fork the repo or copy the code somehow.
You will also need to have fulfilled all the prerequisistes listed
in the top-level [README](../README.md) file.

The first step is to create backends for the Terraform states. This
has to be done manually and the terraform states stored in this repo.
Example for the nonprod backend:

```sh
$ cd bootstrap/nonprod
$ rm terraform.tfstate
$ terragrunt init
$ terragrunt plan
$ terragrunt apply
$ git add terraform.tfstate
$ git commit
```
