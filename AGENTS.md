# Graph for WP Devs guidance

Determine the target WordPress version before answering a WordPress-core question. Select `packs/wordpress/<VERSION>/graph.json` and query it through `./scripts/query.sh <VERSION> "<question>"` or Graphify's `--graph` option before broad source searches.

Use the graph to narrow investigation, then inspect the exact matching WordPress source when implementation detail matters. Static relationships do not prove runtime behavior. Dynamic hooks and hook names, callbacks, `call_user_func`, reflection, generated names, conditional includes, database state, plugins, and themes may require source or runtime verification.

This repository publishes immutable release knowledge, not a graph of its own build scripts. Do not run `graphify update .` for WordPress questions. Codex and Claude Code must consume the same selected pack.

## graphify

This project publishes versioned knowledge graphs under `packs/wordpress/` with god nodes, community structure, and cross-file relationships.

When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.

Rules:
- For WordPress questions, first run `./scripts/query.sh <VERSION> "<question>"`. Use `graphify path "<A>" "<B>" --graph packs/wordpress/<VERSION>/graph.json` or `graphify explain "<concept>" --graph packs/wordpress/<VERSION>/graph.json` for focused traversal.
- Read the selected pack's `GRAPH_REPORT.md` only for broad architecture review or when query/path/explain do not surface enough context.
- Published packs are immutable release artefacts. Rebuild them with `./scripts/build-pack.sh <VERSION>`; never update the repository itself as the graph input.
