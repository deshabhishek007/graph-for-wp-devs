# Contributing

Contributions to scripts, schemas, documentation, tests, and versioned packs are welcome.

1. Install the prerequisites listed in `README.md`.
2. Build the affected pack with `./scripts/build-pack.sh <VERSION>`.
3. Verify it with `./scripts/verify-pack.sh <VERSION>`.
4. Query representative WordPress symbols and review `TEST_RESULTS.md`.
5. Keep downloaded archives and WordPress source out of Git.

Do not add plugins, themes, WooCommerce, embeddings, vector stores, hosted services, or LLM-specific graph copies to a core-pack change. Generated packs must come from an unmodified official stable WordPress archive and record complete provenance.

For reproducibility comparisons, pin the same Graphify version and set the same `SOURCE_DATE_EPOCH`. Explain any graph checksum difference in the pull request.

