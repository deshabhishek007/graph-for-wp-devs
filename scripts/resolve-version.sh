#!/usr/bin/env bash

set -euo pipefail
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_command curl
require_command jq

requested="${1:-}"
[[ -n "$requested" ]] || die "usage: $0 <latest|VERSION>"
[[ $# -eq 1 ]] || die "usage: $0 <latest|VERSION>"

version_api="$WORDPRESS_API/version-check/1.7/?channel=stable"

if [[ "$requested" == "latest" ]]; then
  version="$(curl --fail --silent --show-error --location "$version_api" |
    jq -er '.offers[]
      | select(.response == "upgrade" and .locale == "en_US")
      | select(.version | test("^[0-9]+\\.[0-9]+(\\.[0-9]+)?$"))
      | .version' | head -n 1)" || die "could not resolve the latest stable release from $version_api"
  [[ -n "$version" ]] || die "WordPress.org returned no stable release"
  printf '%s\n' "$version"
  exit 0
fi

if [[ ! "$requested" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
  die "'$requested' is not a stable WordPress version (alpha, beta, RC, nightly, and trunk builds are excluded)"
fi

checksums_url="$WORDPRESS_API/checksums/1.0/?version=${requested}&locale=en_US"
if ! checksum_count="$(curl --fail --silent --show-error --location "$checksums_url" |
  jq -er 'if .checksums and (.checksums | type == "object") then (.checksums | length) else 0 end')"; then
  die "WordPress $requested was not found in the official checksum service"
fi

if [[ "$checksum_count" -le 0 ]]; then
  die "WordPress $requested is not an official stable release with published checksums"
fi

archive_url="https://wordpress.org/wordpress-${requested}.tar.gz"
curl --fail --silent --show-error --location --head "$archive_url" >/dev/null ||
  die "official WordPress archive does not exist: $archive_url"

printf '%s\n' "$requested"

