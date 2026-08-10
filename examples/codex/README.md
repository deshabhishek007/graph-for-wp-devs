# Codex example

Open Codex in the repository, identify the target WordPress release, and ask it to use the matching pack. For example:

```text
For WordPress 7.0.3, use the graph pack to explain what calls wp_insert_post,
then inspect only the relevant core source for dynamic hooks.
```

From a shell, the same underlying data is queried with:

```bash
./scripts/query.sh 7.0.3 "callers of wp_insert_post"
```

