
Fork the [eurus-aws](https://github.com/fabricetriboix/eurus-aws)
repo. Instructions
[here](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo).
It seems tags are not copied anymore, so here is how to get the tags
(this is necessary, otherwise nothing will work):

```bash
$ git remote add upstream https://github.com/fabricetriboix/eurus-aws
$ git fetch --tags upstream
$ git push --tags
```

Edit the [envs/backend.hcl](../envs/backend.hcl) file and change the
bucket name to something you like (it has to be unique across AWS).
You can also choose a region closer to you.
