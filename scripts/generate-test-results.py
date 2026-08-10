#!/usr/bin/env python3

import pathlib
import subprocess
import sys
import textwrap


TESTS = [
    ("wp_insert_post", ["explain", "wp_insert_post"], "Dynamic hooks and runtime filters can add relationships static analysis cannot prove."),
    ("WP_Query", ["explain", "WP_Query"], "Query arguments and database state determine runtime behavior."),
    ("register_post_type", ["explain", "register_post_type"], "Registration data supplied by plugins is not part of this core-only graph."),
    ("register_rest_route", ["explain", "register_rest_route"], "Route callbacks are often supplied dynamically by plugins."),
    ("wp_update_user", ["explain", "wp_update_user"], "Hooks and runtime user data can alter the executed path."),
    ("wp_remote_get", ["explain", "wp_remote_get"], "Transport selection depends on the runtime environment."),
    ("WP_REST_Server", ["explain", "WP_REST_Server"], "Registered endpoints and callbacks depend on runtime state."),
    (
        "register_rest_route → WP_REST_Server",
        ["path", "register_rest_route", "WP_REST_Server", "--undirected"],
        "A missing static path does not disprove a runtime relationship.",
    ),
]


def summarize(value: str) -> str:
    clean = " ".join(value.split())
    if not clean:
        return "No output was returned."
    return textwrap.shorten(clean, width=420, placeholder=" …")


def main() -> int:
    if len(sys.argv) != 4:
        print(f"usage: {sys.argv[0]} GRAPH VERSION OUTPUT", file=sys.stderr)
        return 2
    graph = pathlib.Path(sys.argv[1]).resolve()
    version = sys.argv[2]
    output = pathlib.Path(sys.argv[3])

    lines = [
        f"# WordPress {version} graph test results",
        "",
        "These concise smoke tests establish that representative symbols are discoverable; they do not prove complete runtime behavior.",
        "",
        "| Query | Result summary | Useful? | Known limitation |",
        "| --- | --- | --- | --- |",
    ]
    failures = 0
    for label, arguments, limitation in TESTS:
        result = subprocess.run(
            ["graphify", *arguments, "--graph", str(graph)],
            capture_output=True,
            text=True,
            check=False,
        )
        raw = (result.stdout + "\n" + result.stderr).strip()
        lower = raw.lower()
        useful = (
            result.returncode == 0
            and len(raw) > 20
            and "not found" not in lower
            and "no path" not in lower
            and "no directed path" not in lower
        )
        if not useful:
            failures += 1
        summary = summarize(raw).replace("|", "\\|")
        lines.append(f"| `{label}` | {summary} | {'Yes' if useful else 'Limited'} | {limitation} |")

    lines.extend(
        [
            "",
            "## Interpretation",
            "",
            "Graph relationships are static evidence tagged by Graphify. For hooks, generated names, callbacks, reflection, dynamic includes, database-driven behavior, and plugin/theme interactions, inspect the exact WordPress source and verify against a live runtime when needed.",
            "",
            f"Smoke tests with limited results: {failures} of {len(TESTS)}.",
            "",
        ]
    )
    output.write_text("\n".join(lines), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
