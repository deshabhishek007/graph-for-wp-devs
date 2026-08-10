#!/usr/bin/env bash

set -euo pipefail
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_command jq
require_command python3
require_command uv

[[ $# -eq 1 ]] || die "usage: $0 <latest|VERSION|PACK_DIRECTORY>"
target="$1"
if [[ -d "$target" ]]; then
  pack_dir="$(CDPATH= cd -- "$target" && pwd)"
  version="$(basename "$pack_dir")"
else
  version="$(canonical_version "$target")"
  pack_dir="$PROJECT_ROOT/packs/wordpress/$version"
fi

[[ -d "$pack_dir" ]] || die "pack directory not found: $pack_dir"
for required in manifest.json graph.json GRAPH_REPORT.md checksums.sha256 TEST_RESULTS.md; do
  [[ -s "$pack_dir/$required" ]] || die "missing or empty required pack file: $required"
done

manifest_version="$(jq -er '.wordpress_version' "$pack_dir/manifest.json")"
[[ "$manifest_version" == "$version" ]] || die "folder version '$version' does not match manifest version '$manifest_version'"

uv run --quiet --with 'jsonschema>=4,<5' python "$PROJECT_ROOT/scripts/validate-manifest.py" \
  "$PROJECT_ROOT/schema/manifest.schema.json" "$pack_dir/manifest.json"

(
  cd "$pack_dir"
  while IFS=' ' read -r expected file; do
    file="${file# }"
    [[ -n "$expected" && -n "$file" ]] || die "invalid checksum line in checksums.sha256"
    [[ -f "$file" ]] || die "checksummed file missing: $file"
    actual="$(sha256_file "$file")"
    [[ "$actual" == "$expected" ]] || die "checksum mismatch: $file"
  done < checksums.sha256
)

jq -e '
  (.nodes | type == "array") and
  (((.links // .edges) | type) == "array") and
  ((.nodes | length) > 0) and
  (((.links // .edges) | length) > 0)
' "$pack_dir/graph.json" >/dev/null || die "graph.json failed basic node/edge sanity checks"

graph_sha="$(sha256_file "$pack_dir/graph.json")"
report_sha="$(sha256_file "$pack_dir/GRAPH_REPORT.md")"
[[ "$(jq -r '.files.graph.sha256' "$pack_dir/manifest.json")" == "$graph_sha" ]] || die "manifest graph checksum mismatch"
[[ "$(jq -r '.files.report.sha256' "$pack_dir/manifest.json")" == "$report_sha" ]] || die "manifest report checksum mismatch"

info "Pack wordpress/$version is valid"
