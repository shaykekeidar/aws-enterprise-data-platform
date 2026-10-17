AWS Enterprise Data Platform
Terraform infrastructure proof of concept (POC) | Multi-account AWS data-platform architecture
This repository accompanies an architecture and implementation assignment for a shared AWS data platform serving three offices (Office A, Office B, and Office C). It demonstrates infrastructure-as-code patterns for a centrally governed data lake, AWS account separation, identity and encryption controls, and deployment workflows.
> **Scope and evidence:** This repository is primarily an **AWS infrastructure / platform-engineering POC**, not a verified end-to-end production data platform. A portion of the Central Platform **DEV** infrastructure was deployed and inspected. Other workflows are represented by code, Terraform configurations, proposed architecture, or test plans. The status matrix below distinguishes these cases. **PROD was not deployed.**
1. Architecture
Account and governance model
The target design uses AWS Organizations with separate organizational units (OUs) and accounts. This is the proposed enterprise structure, not a claim that every account was provisioned during the POC.
OU / Scope	Proposed accounts	Purpose
Management	Management / payer	Consolidated billing and organization governance
DEV	Office A DEV, Office B DEV, Office C DEV, Central Platform DEV	Development and validation isolation
PROD	Office A PROD, Office B PROD, Office C PROD, Central Platform PROD	Production workload isolation
Security	Security / Audit, Log Archive	Central security oversight and log retention
Total target model: 11 AWS accounts. AWS Organizations guardrails, service control policies (SCPs), and Landing Zone processes are part of the target design; do not interpret them as an implemented Control Tower deployment.
Conceptual data flow
```text
Office A (browser)
  -> API Gateway + authenticated presigned-URL flow [proposed integration]
  -> Central S3: incoming/office-a/
  -> CSV validation Lambda [source code; end-to-end trigger not verified]
       valid   -> raw/office-a/
       invalid -> quarantine/office-a/
  -> Glue ETL [planned] -> curated/office_id=office-a/

Office B (external API)
  -> scheduled ingestion Lambda + OAuth2 client credentials [planned]
  -> Central S3: incoming/office-b/
  -> Glue ETL [planned] -> curated/office_id=office-b/

Office C (existing RDS)
  -> weekly RDS snapshot / snapshot export [planned]
  -> Office C private staging S3 [planned]
  -> Office C Glue ETL: mask PII before cross-account transfer [planned]
  -> Central S3: incoming/office-c/
  -> Central curated datasets [planned]

Central analytics
  -> Glue Data Catalog / Athena [target design]
  -> QuickSight + office-level row-level security (RLS) [target design]
```
Security boundary: Unmasked Office C data remains in the Office C account. Only approved, masked output is intended to cross into the Central Platform account. Cross-account access requires both appropriate identity permissions and resource policies (including relevant KMS permissions).
Central data lake layout
```text
s3://<central-data-lake-bucket>/
  incoming/
    office-a/
    office-b/
    office-c/
  raw/
    office-a/
  curated/
    office_id=office-a/
    office_id=office-b/
    office_id=office-c/
  quarantine/
    office-a/
  archive/
  temporary/
```
Prefixes illustrate the target logical design; their presence in a configuration does not establish that data has flowed through them.
2. Implemented vs. planned
Component	Status	Evidence / qualification
Central Platform DEV Terraform resources	Partially deployed	A previous DEV inspection returned 17 Terraform-managed resource addresses via `terraform state list`. This is not evidence that all target services were deployed.
Central DEV S3 remote Terraform backend	Verified	S3 backend metadata and the remote DEV state object were inspected.
Terraform S3 data-lake configuration	Implemented as IaC	Bucket/privacy/encryption/versioning and related configuration are represented in Terraform; individual controls should be checked against current AWS state before claiming runtime verification.
Office C cross-account IAM configuration	Terraform validated	A successful Terraform validation does not prove an actual cross-account data transfer or KMS operation.
Office A CSV validator	Python source available	Includes proposed validation, 10 MiB maximum object-size rule, and quarantine flow. S3-triggered integration and negative-path execution have not been verified end to end.
Office A API authentication and browser upload	Designed / partial source	The complete authenticated presigned-URL flow has not been verified end to end.
Office B external API ingestion	Planned	Scheduled OAuth2 ingestion has not been demonstrated end to end.
Office C snapshot export, masking and publication	Planned	Weekly snapshot/export/Glue/transfer orchestration has not been demonstrated end to end.
Glue transformations and curated datasets	Target design	Do not assume successful ETL jobs or populated curated datasets.
Athena / QuickSight / office RLS	Target design	Dashboard and access-control behavior have not been demonstrated in a deployed QuickSight environment.
GitHub Actions CI/CD	Workflow definitions / proposed controls	Workflow files do not by themselves prove successful, authorized cloud deployments or a working production approval gate.
Production infrastructure	Not deployed	PROD is an architectural/configuration target only; no PROD `terraform apply` is claimed.
Interpretation of status terms:
Verified: A specific command or AWS artifact was inspected.
Terraform validated: Configuration passed static validation at a point in time; cloud behavior is not thereby tested.
Implemented as IaC / source available: Source files exist, but runtime deployment or integration may be incomplete.
Planned / target design: Described architecture, not an execution claim.
3. Repository structure
The following paths identify the principal areas of the POC. Consult the checked-out repository for its exact current file inventory.
```text
aws-enterprise-data-platform/
├── environments/
│   ├── dev/
│   │   ├── central-platform/     # DEV Terraform root and backend
│   │   └── office-c/             # Office C DEV IAM configuration
│   └── prod/                     # Production-oriented configuration (not applied)
├── modules/
│   ├── central-platform/         # Shared platform resources and KMS/IAM
│   ├── s3-data-lake/             # S3 bucket, policies and lifecycle configuration
│   └── iam-ingestion/            # Ingestion-related IAM resources
├── lambda/
│   ├── csv-validator/            # Office A validation logic
│   └── presigned-url/            # Office A presigned upload logic
├── tests/                        # Test definitions, where present
└── .github/workflows/            # Terraform automation definitions
```
4. Prerequisites
AWS account/profile with authorization to inspect or create the relevant DEV resources.
AWS CLI v2, authenticated using an approved identity method (for example, an AWS CLI profile or AWS IAM Identity Center).
Terraform CLI compatible with the repository's configured provider and version constraints.
Python 3 and `pytest` if running Python tests.
Git and, on Windows, PowerShell for the example commands.
Existing remote-state backend infrastructure, or a separately approved backend bootstrap procedure.
Correct values for environment-specific Terraform variables and any cross-account role ARNs.
Do not commit AWS access keys, secrets, state files, sensitive Terraform plans, or plaintext credentials. GitHub authentication to AWS should use OIDC-based role assumption and temporary STS credentials, subject to approved trust policies and permissions.
5. Inspect and validate DEV
Run the following from PowerShell. These commands inspect and validate configuration; they do not deploy resources.
```powershell
git clone https://github.com/shaykekeidar/aws-enterprise-data-platform.git
cd aws-enterprise-data-platform

aws sts get-caller-identity

cd environments/dev/central-platform
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan
terraform state list
```
Important:
`terraform init` requires access to the configured S3 state backend and provider installation.
`terraform plan` evaluates the current account, variables and permissions and can show changes; a clean plan is not guaranteed.
`terraform state list` shows addresses managed by the selected Terraform state, not a live compliance or integration-test result.
Cross-account examples may require the other account's IAM role ARNs and matching S3 bucket/KMS resource policies before they become operational.
Optional Python checks
From the repository root:
```powershell
python -m compileall lambda
python -m pytest tests -v
```
These are commands to run, not a claim that the latest code passed them. `compileall` checks Python syntax, not AWS behavior; pytest coverage depends on the actual test cases present. Review the exit codes before reporting results.
Apply (intentional DEV action only)
Only if you are authorized, have confirmed the selected account/state/region, reviewed the plan and understood cost implications:
```powershell
cd environments/dev/central-platform
terraform plan -out=dev.tfplan
terraform apply dev.tfplan
```
Terraform plan files can contain sensitive values. Protect and remove local plan artifacts according to your organization's retention policy. Never run these commands against PROD as a substitute for an approved production workflow.
6. Evidence and verification boundaries
The following evidence was observed during development of the assignment:
DEV S3 remote state: An S3 object was found at `s3://enterprise-data-platform-tfstate-057461015409/dev/central-platform/terraform.tfstate`.
Backend configuration: Terraform backend metadata identified an S3 backend using the DEV key `dev/central-platform/terraform.tfstate`.
Terraform-managed resource inventory: `terraform state list` returned 17 resource addresses at the time of inspection.
Office C IAM Terraform: DEV configuration validation was reported; no successful end-to-end Office C export or cross-account transfer is claimed.
These observations are historical snapshots and should be rechecked against the currently selected AWS account. They do not verify every service, S3 data path, Lambda trigger, IAM permission, encryption condition, or CI/CD workflow.
Evidence to capture before submission, if available
Evidence	How to capture it	What it demonstrates
AWS identity	`aws sts get-caller-identity` (redact account identifiers if sharing publicly)	Selected caller/account
Terraform validation	`terraform validate`	Static Terraform configuration correctness
Planned changes	`terraform plan` (review and redact secrets)	Proposed resource changes at a point in time
Managed resources	`terraform state list`	Resources tracked in the selected state
Remote state presence	Authorized S3 listing / backend metadata	State stored remotely
Python tests	Test command and actual terminal result	Only the executed test cases
Do not create illustrative screenshots and label them as execution evidence. A text transcript with the command, date, outcome, and redacted identifiers is also acceptable.
7. Terraform remote state and recovery
DEV Central Platform uses an S3 remote backend. The configured DEV state key is:
```text
dev/central-platform/terraform.tfstate
```
The proposed PROD separation uses a distinct key:
```text
prod/central-platform/terraform.tfstate
```
The PROD key is a configuration/design detail, not evidence of a deployed PROD environment.
Backend safeguards to maintain or verify:
Restrict state-bucket access to approved Terraform operators and automation roles.
Encrypt state at rest and require secure transport.
Use Terraform's configured S3 backend locking (`use_lockfile = true`) and verify lock behavior when required.
Enable and verify S3 Versioning on the backend bucket before relying on earlier-object-version recovery. Versioning was not independently verified during the cited DEV inspection.
Treat state as sensitive because it can contain resource metadata and sensitive values.
State recovery is not application-data recovery. Reverting Git or restoring a prior Terraform state object is not a replacement for database/S3 data backups and must follow a reviewed recovery procedure.
8. Security controls vs. business features
Security and platform patterns represented by the POC
AWS Organizations account isolation and OU/SCP governance model (target architecture).
Private S3 data lake with public-access blocking and SSE-KMS encryption configured in IaC.
IAM least-privilege intent and cross-account access controls, requiring policies on both sides of the trust boundary.
GitHub Actions OIDC / temporary credentials design; no long-lived AWS access keys should be stored as repository secrets.
AWS Secrets Manager for application secrets (target design).
Centralized logging, audit accounts, and security-review processes (target architecture).
Protected Terraform state and sensitive-plan handling.
Business workflows that require separate integration evidence
Uploading an Office A CSV using authenticated browser access and a presigned URL.
Enforcing object size/schema checks, routing valid CSVs to `raw/` and invalid files to `quarantine/`.
Pulling Office B external API data on schedule, including OAuth2 token retrieval and rate limiting.
Exporting Office C RDS snapshots and masking PII within Office C before central publication.
Executing Glue jobs, populating curated datasets, refreshing dashboards and verifying QuickSight RLS.
A correctly configured IAM role or S3 bucket does not prove that the business workflow completed successfully.
9. Cost model (illustrative monthly PROD estimate)
The assignment's monthly estimate covers the entire proposed governed account scope, not just incremental pipeline services. In particular, Office C includes the cost of its existing RDS database. Figures are planning estimates, not AWS billing evidence.
Scope	Monthly estimate (USD)
Office A PROD	$4.64
Office B PROD	$2.91
Office C PROD (existing RDS + data-platform increment)	$98.24
Central Platform PROD	$188.76
Shared Security / Audit	$40.00
Consolidated monthly estimate	$334.55
Annualized estimate (12 months)	$4,014.60
For Office C, the $98.24 subtotal comprises $80.95 existing RDS plus $17.29 incremental data-platform costs; do not count both subtotal and components again. AWS Organizations supports consolidated billing at the payer account, while office-specific showback/chargeback reports remain internal allocations, not separate AWS invoices.
Actual pricing depends on region, usage, retention, data volume, request rates and current AWS prices. DEV testing can incur charges even when PROD was never deployed.
10. Cleanup and safe teardown
Warning: Terraform destroy can permanently remove cloud infrastructure. Review dependencies, state selection, S3 contents, retention requirements and organization policies first.
For an explicitly authorized disposable DEV deployment:
```powershell
cd environments/dev/central-platform
aws sts get-caller-identity
terraform workspace show
terraform plan -destroy
# After review and explicit approval:
terraform destroy
```
Confirm that the selected AWS account and backend key are DEV.
Do not destroy or manually delete the shared remote-state bucket as part of routine environment cleanup.
Check for retained objects, versioned S3 data, log groups, snapshots, KMS keys and other resources whose lifecycle may be independent of a destroy run.
Do not treat `terraform destroy` as secure deletion of all retained data or backups.
Ensure production data and shared governance/security accounts are outside the teardown scope.
11. Known limitations and follow-up work
No end-to-end integration claim: The three office pipelines, central ETL and dashboard reporting were not verified as one working system.
No PROD deployment claim: PROD approvals and deployment patterns are described but have not been exercised through a PROD apply.
Partial security verification: IAM/KMS/S3 controls must be validated at runtime, including negative access tests and cross-account resource policies.
Office A upload controls: A 10 MiB validation limit in Lambda does not itself prevent an oversized direct upload to S3; preventative upload constraints and failure paths should be tested separately.
Office C data handling: Snapshot export orchestration, Office C-local PII masking, retention and the cross-account masked-data contract require integration testing and governance sign-off.
RLS verification: QuickSight office-level restrictions and privileged management access require tests with representative identities and datasets.
Operational readiness: Alerting, SLO evaluation, backup/restore drills, cost alarms and runbooks require deployment-specific evidence.
Backend resilience: Independently verify S3 state-bucket versioning, locking and recovery procedures before relying on them.
CI/CD: Inspect real workflow runs and required approvals before describing a pipeline as successfully deployed.
12. Engineering and AI-assistance disclosure
This repository documents engineering decisions made during a learning and implementation exercise. ChatGPT was used to discuss AWS architecture, compare technical alternatives, review IAM/KMS/Terraform/Python approaches, and improve technical documentation. Technical recommendations were evaluated by the author; AI-generated suggestions are not presented as execution evidence. The accompanying assignment contains the formal disclosure of tool usage.
---
Repository: https://github.com/shaykekeidar/aws-enterprise-data-platform  
Purpose: Architecture documentation, reproducible DEV infrastructure examples, and clearly bounded implementation evidence.