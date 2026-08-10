# Reproducibility findings

Two full WordPress 7.0.3 builds were run on the same machine with Graphify 0.9.37 and the same verified source archive.

| Observation | First build | Second build | Published build |
| --- | --- | --- | --- |
| Nodes | 23,623 | 23,623 | 23,623 |
| Edges after clustering | 51,883 | 51,883 | 51,883 |
| Communities | 1,720 | 1,726 | 1,730 |
| `graph.json` SHA-256 | `dd48a9bfcb6e076c65c57ed5937e70ba233f303e524b7c41f400c8633d5d0289` | `4c0c1e598d4d337c703abb92eb7fa9175c2012cf049533e326987937afeebd53` | `96a5fbcdedc7496822ab6926f4171bb4c47167f4f64457c5d8178160d1404d0c` |

AST extraction produced the same node and edge counts, but Graphify community detection changed community count and assignments. Because community fields are stored in `graph.json`, the graph is not byte-for-byte deterministic. This project does not modify Graphify internals or strip those fields simply to force a matching hash.

The build removes the absolute analysis path and wall-clock date from the first line of `GRAPH_REPORT.md`. The manifest keeps `generated_at` outside the graph; `SOURCE_DATE_EPOCH` makes that timestamp reproducible. File paths inside the graph are relative to WordPress core. Tool-version changes, platform behavior, ordering, generated identifiers, and future Graphify algorithms remain potential sources of differences.

For comparisons, pin Graphify, use the same verified WordPress archive, set the same `SOURCE_DATE_EPOCH`, and compare counts as well as hashes. A hash difference requires review but is not by itself evidence that the WordPress source changed.
