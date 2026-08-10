# Security policy

Please report vulnerabilities privately through the repository host's security-advisory feature rather than a public issue. Include affected scripts or pack versions, impact, reproduction steps, and any suggested mitigation.

Only official HTTPS WordPress sources are accepted. The downloader rejects unsafe archive paths, validates the archive Content-MD5 when WordPress supplies it, and checks extracted core files against WordPress.org's checksum service. Packs are additionally protected by SHA-256 checksums and schema validation.

Graph output is static analysis data and must not be treated as trusted executable code or proof of runtime behavior.

