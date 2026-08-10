# Claude Code example

Open Claude Code in the repository, identify the target WordPress release, and ask it to use the matching pack. For example:

```text
For WordPress 7.0.3, use the graph pack to trace register_rest_route to
WP_REST_Server, then inspect only the relevant core source.
```

From a shell, the same underlying data is queried with:

```bash
./scripts/query.sh 7.0.3 "register_rest_route WP_REST_Server"
```

