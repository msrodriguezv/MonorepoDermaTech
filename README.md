# Dermatech: Distributed Dermatological Management Ecosystem

**Status:** Active Development
**License:** Proprietary - Universidad Central del Ecuador (UCE)
**Department:** Faculty of Applied Sciences, Information Systems Program

## Project Overview

Dermatech is a comprehensive software ecosystem designed to optimize and automate dermatological triage and care workflows at the Health Center of the Universidad Central del Ecuador (UCE). Addressing the operational inefficiencies of traditional manual admission processes—such as service saturation, subjective patient prioritization, and disconnected referral workflows—Dermatech implements a "Digital First" approach to modernize the patient journey.

Unlike monolithic legacy systems, this solution adopts a Cloud-Native, distributed architecture utilizing microservices, event-driven communication patterns, and a hybrid deployment strategy. This design ensures scalability, data sovereignty, and cost efficiency suitable for an academic and public health environment.

## Objectives

* **Process Optimization:** Transform the patient experience from a physical, queue-based interaction to a digital workflow using AI-assisted pre-triage and encrypted QR code admission.
* **Architectural Resilience:** Implement a decoupled system using Event-Driven patterns and hybrid cloud infrastructure (AWS + On-Premise) to handle academic traffic spikes without service degradation.
* **Data Integrity and Sovereignty:** Guarantee the security and immutability of medical records through strict environment isolation (QA vs. Production) and automated on-premise replication tunnels.

## System Architecture

The system is built upon a **Microservices Architecture** comprising a minimum of 10 autonomous services, organized by business domains (Identity, Scheduling, Triage, Clinical) to strictly adhere to the Separation of Concerns principle.

### Infrastructure Diagram

The following diagram illustrates the Hybrid Cloud topology, featuring isolated AWS accounts for QA and Production (Multi-AZ), perimeter security via Cloudflare, and the secure VPN tunnel to the On-Premise University Server for data sovereignty.

![Infrastructure Diagram](docs/infrastructure_diagram.png)
*Figure 1: Infrastructure Architecture - Isolated Accounts (PROD Multi-AZ vs QA) and Hybrid Connectivity.*

### Architectural Patterns

* **Hybrid Cloud Strategy:** Core business logic resides on AWS ECS (Fargate Spot) to ensure high availability and scalability. [cite_start]Heavy persistence layers and static code analysis tools are offloaded to external PaaS providers and an on-premise university server to minimize operational costs[cite: 301, 302].
* **Event-Driven Communication:**
    * [cite_start]**Apache Kafka:** Utilized for high-throughput event streaming, specifically for processing massive QR scan ingestions without blocking the main thread[cite: 495].
    * [cite_start]**RabbitMQ:** Manages asynchronous background task queues, such as email notifications and push alerts, to decouple non-critical operations from user interactions[cite: 497].
* **CQRS (Command Query Responsibility Segregation):** The scheduling module separates read and write operations. [cite_start]Availability queries are resolved via high-speed Redis caches, while bookings are processed as transactional writes in PostgreSQL[cite: 906, 907].
* [cite_start]**Polyglot Persistence:** Adopting the "Right Tool for the Job" philosophy, the system avoids a monolithic database in favor of[cite: 616, 622]:
    * **PostgreSQL:** For relational, transactional data (Identity, Appointments).
    * **MongoDB:** For unstructured clinical documents and multimedia history.
    * **Redis:** For high-speed caching of availability slots and session management.

## Technology Stack

### Frontend (Unified Client)
* **Framework:** Flutter (Dart)
* **Strategy:** A single codebase compiles to three distinct platforms:
    * **Mobile (Android/iOS):** For Students (Patients) and Nurses.
    * **Desktop (Windows/Linux):** For Doctors (Dermatologists) requiring high-density data visualization.
    * [cite_start]**Web:** For Administrators managing audits and configurations[cite: 477, 478].

