#!/usr/bin/env bash

set -euo pipefail
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_command graphify
require_command jq
require_command python3
require_command tar

[[ $# -eq 1 ]] || die "usage: $0 <latest|VERSION>"
version="$(canonical_version "$1")"
source_dir="$("$PROJECT_ROOT/scripts/download-wordpress.sh" "$version")"
provenance="$PROJECT_ROOT/build/provenance/wordpress-${version}.json"
work_parent="$PROJECT_ROOT/build/work/wordpress-${version}"
mkdir -p "$work_parent"
work_dir="$(mktemp -d "$work_parent/run.XXXXXX")"
analysis_input="$work_dir/source"
output_root="$work_dir/result"
graphify_output="$output_root/graphify-out"
pack_dir="$PROJECT_ROOT/packs/wordpress/$version"

mkdir -p "$output_root" "$pack_dir"

mkdir -p "$analysis_input"
info "Preparing a fresh core-only analysis workspace (default themes and plugins excluded)"
tar -cf - \
  --exclude='./wp-content/plugins' \
  --exclude='./wp-content/themes' \
  --exclude='./graphify-out' \
  -C "$source_dir" . | tar -xf - -C "$analysis_input"

info "Building the WordPress $version graph with Graphify"
graphify extract "$analysis_input" \
  --code-only \
  --no-cluster \
  --no-gitignore \
  --force \
  --max-workers "${GRAPHIFY_MAX_WORKERS:-4}" \
  --out "$output_root"

graph="$graphify_output/graph.json"
[[ -s "$graph" ]] || die "Graphify did not produce $graph"

info "Clustering the graph and generating its architecture report without LLM labels"
graphify cluster-only "$analysis_input" \
  --graph "$graph" \
  --no-label \
  --no-viz

report="$graphify_output/GRAPH_REPORT.md"
[[ -s "$report" ]] || die "Graphify did not produce $report"

install -m 0644 "$graph" "$pack_dir/graph.json"
install -m 0644 "$report" "$pack_dir/GRAPH_REPORT.md"
python3 - "$pack_dir/GRAPH_REPORT.md" "$version" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
lines = path.read_text(encoding="utf-8").splitlines()
if lines:
    lines[0] = f"# Graph Report - WordPress core {sys.argv[2]}"
path.write_text("\n".join(lines) + "\n", encoding="utf-8")
PY
python3 "$PROJECT_ROOT/scripts/generate-test-results.py" \
  "$graph" "$version" "$pack_dir/TEST_RESULTS.md"

graph_sha="$(sha256_file "$pack_dir/graph.json")"
report_sha="$(sha256_file "$pack_dir/GRAPH_REPORT.md")"
tests_sha="$(sha256_file "$pack_dir/TEST_RESULTS.md")"
nodes="$(jq -er '.nodes | length' "$pack_dir/graph.json")"
edges="$(jq -er '(.links // .edges) | length' "$pack_dir/graph.json")"
payload_bytes="$(wc -c < "$pack_dir/graph.json" | tr -d ' ')"
payload_bytes="$((payload_bytes + $(wc -c < "$pack_dir/GRAPH_REPORT.md" | tr -d ' ') + $(wc -c < "$pack_dir/TEST_RESULTS.md" | tr -d ' ')))"
graphify_version="$(graphify --version | awk '{print $NF}')"

if [[ -n "${SOURCE_DATE_EPOCH:-}" ]]; then
  generated_at="$(python3 - "$SOURCE_DATE_EPOCH" <<'PY'
import datetime
import sys

print(datetime.datetime.fromtimestamp(int(sys.argv[1]), datetime.timezone.utc).isoformat().replace("+00:00", "Z"))
PY
)"
  generated_at_source="SOURCE_DATE_EPOCH"
else
  generated_at="$(python3 - <<'PY'
import datetime

print(datetime.datetime.now(datetime.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"))
PY
)"
  generated_at_source="build-clock"
fi

jq -n \
  --arg version "$version" \
  --arg graphify_version "$graphify_version" \
  --arg generated_at "$generated_at" \
  --arg generated_at_source "$generated_at_source" \
  --arg archive "$(jq -r '.archive_url' "$provenance")" \
  --arg archive_sha256 "$(jq -r '.archive_sha256' "$provenance")" \
  --arg archive_content_md5 "$(jq -r '.archive_content_md5 // empty' "$provenance")" \
  --arg checksum_api "$(jq -r '.checksum_api' "$provenance")" \
  --arg graph_sha "$graph_sha" \
  --arg report_sha "$report_sha" \
  --arg tests_sha "$tests_sha" \
  --argjson verified_files "$(jq -r '.verified_files' "$provenance")" \
  --argjson nodes "$nodes" \
  --argjson edges "$edges" \
  --argjson payload_bytes "$payload_bytes" \
  '{
    schema_version: 1,
    pack_type: "wordpress-core",
    wordpress_version: $version,
    graphify: {
      version: $graphify_version,
      package: "graphifyy",
      license: "Apache-2.0",
      build_mode: "code-only"
    },
    generated_at: $generated_at,
    source: {
      project: "WordPress",
      provider: "wordpress.org",
      archive: $archive,
      archive_sha256: $archive_sha256,
      archive_content_md5: (if $archive_content_md5 == "" then null else $archive_content_md5 end),
      checksum_api: $checksum_api,
      verified_files: $verified_files,
      license: "GPL-2.0-or-later"
    },
    files: {
      graph: {path: "graph.json", sha256: $graph_sha},
      report: {path: "GRAPH_REPORT.md", sha256: $report_sha},
      test_results: {path: "TEST_RESULTS.md", sha256: $tests_sha}
    },
    statistics: {
      nodes: $nodes,
      edges: $edges,
      payload_bytes: $payload_bytes
    },
    reproducibility: {
      core_graph_expected_deterministic: false,
      generated_at_source: $generated_at_source,
      known_nondeterminism: ["Graphify community detection and community ID assignment"]
    }
  }' > "$pack_dir/manifest.json.tmp"
mv "$pack_dir/manifest.json.tmp" "$pack_dir/manifest.json"

(
  cd "$pack_dir"
  for file in graph.json GRAPH_REPORT.md TEST_RESULTS.md manifest.json; do
    printf '%s  %s\n' "$(sha256_file "$file")" "$file"
  done > checksums.sha256.tmp
  mv checksums.sha256.tmp checksums.sha256
)

"$PROJECT_ROOT/scripts/verify-pack.sh" "$pack_dir"
info "Built $pack_dir ($nodes nodes, $edges edges)"
