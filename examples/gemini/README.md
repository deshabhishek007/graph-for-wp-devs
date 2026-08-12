# Gemini CLI example

Open Gemini CLI in the repository, identify the target WordPress release, and ask it to use the matching pack. For example:

```text
For WordPress 7.0.3, use the graph pack to explain how wp_remote_get connects
to the HTTP transport classes, then identify relationships that need runtime verification.
```

From a shell, the same underlying data is queried with:

```bash
./scripts/query.sh 7.0.3 "wp_remote_get HTTP transport"
```
