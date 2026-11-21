# Distributed version of the Spring PetClinic Sample Application built with Spring Cloud and Spring AI

> **DevOps course fork:** To resume AI-assisted engineering, use [course current state and evidence classification](docs/governance/CURRENT_STATE.md). This README largely describes upstream-inherited capabilities; do not mistake them for capabilities independently verified by this course. The 2026-11-20 [stabilization evidence](docs/stabilization/STABILIZATION_EVIDENCE_V1.md) records a bounded real-JVM smoke but not systemd, container PID1, production graceful drain or cloud deployment.


[![Build Status](https://github.com/spring-petclinic/spring-petclinic-microservices/actions/workflows/maven-build.yml/badge.svg)](https://github.com/spring-petclinic/spring-petclinic-microservices/actions/workflows/maven-build.yml)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

This project demonstrates how to split the classic Spring PetClinic sample application into **[microservices](http://www.martinfowler.com/articles/microservices.html)**, with a **Vue.js frontend** and a Spring AI-powered chatbot.
To achieve that goal, it relies on Spring Boot, **Spring Cloud Gateway**, **Spring Cloud Circuit Breaker** with Resilience4j, **Spring Cloud Config**, Micrometer Tracing with Zipkin, Prometheus and Grafana for monitoring, 
Spring Boot Admin, Chaos Monkey for Spring Boot,  and the Eureka Service Discovery from the [Spring Cloud Netflix](https://github.com/spring-cloud/spring-cloud-netflix) technology stack.

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/spring-petclinic/spring-petclinic-microservices)

[![Open in Codeanywhere](https://codeanywhere.com/img/open-in-codeanywhere-btn.svg)](https://app.codeanywhere.com/#https://github.com/spring-petclinic/spring-petclinic-microservices)

## Starting services locally without Docker

Every microservice is a Spring Boot application and can be started locally using IDE or `../mvnw spring-boot:run` command.
Please note that supporting services (Config and Discovery Server) must be started before any other application (Customers, Vets, Visits and API).
Startup of Tracing server, Admin server, Grafana and Prometheus is optional.
If everything goes well, you can access the following services at given location:
* Discovery Server - http://localhost:8761
* Config Server - http://localhost:8888
* Vue.js frontend (API Gateway) - http://localhost:8080
* Customers, Vets, Visits and GenAI Services - random port, check Eureka Dashboard 
* Tracing Server (Zipkin) - http://localhost:9411/zipkin/ (we use [openzipkin](https://github.com/openzipkin/zipkin/tree/main/zipkin-server))
* Admin Server (Spring Boot Admin) - http://localhost:9090
* Grafana Dashboards - http://localhost:3030
* Prometheus - http://localhost:9091

You can tell Config Server to use your local Git repository by using `native` Spring profile and setting
`GIT_REPO` environment variable, for example:
`-Dspring.profiles.active=native -DGIT_REPO=/projects/spring-petclinic-microservices-config`

## Starting services locally with docker-compose
In order to start entire infrastructure using Docker, you have to build images by executing
``bash
./mvnw clean install -P buildDocker
``
This requires `Docker` or `Docker desktop` to be installed and running.

Alternatively you can also build all the images on `Podman`, which requires Podman or Podman Desktop to be installed and running.
```bash
./mvnw clean install -PbuildDocker -Dcontainer.executable=podman
```
By default, the Docker OCI image is build for an `linux/amd64` platform.
For other architectures, you could change it by using the `-Dcontainer.platform` maven command line argument.
For instance, if you target container images for an Apple M2, you could use the command line with the `linux/arm64` architecture:
```bash
./mvnw clean install -P buildDocker -Dcontainer.platform="linux/arm64"
```

Once images are ready, you can start them with a single command
`docker compose up` or `podman-compose up`. 

Containers startup order is coordinated with the `service_healthy` condition of the Docker Compose [depends-on](https://github.com/compose-spec/compose-spec/blob/main/spec.md#depends_on) expression 
and the [healthcheck](https://github.com/compose-spec/compose-spec/blob/main/spec.md#healthcheck) of the service containers. 
After starting services, it takes a while for API Gateway to be in sync with service registry,
so don't be scared of initial Spring Cloud Gateway timeouts. You can track services availability using Eureka dashboard
available by default at http://localhost:8761.

The `main` branch uses an Eclipse Temurin with Java 17 as Docker base image.

*NOTE: Under MacOSX or Windows, make sure that the Docker VM has enough memory to run the microservices. The default settings
are usually not enough and make the `docker-compose up` painfully slow.*


## Starting services locally with docker-compose and Java
If you experience issues with running the system via docker-compose you can try running the `./scripts/run_all.sh` script that will start the infrastructure 
services via `docker compose` and all the Java based applications via standard `nohup java -jar ...` command.
The logs will be available under `${ROOT}/target/nameoftheapp.log`.

By default the applications are started without the `chaos-monkey` profile. Pass the optional `--chaos-monkey` flag to enable it and interact with Spring Boot Chaos Monkey:
```bash
./scripts/run_all.sh --chaos-monkey
```
You can check out the [README](scripts/chaos/README.md) for more information about how to use the `./scripts/chaos/call_chaos.sh` helper script to enable assaults.

Use `./scripts/stop_all.sh` to stop all the Java applications and the docker-compose infrastructure containers started by `run_all.sh`.

## Understanding the Spring Petclinic application

[See the presentation of the Spring Petclinic Framework version](http://fr.slideshare.net/AntoineRey/spring-framework-petclinic-sample-application)

[A blog post introducing the Spring Petclinic Microsevices](http://javaetmoi.com/2018/10/architecture-microservices-avec-spring-cloud/) (french language)

You can then access petclinic here: http://localhost:8080/

## Microservices Overview

This project consists of several microservices:
- **Customers Service**: Manages customer data.
- **Vets Service**: Handles information about veterinarians.
- **Visits Service**: Manages pet visit records.
- **GenAI Service**: Provides a chatbot interface to the application.
- **API Gateway**: Routes client requests to the appropriate services.
- **Config Server**: Centralized configuration management for all services.
- **Discovery Server**: Eureka-based service registry.

Each service has its own specific role and communicates via REST APIs.


![Spring Petclinic Microservices screenshot](docs/application-screenshot.png)


**Architecture diagram of the Spring Petclinic Microservices**

![Spring Petclinic Microservices architecture](docs/microservices-architecture-diagram.jpg)

## Integrating the Spring AI Chatbot

Spring Petclinic integrates a Chatbot that allows you to interact with the application in a natural language. Here are some examples of what you could ask:

1. Please list the owners that come to the clinic.
2. Are there any vets that specialize in surgery?
3. Is there an owner named Betty?
4. Which owners have dogs?
5. Add a dog for Betty. Its name is Moopsie.
6. Create a new owner.

![Screenshot of the chat dialog](docs/spring-ai.png)

This `spring-petclinic-genai-service` microservice currently supports **OpenAI** (default) or **Azure's OpenAI** as the LLM provider.
In order to start the microservice, perform the following steps:

1. Decide which provider you want to use. By default, the `spring-ai-starter-model-openai` dependency is enabled. 
   You can change it to `spring-ai-starter-model-azure-openai`in the `pom.xml`.
2. Create an OpenAI API key or an Azure OpenAI resource in your Azure Portal.
   Refer to the [OpenAI's quickstart](https://platform.openai.com/docs/quickstart) or [Azure's documentation](https://learn.microsoft.com/en-us/azure/ai-services/openai/) for further information on how to obtain these.
   You only need to populate the provider you're using - either openai, or azure-openai.
   If you don't have your own OpenAI API key, don't worry!
   You can temporarily use the `demo` key, which OpenAI provides free of charge for demonstration purposes.
   This `demo` key has a quota, is limited to the `gpt-4o-mini` model, and is intended solely for demonstration use.
   With your own OpenAI account, you can test the `gpt-4o` model by modifying the `deployment-name` property of the `application.yml` file.
3. Export your API keys and endpoint as environment variables:
    * either OpenAI:
    ```bash
    export OPENAI_API_KEY="your_api_key_here"
    ```
    * or Azure OpenAI:
    ```bash
    export AZURE_OPENAI_ENDPOINT="https://your_resource.openai.azure.com"
    export AZURE_OPENAI_KEY="your_api_key_here"
    ```

## In case you find a bug/suggested improvement for Spring Petclinic Microservices

Our issue tracker is available here: https://github.com/spring-petclinic/spring-petclinic-microservices/issues

## Database configuration

In its default configuration, Petclinic uses an in-memory database (HSQLDB) which gets populated at startup with data.
A similar setup is provided for MySql in case a persistent database configuration is needed.
Dependency for Connector/J, the MySQL JDBC driver is already included in the `pom.xml` files.

### Start a MySql database

You may start a MySql database with docker:

```
docker run -e MYSQL_ROOT_PASSWORD=petclinic -e MYSQL_DATABASE=petclinic -p 3306:3306 mysql:8.4.5
```
or download and install the MySQL database (e.g., MySQL Community Server 8.4.5 LTS), which can be found here: https://dev.mysql.com/downloads/

### Use the Spring 'mysql' profile

To use a MySQL database, you have to start 3 microservices (`visits-service`, `customers-service` and `vets-services`)
with the `mysql` Spring profile. Add the `--spring.profiles.active=mysql` as program argument.

By default, at startup, database schema will be created and data will be populated.
You may also manually create the PetClinic database and data by executing the `"db/mysql/{schema,data}.sql"` scripts of each 3 microservices. 
In the `application.yml` of the [Configuration repository], set the `initialization-mode` to `never`.

If you are running the microservices with Docker, you have to add the `mysql` profile into the [Dockerfile](docker/Dockerfile):
```
ENV SPRING_PROFILES_ACTIVE docker,mysql
```
In the `mysql section` of the `application.yml` from the [Configuration repository], you have to change 
the host and port of your MySQL JDBC connection string. 

## Custom metrics monitoring

Grafana and Prometheus are included in the `docker-compose.yml` configuration, and the public facing applications
have been instrumented with [MicroMeter](https://micrometer.io) to collect JVM and custom business metrics.

A JMeter load testing script is available to stress the application and generate metrics: [petclinic_test_plan.jmx](spring-petclinic-api-gateway/src/test/jmeter/petclinic_test_plan.jmx)

![Grafana metrics dashboard](docs/grafana-custom-metrics-dashboard.png)

### Using Prometheus

* Prometheus can be accessed from your local machine at http://localhost:9091

### Using Grafana with Prometheus

* An anonymous access and a Prometheus datasource are setup.
* A `Spring Petclinic Metrics` Dashboard is available at the URL http://localhost:3030/d/69JXeR0iw/spring-petclinic-metrics.
You will find the JSON configuration file here: [docker/grafana/dashboards/grafana-petclinic-dashboard.json]().
* You may create your own dashboard or import the [Micrometer/SpringBoot dashboard](https://grafana.com/dashboards/4701) via the Import Dashboard menu item.
The id for this dashboard is `4701`.

### Custom metrics
Spring Boot registers a lot number of core metrics: JVM, CPU, Tomcat, Logback... 
The Spring Boot auto-configuration enables the instrumentation of requests handled by Spring MVC.
All those three REST controllers `OwnerResource`, `PetResource` and `VisitResource` have been instrumented by the `@Timed` Micrometer annotation at class level.

* `customers-service` application has the following custom metrics enabled:
  * @Timed: `petclinic.owner`
  * @Timed: `petclinic.pet`
* `visits-service` application has the following custom metrics enabled:
  * @Timed: `petclinic.visit`

## Looking for something in particular?

| Spring Cloud components         | Resources  |
|---------------------------------|------------|
| Configuration server            | [Config server properties](spring-petclinic-config-server/src/main/resources/application.yml) and [Configuration repository] |
| Service Discovery               | [Eureka server](spring-petclinic-discovery-server) and [Service discovery client](spring-petclinic-vets-service/src/main/java/org/springframework/samples/petclinic/vets/VetsServiceApplication.java) |
| API Gateway                     | [Spring Cloud Gateway starter](spring-petclinic-api-gateway/pom.xml) and [Routing configuration](/spring-petclinic-api-gateway/src/main/resources/application.yml) |
| Docker Compose                  | [Spring Boot with Docker guide](https://spring.io/guides/gs/spring-boot-docker/) and [docker-compose file](docker-compose.yml) |
| Circuit Breaker                 | [Resilience4j fallback method](spring-petclinic-api-gateway/src/main/java/org/springframework/samples/petclinic/api/boundary/web/ApiGatewayController.java)  |
| Grafana / Prometheus Monitoring | [Micrometer implementation](https://micrometer.io/), [Spring Boot Actuator Production Ready Metrics] |

| Front-end module   | Files                                                                                                                                                                                                 |
|--------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Maven build        | [Maven dependencies for Vue, Vue Router, Bootstrap, DOMPurify, and Marked](spring-petclinic-api-gateway/pom.xml). Maven packages the frontend; no Node.js, NPM, or maven-frontend-plugin is required. |
| Vue JS             | [Standalone Vue modules](spring-petclinic-api-gateway/src/main/resources/static/scripts/main.js) use runtime templates and native browser imports in no-build mode.                                    |
| Vue Router         | [Client-side routes](spring-petclinic-api-gateway/src/main/resources/static/scripts/router.js) use browser history for all application screens.                                                        |
| Static entry point | [HTML host page](spring-petclinic-api-gateway/src/main/resources/static/index.html) mounts the Vue application and loads local WebJar assets.                                                         |

## Pushing to a Docker registry

Docker images for `linux/amd64` and `linux/arm64` platforms have been published into DockerHub 
in the [springcommunity](https://hub.docker.com/u/springcommunity) organization.
You can pull an image:
```bash
docker pull springcommunity/spring-petclinic-config-server
```
You may prefer to build then push images to your own Docker registry.

### Choose your Docker registry

You need to define your target Docker registry.
Make sure you're already logged in by running `docker login <endpoint>` or `docker login` if you're just targeting Docker hub.

Setup the `REPOSITORY_PREFIX` env variable to target your Docker registry.
If you're targeting Docker hub, simple provide your username, for example:
```bash
export REPOSITORY_PREFIX=springcommunity
```

For other Docker registries, provide the full URL to your repository, for example:
```bash
export REPOSITORY_PREFIX=harbor.myregistry.com/petclinic
```

To push Docker image for the `linux/amd64` and the `linux/arm64` platform to your own registry, please use the command line:
```bash
mvn clean install -Dmaven.test.skip -P buildDocker -Ddocker.image.prefix=${REPOSITORY_PREFIX} -Dcontainer.build.extraarg="--push" -Dcontainer.platform="linux/amd64,linux/arm64"
```

The `scripts/pushImages.sh` and `scripts/tagImages.sh` shell scripts could also be used once you build your image with the `buildDocker` maven profile.
The `scripts/tagImages.sh` requires to declare the `VERSION` env variable.

## Compiling the CSS

There is a `petclinic.css` in `spring-petclinic-api-gateway/src/main/resources/static/css`.
It was generated from the `petclinic.scss` source, combined with the [Bootstrap](https://getbootstrap.com/) library.
If you make changes to the `scss`, or upgrade Bootstrap, you will need to re-compile the CSS resources
using the Maven profile `css` of the `spring-petclinic-api-gateway`module.
```bash
cd spring-petclinic-api-gateway
mvn generate-resources -P css
```

## Interesting Spring Petclinic forks

The Spring Petclinic `main` branch in the main [spring-projects](https://github.com/spring-projects/spring-petclinic)
GitHub org is the "canonical" implementation, currently based on Spring Boot and Thymeleaf.

This [spring-petclinic-microservices](https://github.com/spring-petclinic/spring-petclinic-microservices/) project is one of the [several forks](https://spring-petclinic.github.io/docs/forks.html) 
hosted in a special GitHub org: [spring-petclinic](https://github.com/spring-petclinic).
If you have a special interest in a different technology stack
that could be used to implement the Pet Clinic then please join the community there.


## Contributing

The [issue tracker](https://github.com/spring-petclinic/spring-petclinic-microservices/issues) is the preferred channel for bug reports, features requests and submitting pull requests.

For pull requests, editor preferences are available in the [editor config](.editorconfig) for easy use in common text editors. Read more and download plugins at <http://editorconfig.org>.


[Configuration repository]: https://github.com/spring-petclinic/spring-petclinic-microservices-config
[Spring Boot Actuator Production Ready Metrics]: https://docs.spring.io/spring-boot/docs/current/reference/html/production-ready-metrics.html

## Supported by

[![JetBrains logo](https://resources.jetbrains.com/storage/products/company/brand/logos/jetbrains.svg)](https://jb.gg/OpenSourceSupport)

## DevOps Platform Engineering course-fork stabilization (November 2026)

This fork retains the original Java 17 / Spring Boot 4.0.1 multi-module business system. The course-specific local supervisor deliberately differs from upstream's historical convenience scripts.

- Build the exact checked-out source with `./mvnw -B package` before using the local launcher. The fork-specific Maven test workflow is recorded in [the stabilization evidence](docs/stabilization/STABILIZATION_EVIDENCE_V1.md).
- On a Linux host with Python 3 pidfd support, run `bash scripts/run_all.sh --no-infra` for local JVM mode, or omit `--no-infra` to start only the explicitly owned support containers. External Config Server is pinned by the `PETCLINIC_CONFIG_REF` environment variable, default `323993ce2519c6d02df63e08bf4458d123d3b611`. This does not change the upstream Docker Compose runtime configuration.
- The runner records each `-jar` child PID, `/proc` start ticks, and JAR identity in `target/local-supervisor/`. `bash scripts/stop_all.sh` sends SIGTERM, then a bounded SIGKILL only to the recorded process instance using a Linux pidfd. It does **not** use `pkill`, generic process-name matching, forceful container deletion, or unscoped Compose teardown. Stale identity records are treated as not-owned.
- Health polling checks the actual `/actuator/health` response and exits nonzero if the process dies or readiness times out; a successful launch does not equal a healthy service. `PETCLINIC_READINESS_TIMEOUT` controls the per-service deadline. Inspect `target/local-supervisor/*.log` on failure.
- The inherited GenAI service is **opt-in**, via `--with-genai` only. Chaos Monkey is likewise opt-in via `--chaos-monkey`. Neither is called by the baseline tests; do not configure paid API credentials merely to run the core platform.
- `python3 scripts/test_managed_process.py` validates exact process ownership against disposable, non-Java child processes; `bash scripts/test_safe_launcher.sh` validates simulated success, timeout and early exit. Both are distinct from a running Spring application.
- `bash scripts/smoke_config_server.sh` and `bash scripts/smoke_gateway.sh` are real-JVM smoke probes for an isolated, disposable Linux CI environment; they create loopback application processes and explicitly clean up. Gateway may initially return HTTP 503 until service registration converges. Review the evidence ledger for observed successes and failed cold-start deadlines before making deployment claims.
- The upstream PR auto-triage workflow is guarded to act only on `spring-petclinic/spring-petclinic-microservices`, not automatically close course-fork PRs.

**Scope and limitations:** The completed Maven CI and controlled real-JVM smoke do not prove Docker/Kubernetes production behavior, full request-draining semantics, PID-namespace init behavior, customer data durability, cloud readiness, or learner mastery. Docker Compose fixed `container_name` and floating upstream images remain inherited; a real Compose integration baseline is separate roadmap work. This course also maintains an **independent React academy repository**; no monorepo.

**Safety note:** `run_all.sh`/`stop_all.sh` are intentionally Linux-only and fail closed when pidfd support is unavailable. They are not a macOS process supervisor. Do not use them to manage unrelated processes or a shared production host.
