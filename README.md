# Graph for WP Devs

Pre-built, versioned WordPress code knowledge graphs for developers and AI coding agents.

Graph for WP Devs analyses an official WordPress release once with [Graphify](https://graphify.com/) and packages the result as reusable, provider-independent data. A developer, CLI, IDE, MCP client, Codex, Claude Code, or Gemini CLI can all read the same `graph.json`.

```text
official WordPress release → Graphify analysis → versioned graph pack → consumers
```

## What problem does this solve?

AI coding agents repeatedly search and read WordPress core to rediscover architecture that is identical for everyone targeting the same release. A graph pack preserves structural relationships once, narrows later source inspection, and makes the result shareable.

This project provides:

- WordPress core knowledge graphs and architecture reports;
- versioned, checksummed graph packs with machine-readable manifests;
- reproducible download, build, query, and verification scripts;
- project-scoped Codex, Claude Code, and Gemini CLI support;
- a stable base for future MCP, IDE, and developer tools.

It is not WordPress documentation, a live WordPress runtime, a remote execution or database tool, an AI model, or proof of dynamic runtime behavior. It is not tied to one AI vendor and does not replace Novamira or another runtime WordPress MCP.

## Quick start

Prerequisites are Git, curl, jq, Python 3.10+, uv, tar, and either `sha256sum` or `shasum`. Install Graphify in your user tool environment:

```bash
uv tool install graphifyy
graphify --version
graphify --help
```

Then clone and query a published pack:

```bash
git clone https://github.com/deshabhishek007/graph-for-wp-devs.git
cd graph-for-wp-devs
./scripts/query.sh latest "wp_insert_post"
./scripts/query.sh 7.0.3 "WP_Query"
```

`latest` is resolved at run time from WordPress.org's stable version-check API. Pre-releases, nightly builds, trunk, and invalid historical versions are rejected; the command never silently falls back.

Build and verify a pack locally:

```bash
./scripts/build-pack.sh latest
./scripts/verify-pack.sh latest
```

Graph generation uses Graphify's local code-only AST extraction, excluding bundled themes and plugins. No LLM API key is required for this build mode.

## Pack format

Every `packs/wordpress/<VERSION>/` directory contains:

| File | Purpose |
| --- | --- |
| `manifest.json` | Version, provenance, tool version, licences, statistics, and file hashes |
| `graph.json` | Graphify's reusable machine-readable graph |
| `GRAPH_REPORT.md` | Human-readable architecture report |
| `checksums.sha256` | Integrity hashes for pack content |
| `TEST_RESULTS.md` | Concise representative query results and limitations |

The public contract is [schema/manifest.schema.json](schema/manifest.schema.json). Third-party tools should select a version, validate the manifest, verify hashes, and then consume the file named by `files.graph.path`. The graph remains Graphify-native in the first release; no LLM-specific transformed copy is created.

Direct Graphify use is also possible:

```bash
graphify explain "WP_REST_Server" --graph packs/wordpress/7.0.3/graph.json
graphify path "register_rest_route" "WP_REST_Server" --graph packs/wordpress/7.0.3/graph.json
```

Read `GRAPH_REPORT.md` for broad navigation. Inspect the matching pristine source under `build/sources/` after a local build when exact implementation details matter.

## Build and provenance

`download-wordpress.sh` obtains the official tar archive from `wordpress.org`, validates its server-supplied Content-MD5 when present, extracts it without modification, and verifies every published file checksum through the official WordPress checksum API. Pristine source, archives, provenance records, and temporary analysis workspaces stay under ignored `build/` paths.

`build-pack.sh` copies core into a separate analysis workspace, excludes `wp-content/plugins` and `wp-content/themes`, runs Graphify code-only extraction, creates an unlabelled architecture clustering without LLM calls, and emits the portable pack.

The manifest's build-clock `generated_at` field is intentionally outside `graph.json` and changes between ordinary builds. Set `SOURCE_DATE_EPOCH` to make that metadata deterministic:

```bash
SOURCE_DATE_EPOCH=0 ./scripts/build-pack.sh 7.0.3
```

Graphify's community clustering is not currently byte-for-byte deterministic even with the same source, tool version, and environment. In the first WordPress 7.0.3 comparison, node and edge counts were stable while community count, assignments, report, and graph SHA-256 changed. Machine-specific report headings are normalized, but Graphify's graph content is otherwise retained. See [REPRODUCIBILITY.md](REPRODUCIBILITY.md).

## Codex, Claude Code, and Gemini CLI

Install and authenticate at least one supported agent: [Codex CLI](https://developers.openai.com/codex/cli/), [Claude Code](https://code.claude.com/docs/en/getting-started), or [Gemini CLI](https://github.com/google-gemini/gemini-cli). Then install Graphify, clone this repository, and start your preferred agent from the repository root:

```bash
uv tool install graphifyy
git clone https://github.com/deshabhishek007/graph-for-wp-devs.git
cd graph-for-wp-devs
```

The project-scoped integrations are already committed. Codex reads `AGENTS.md` and `.codex/`, Claude Code reads `CLAUDE.md` and `.claude/`, and Gemini CLI reads `GEMINI.md` and `.gemini/`. Start one of them normally:

```bash
codex   # Codex CLI
claude  # Claude Code
gemini  # Gemini CLI
```

Then ask a version-specific question, for example:

```text
For WordPress 7.0.3, use the matching graph pack to explain what calls
wp_insert_post, then inspect source only where static analysis is insufficient.
```

Maintainers can regenerate or upgrade the committed integrations with Graphify's project-scoped installer:

```bash
graphify install --project --platform codex
graphify install --project --platform claude
graphify install --project --platform gemini
```

After regeneration, review hook command paths before committing so they remain portable across machines.

The intended flow is:

```text
target WordPress version → matching pack → Graphify query → targeted source inspection
```

All three agents consume the same file under `packs/wordpress/<VERSION>/graph.json`. They do not maintain separate graph formats. See the focused examples for [Codex](examples/codex/README.md), [Claude Code](examples/claude-code/README.md), and [Gemini CLI](examples/gemini/README.md).

## Map and hands

Graph for WP Devs is the map: knowledge, architecture, relationships, call paths, code structure, and version-specific context. A runtime WordPress MCP is the hands: live-site access, file and database changes, PHP execution, plugin activation, and runtime testing.

```text
                   AI agent
                      │
             ┌────────┴────────┐
             ▼                 ▼
     Graph for WP Devs      Runtime MCP
        "How WP works"    "Actual WP site"
             └────────┬────────┘
                      ▼
                implement/test
```

They complement one another. A future MCP layer here should remain a thin consumer of versioned packs, exposing operations such as symbol lookup, neighbours, callers, callees, and paths without replacing the pack as the core data model.

## Limitations

Static analysis can be incomplete around hooks and dynamic hook names, `call_user_func`, closures, reflection, runtime callbacks, generated class/function names, dynamic includes, database-driven behavior, and plugin/theme interactions. Graphify marks relationship provenance, but a graph relationship does not prove runtime behavior. Use targeted source inspection and a live WordPress environment where correctness depends on runtime state.

## Contributing and security

See [CONTRIBUTING.md](CONTRIBUTING.md), [SECURITY.md](SECURITY.md), and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). Repository tooling is Apache-2.0 licensed. WordPress-derived pack data records WordPress's GPL-2.0-or-later provenance in each manifest.
