#!/usr/bin/env bash

set -euo pipefail
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_command curl
require_command jq
require_command python3
require_command tar

[[ $# -eq 1 ]] || die "usage: $0 <latest|VERSION>"
version="$(canonical_version "$1")"

archive_dir="$PROJECT_ROOT/build/cache/archives"
source_parent="$PROJECT_ROOT/build/sources"
provenance_dir="$PROJECT_ROOT/build/provenance"
checksums_dir="$PROJECT_ROOT/build/cache/checksums"
archive="$archive_dir/wordpress-${version}.tar.gz"
headers="$archive_dir/wordpress-${version}.headers"
source_dir="$source_parent/wordpress-${version}"
provenance="$provenance_dir/wordpress-${version}.json"
checksums_file="$checksums_dir/wordpress-${version}-en_US.json"
archive_url="https://wordpress.org/wordpress-${version}.tar.gz"
checksums_url="$WORDPRESS_API/checksums/1.0/?version=${version}&locale=en_US"

mkdir -p "$archive_dir" "$source_parent" "$provenance_dir" "$checksums_dir"

if [[ ! -f "$archive" ]]; then
  tmp_archive="$(mktemp "$archive_dir/.wordpress-${version}.XXXXXX")"
  tmp_headers="$(mktemp "$archive_dir/.wordpress-${version}.headers.XXXXXX")"
  info "Downloading WordPress $version from $archive_url"
  curl --fail --show-error --location --dump-header "$tmp_headers" --output "$tmp_archive" "$archive_url"
  mv "$tmp_archive" "$archive"
  mv "$tmp_headers" "$headers"
fi

archive_sha256="$(sha256_file "$archive")"
header_md5=""
if [[ -f "$headers" ]]; then
  header_md5="$(awk 'BEGIN { IGNORECASE=1 } /^content-md5:/ { gsub("\\r", "", $2); print tolower($2) }' "$headers" | tail -n 1)"
fi
if [[ "$header_md5" =~ ^[0-9a-f]{32}$ ]]; then
  actual_md5="$(python3 - "$archive" <<'PY'
import hashlib
import pathlib
import sys

h = hashlib.md5(usedforsecurity=False)
with pathlib.Path(sys.argv[1]).open("rb") as stream:
    for chunk in iter(lambda: stream.read(1024 * 1024), b""):
        h.update(chunk)
print(h.hexdigest())
PY
)"
  [[ "$actual_md5" == "$header_md5" ]] || die "archive Content-MD5 verification failed for $archive"
fi

if [[ ! -f "$checksums_file" ]]; then
  checksums_tmp="$(mktemp "$checksums_dir/.wordpress-${version}.XXXXXX")"
  curl --fail --silent --show-error --location "$checksums_url" > "$checksums_tmp"
  mv "$checksums_tmp" "$checksums_file"
fi
jq -e '.checksums and (.checksums | length > 0)' "$checksums_file" >/dev/null ||
  die "official checksum response for WordPress $version was empty"

if [[ ! -d "$source_dir" ]]; then
  extract_tmp="$(mktemp -d "$source_parent/.wordpress-${version}.XXXXXX")"
  python3 - "$archive" <<'PY'
import pathlib
import sys
import tarfile

archive = pathlib.Path(sys.argv[1])
with tarfile.open(archive, "r:gz") as tar:
    for member in tar.getmembers():
        path = pathlib.PurePosixPath(member.name)
        if path.is_absolute() or ".." in path.parts or not path.parts or path.parts[0] != "wordpress":
            raise SystemExit(f"unsafe archive member: {member.name}")
PY
  tar -xzf "$archive" -C "$extract_tmp"
  mv "$extract_tmp/wordpress" "$source_dir"
fi

verified_count="$(python3 - "$source_dir" "$checksums_file" <<'PY'
import hashlib
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
payload = json.loads(pathlib.Path(sys.argv[2]).read_text())
checksums = payload.get("checksums", {})
failures = []
for relative, expected in checksums.items():
    path = root / relative
    if not path.is_file():
        failures.append(f"missing: {relative}")
        continue
    digest = hashlib.md5(path.read_bytes(), usedforsecurity=False).hexdigest()
    if digest != expected:
        failures.append(f"mismatch: {relative}")
if failures:
    print("\n".join(failures[:20]), file=sys.stderr)
    if len(failures) > 20:
        print(f"... and {len(failures) - 20} more", file=sys.stderr)
    raise SystemExit(1)
print(len(checksums))
PY
)" || die "WordPress.org file checksum verification failed for $source_dir"

last_modified=""
if [[ -f "$headers" ]]; then
  last_modified="$(awk 'BEGIN { IGNORECASE=1 } /^last-modified:/ { sub(/^[^:]+:[[:space:]]*/, ""); gsub("\\r", ""); print }' "$headers" | tail -n 1)"
fi

jq -n \
  --arg version "$version" \
  --arg archive_url "$archive_url" \
  --arg archive_sha256 "$archive_sha256" \
  --arg archive_content_md5 "$header_md5" \
  --arg checksum_api "$checksums_url" \
  --arg last_modified "$last_modified" \
  --argjson verified_files "$verified_count" \
  '{
    project: "WordPress",
    version: $version,
    provider: "wordpress.org",
    archive_url: $archive_url,
    archive_sha256: $archive_sha256,
    archive_content_md5: (if $archive_content_md5 == "" then null else $archive_content_md5 end),
    checksum_api: $checksum_api,
    verified_files: $verified_files,
    archive_last_modified: (if $last_modified == "" then null else $last_modified end),
    source_license: "GPL-2.0-or-later"
  }' > "$provenance.tmp"
mv "$provenance.tmp" "$provenance"

info "Verified $verified_count files against WordPress.org checksums"
printf '%s\n' "$source_dir"
