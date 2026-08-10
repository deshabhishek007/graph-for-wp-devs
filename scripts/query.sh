#!/usr/bin/env bash

set -euo pipefail
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_command graphify
[[ $# -eq 2 ]] || die "usage: $0 <latest|VERSION> \"<QUERY>\""

version="$(canonical_version "$1")"
graph="$PROJECT_ROOT/packs/wordpress/$version/graph.json"
[[ -f "$graph" ]] || die "graph pack for WordPress $version is not installed; run ./scripts/build-pack.sh $version or download the pack"

exec graphify query "$2" --graph "$graph"

