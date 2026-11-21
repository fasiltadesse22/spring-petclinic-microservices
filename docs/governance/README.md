# Course continuity and architecture authority

The [current-state recovery entry](CURRENT_STATE.md) is the new-session entry point for this fork, not a replacement for the existing upstream README or source. The [2026-11-20 stabilization evidence](../stabilization/STABILIZATION_EVIDENCE_V1.md) is a historical record with precise bounded CI results.

The current source and configurations determine implemented reality. The Academy roadmap and blueprint determine curriculum scope. Actual recorded experiment and CI evidence determine verification maturity. The [dual-repository contract](https://github.com/fasiltadesse22/devops-platform-engineering-academy/blob/main/docs/contracts/DUAL_REPOSITORY_EXECUTION_CONTRACT_V1.md) owns existing architecture invariants. Do not add an ADR unless a new significant decision actually requires one; if so, record its motivation, alternatives, impact, evidence, and supersession.

For any next part, first inspect fresh main SHAs and the Academy ledger and blueprint, then immediate predecessor, affected PetClinic source, relevant tests and evidence. Avoid reading whole history unless a concrete dependency demands it. Before implementation write an explicit scope and exclusions report. At finish verify tests and runtime claims, use an independent PR, check actual merge status, then record final main SHA in a dated Academy progress checkpoint. Historical evidence must not be retroactively promoted.

Run `python3 scripts/test_governance.py` to verify essential local continuity paths and classification wording. This static check does **not** verify external CI success, runtime behavior, architecture quality, or current GitHub settings.
