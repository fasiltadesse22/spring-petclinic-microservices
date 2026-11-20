# PetClinic — Post-audit stabilization evidence V1

**Starting fork SHA:** `e8b747ab522721076cacb5cf688eb8a54ba8c5c9`.
**Stabilization PR:** https://github.com/fasiltadesse22/spring-petclinic-microservices/pull/1
**Independent React Academy:** https://github.com/fasiltadesse22/devops-platform-engineering-academy
**Date:** 2026-11-20. This is an engineering safety/reproducibility checkpoint, not Part 1.1.6.

## Source corrections and planned guarantees

- R01: broad `pkill -9 -f` and broad `docker rm --force` removed from the local scripts; explicit owned PID + start_ticks + JAR, pidfd exact target signaling and bounded TERM→KILL; no unsafe numeric PID fallback.
- R02: health-readiness timeout and early process exit return nonzero; logs retained; bounded cleanup only for owned records. Infrastructure opt-out and GenAI opt-in.
- R06: Config Server Git label defaults to immutable external config SHA `323993ce2519c6d02df63e08bf4458d123d3b611` in the local JVM launcher; code uses Java 17 and Spring Boot 4.0.1. The existing Docker Compose remains inherited and unpinned.
- R07: upstream-only gate for inherited `pull_request_target` auto-triage; existing Maven workflow retained; separate local process safety workflow added.
- R10/R11: comprehensive Docker security, Kubernetes and cloud work intentionally deferred.

## Verified actual checks (separate evidence categories)

1. **Source compile and tests:** [Maven CI run 44796524675](https://github.com/fasiltadesse22/spring-petclinic-microservices/actions/runs/44796524675) passed JDK 17 Maven reactor package and existing test suite with no test failures. Subsequent real-JVM smoke builds also completed successfully; the entire service suite has not been subjected to a production-like load test.
2. **Disposable process ownership:** [Process-safety run 44796524500](https://github.com/fasiltadesse22/spring-petclinic-microservices/actions/runs/44796524500) passed 6 separate Python owned-process tests and fake health workflows. Later [run 44800437868](https://github.com/fasiltadesse22/spring-petclinic-microservices/actions/runs/44800437868) also passed after adding unrecorded-child abort protections.
3. **Actual Config Server:** [Real runtime smoke run 44799610076](https://github.com/fasiltadesse22/spring-petclinic-microservices/actions/runs/44799610076) started the Java Config Server on loopback 18888, obtained successful `/actuator/health` and config endpoint responses and terminated its owned PID. [Run 44800424835](https://github.com/fasiltadesse22/spring-petclinic-microservices/actions/runs/44800424835) additionally reported an **exact matching external configuration revision** (not merely HTTP 200).
4. **Actual Gateway → Customers:** [Real Gateway run 44800159099](https://github.com/fasiltadesse22/spring-petclinic-microservices/actions/runs/44800159099) started 7 actual JVM apps, observed health, and after several expected discovery-convergence HTTP 503 responses, obtained a successful Gateway GET `/api/customer/owners` with JSON-array response. All seven owned PIDs were then stopped, without generic process-name killing.
5. **Cold-start timing boundary:** [Run 44800424835](https://github.com/fasiltadesse22/spring-petclinic-microservices/actions/runs/44800424835) FAILED its Gateway stage because Customers JPA/Hikari startup had not completed within the **35-second** probe deadline; readiness correctly failed and cleanup targeted only owned JVM PIDs. This is not proof of a business logic defect. The bounded smoke deadline was subsequently adjusted to 90 seconds; treat further results by their actual CI statuses.

## Evidence limitations

- Real HTTP smoke confirms **that specific** Config Server and Gateway→Customers transaction on a GitHub runner, not broad production service correctness.
- The Java tests, fake readiness tests and real smoke checks are distinct evidence. No paid AI API, AWS, EKS, Kubernetes, shared database, or production workload was executed.
- Docker Compose configuration and container runtime itself were not verified during the above real-JVM smoke (which used `--no-infra`), so image identity, container PID 1 and container shutdown behavior remain source-only.
- Branch protection API was not inspectable; do not claim a protected main or enforced PR requirement. Original upstream auto-triage was designed for upstream and is only constrained in the fork.
- The external Config Git revision was checked by the Config Server environment response in a verified run, not inferred solely from a launcher environment variable.
- Additional scope: process-state identity and pidfd availability are Linux-specific; no macOS behavior is claimed.
- No PetClinic domain/business modules or authored Academy manuscripts were changed for these safety corrections.

## Checkpoint update

Final feature/merge SHAs, post-merge CI and readiness verdict are recorded after green gates and actual merges. Part 1.1.6 (systemd) remains planned.
