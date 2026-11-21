# Current state and session recovery — PetClinic engineering platform

> Course-specific navigation for the independently maintained [DevOps Academy](https://github.com/fasiltadesse22/devops-platform-engineering-academy). This file is **not** a replacement for the upstream PetClinic README, source, or deployment documentation.

## Source-of-truth startup

1. Resolve fresh `main` SHAs for this fork and the Academy. Do not treat the original upstream baseline as current main.
2. Read the [Academy progress ledger](https://github.com/fasiltadesse22/devops-platform-engineering-academy/blob/main/docs/progress/PROGRESS_LEDGER.md), exact roadmap/blueprint part and [dual-repository contract](https://github.com/fasiltadesse22/devops-platform-engineering-academy/blob/main/docs/contracts/DUAL_REPOSITORY_EXECUTION_CONTRACT_V1.md).
3. Inspect the relevant live source (`pom.xml`, service modules, `scripts/`, `docker-compose.yml`, `.github/workflows/`) and the [stabilization evidence](../stabilization/STABILIZATION_EVIDENCE_V1.md). Expand history only for relevant dependencies.
4. Before code changes, report current SHAs, proposed scope and exclusions, preserved invariants, actual evidence and test plan. If documentation and implementation disagree, report the contradiction.

## Current verified vs unverified boundaries

The fork inherits Customers, Vets, Visits, API Gateway, Config Server, Eureka Discovery, optional GenAI, Docker Compose and observability assets from the upstream project. Their presence is **not** proof that this course engineered or exercised them.

The 2026-11-20 [PetClinic stabilization PR #1](https://github.com/fasiltadesse22/spring-petclinic-microservices/pull/1) improved owned-process targeting, readiness failure behavior and local script safety. Recorded [Maven CI](https://github.com/fasiltadesse22/spring-petclinic-microservices/actions/runs/44801760603) and [process safety CI](https://github.com/fasiltadesse22/spring-petclinic-microservices/actions/runs/44801761397) passed. The [bounded JVM smoke](https://github.com/fasiltadesse22/spring-petclinic-microservices/actions/runs/44800925965) recorded real Config Server external configuration revision, locally started JVM services and a Gateway→Customers HTTP transaction. These are specific CI observations, not universal availability claims.

**Still unverified:** real Docker Compose/container PID1 runtime, systemd restart semantics, production graceful request drain, full load/security properties and Kubernetes/AWS runtime. Prior lesson Linux companion labs are not PetClinic runtime evidence. Branch protection enforcement was not independently inspectable in the previous checkpoint.

## Architecture, provenance and change policy

- Preserve upstream attribution and the existing owner/pet/vet/visit domain flows.
- No speculative service addition or unrelated Java/domain changes to satisfy a conceptual lesson.
- Preserve independent Git histories; use immutable links to Academy lesson evidence. No cross-repository runtime dependency.
- [Execution contract](https://github.com/fasiltadesse22/devops-platform-engineering-academy/blob/main/docs/contracts/DUAL_REPOSITORY_EXECUTION_CONTRACT_V1.md) governs existing architectural rules; introduce ADRs only for new consequential decisions not already established there.
- `docs/stabilization/STABILIZATION_EVIDENCE_V1.md` is a dated historical checkpoint; later successful or failed runs get a new attributable record, never silent retroactive edits.

## Mandatory completion freeze

Prior to an independently scoped PR: preserve tests and process-safety gates, document exact verification environment and commands, distinguish source-inspected/build-verified/runtime-verified/blocked and clean only owned resources. After actual merge: verify the final main SHA and link the result in the Academy's new lesson checkpoint if applicable. Avoid circular requirements for pre-merge future SHAs.