### Backend (Polyglot Microservices)
* [cite_start]**NestJS (Node.js):** The primary framework for core business logic services (Auth, Patient, Scheduling) selected for its modular architecture and strong typing[cite: 504].
* **Go (Golang):** Powering the dedicated `qr-ingest` service. [cite_start]Selected for its superior concurrency model to handle bursts of attendance requests with sub-200ms latency[cite: 501].
* [cite_start]**Python:** Hosting the Artificial Intelligence Agent, chosen to leverage native data science libraries for probabilistic symptom analysis and risk scoring[cite: 502].

### Infrastructure & DevOps
* **Containerization:** Docker & Docker Compose.
* [cite_start]**Orchestration:** AWS ECS (Elastic Container Service) using Fargate Spot instances[cite: 326].
* [cite_start]**IaC (Infrastructure as Code):** Terraform is used for modular and reproducible cloud resource provisioning[cite: 682].
* [cite_start]**CI/CD:** GitHub Actions orchestrates automated testing and deployment pipelines[cite: 723].
* [cite_start]**Security:** Cloudflare serves as the perimeter WAF, while Nginx acts as the internal API Gateway[cite: 317, 507].

## Functional Modules

### 1. Patient Module (Mobile App)
* [cite_start]**AI-Assisted Pre-Triage:** A wizard interface collects symptom data, which is processed by the AI agent to assign a preliminary, invisible priority level[cite: 83].
* **Smart Scheduling:** Users can query real-time availability. [cite_start]The system uses Redis locking to prevent double-booking during high-traffic periods[cite: 147].
* [cite_start]**Digital Admission:** Upon booking, the system generates an encrypted QR code containing appointment metadata for rapid physical validation[cite: 86].

### 2. Nursing & Triage Module (Mobile/Tablet App)
* [cite_start]**High-Speed Ingestion:** The module features a dedicated QR scanning interface capable of processing admissions with minimal latency via the Go microservice[cite: 88].
* **Human-in-the-Loop Validation:** Nurses review the AI-suggested priority and vital signs. [cite_start]The system enforces human authority, allowing nurses to confirm or override the algorithmic classification before queuing the patient[cite: 90].

### 3. Clinical Module (Desktop App)
* [cite_start]**Medical Management:** A specialized desktop interface allows dermatologists to document diagnoses and issue prescriptions efficiently[cite: 93].
* [cite_start]**Multimedia Support:** The system supports the upload and storage of dermatological imagery directly into the MongoDB clinical record[cite: 94].
* [cite_start]**Referral Management:** Automated generation of PDF referral sheets for external partners when internal resolution is not possible[cite: 95].

### 4. Administrative Module (Web Portal)
* [cite_start]**Audit & Analytics:** Administrators have access to dashboards for monitoring service metrics and reviewing immutable audit logs to ensure legal traceability[cite: 98].

## Project Structure

[cite_start]The repository follows a **Monorepo** strategy managed by Nx Workspace to ensure code cohesion, atomic refactoring, and unified dependency management across the frontend and backend[cite: 672, 673].

```text
dermatech-monorepo/
├── apps/
│   ├── client/
│   │   └── dermatech-app/      # Unified Flutter frontend (Mobile/Desktop/Web)
│   └── services/               # Polyglot Backend Services
│       ├── auth-service/       # NestJS (Hexagonal Architecture)
│       ├── availability-qry/   # NestJS (CQRS Read Model)
│       ├── appointment-cmd/    # NestJS (CQRS Write Model)
│       ├── qr-ingest/          # Go (Event-Driven Producer)
│       ├── ai-agent/           # Python (Service-Oriented AI)
│       ├── triage-core/        # NestJS (Rules Engine)
│       ├── history-service/    # NestJS (Document-Oriented)
│       └── ...
├── libs/                       # Shared libraries (DTOs, Contracts, Validators)
├── infrastructure/             # Terraform modules for AWS/On-Premise
│   ├── modules/
│   └── environments/
└── .github/workflows/          # CI/CD Pipelinesgit 