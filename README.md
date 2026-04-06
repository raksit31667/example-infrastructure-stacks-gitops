# Infrastructure Stacks GitOps

Terraform Stacks and GitHub Actions pipelines for provisioning AWS infrastructure and microservice resources across multiple environments using a human-controlled GitOps model.

## Overview

This repository is split into two independently operated layers:

| Layer | What it manages | Trigger |
|---|---|---|
| **Infrastructure** | VPC, EKS control plane, node groups | Manual `workflow_dispatch` only |
| **Microservices** | ECR, ElastiCache, Secrets Manager, IRSA IAM role/policies per service | Manual `workflow_dispatch` or push to `master` |

The layers are decoupled via an **infrastructure contract** — a JSON document published to S3 after a successful infrastructure apply. Microservice stacks read the contract to obtain VPC, security group IDs, and EKS OIDC provider details rather than querying AWS directly at plan time.

## Repository Layout

```
.
├── stacks/
│   ├── infrastructure/              # Infrastructure Terraform Stack
│   │   ├── .terraform-version       # Terraform 1.14.5
│   │   ├── providers.tfcomponent.hcl
│   │   ├── variables.tfcomponent.hcl
│   │   ├── components.tfcomponent.hcl
│   │   ├── outputs.tfcomponent.hcl
│   │   ├── infratest.tfdeploy.hcl
│   │   ├── staging.tfdeploy.hcl
│   │   ├── production.tfdeploy.hcl
│   │   └── modules/
│   │       ├── network/             # VPC, subnets, NAT gateways, security groups
│   │       ├── kubernetes-controlplane/  # EKS cluster, IAM, OIDC provider
│   │       └── nodegroup/           # EKS managed node group, IAM roles
│   │
│   └── services/
│       └── booking/                 # Template service stack (copy for other services)
│           ├── .terraform-version
│           ├── providers.tfcomponent.hcl
│           ├── variables.tfcomponent.hcl
│           ├── components.tfcomponent.hcl
│           ├── outputs.tfcomponent.hcl
│           ├── booking.tfdeploy.hcl
│           └── modules/
│               ├── ecr/             # ECR repository with lifecycle policy
│               ├── elasticache/     # Serverless ElastiCache (Valkey/Redis)
│               ├── secret/          # AWS Secrets Manager secret
│               └── irsa/            # IAM role/policies for Kubernetes service account
│
├── .github/
│   └── workflows/
│       ├── infrastructure-provision.yaml          # Infrastructure pipeline
│       ├── microservice-stacks-provision.yaml     # Reusable microservice pipeline
│       ├── microservice-booking-production.yaml
│       ├── microservice-booking-staging.yaml
│       └── microservice-booking-test.yaml
│
└── scripts/
    └── setup-microservice-stacks.sh   # Scaffold new service stacks from the booking template
```

## Prerequisites

- Terraform >= 1.13 (1.14.5 recommended; pinned in `.terraform-version`)
- HCP Terraform organization with Stacks enabled
- AWS IAM role configured for GitHub OIDC federation (one per environment)
- S3 bucket (with versioning) for infrastructure contracts
- GitHub environment `infra-release` configured with required reviewers for production approval gates

## Required Placeholders

Before running any workflow, replace every placeholder in the Terraform and workflow files:

| Placeholder | Description |
|---|---|
| `<AWS_ACCOUNT_ID>` | Target AWS account number |
| `<AWS_REGION>` | AWS region (e.g. `ap-southeast-2`) |
| `<GITHUB_OIDC_ROLE_ARN>` | IAM role ARN assumed by GitHub Actions via OIDC |
| `<TF_STATE_BUCKET_NAME>` | S3 bucket name used for infrastructure contracts |
| `<PROJECT_OR_STACK_NAME>` | Short identifier prefixed on all AWS resource names |
| `<ENTERPRISE_APP_ID>` | Enterprise application ID tag value |
| `<COST_CENTRE>` | Cost centre tag value |
| `<OWNER_TEAM>` | Owning team tag value |

For the booking microservice deployment file, also replace:

| Placeholder | Where to get the value |
|---|---|
| `<VPC_ID_*>` | Injected automatically by the microservice workflow from the infrastructure contract in S3 |
| `<PRIVATE_SUBNETS_*_JSON>` | Injected automatically by the microservice workflow from the infrastructure contract in S3 |
| `<ELASTICACHE_SG_ID_*>` | Injected automatically by the microservice workflow from the infrastructure contract in S3 |
| `<OIDC_PROVIDER_ARN_*>` | Injected automatically by the microservice workflow from the infrastructure contract in S3 |
| `<OIDC_PROVIDER_URL_*>` | Injected automatically by the microservice workflow from the infrastructure contract in S3 |
| `<BOOKING_*_SECRET_JSON>` | AWS Secrets Manager or your secrets store |

`k8s_namespace` and `k8s_service_account_name` are currently hardcoded in `booking.tfdeploy.hcl`.

## Pipelines

### Infrastructure Pipeline

**File:** [.github/workflows/infrastructure-provision.yaml](.github/workflows/infrastructure-provision.yaml)

Triggered manually via `workflow_dispatch`. Inputs:

| Input | Values | Description |
|---|---|---|
| `environment` | `infratest` / `staging` / `production` | Target deployment |
| `apply_changes` | `true` / `false` | `false` = plan only |

**Job flow:**

```
validate → plan → approval_gate* → apply → test_network ┐
                                               test_controlplane ┤→ publish_contract
                                               test_nodegroup   ┘
```

\* `approval_gate` requires a reviewer approved in the `infra-release` GitHub environment.

The `publish_contract` job writes a versioned JSON file to S3:

```
s3://<TF_STATE_BUCKET_NAME>/contracts/<environment>/contract-<git_sha>-<run_id>.json
s3://<TF_STATE_BUCKET_NAME>/contracts/<environment>/latest.json
```

Contract schema:

```json
{
  "vpc_id": "...",
  "private_subnets": ["..."],
  "public_subnets": ["..."],
  "cluster_name": "...",
  "cluster_endpoint": "...",
  "cluster_ca": "...",
  "cluster_sg_id": "...",
  "elasticache_sg_id": "...",
  "oidc_provider_arn": "...",
  "oidc_provider_url": "...",
  "account_id": "...",
  "environment": "...",
  "git_sha": "...",
  "run_id": "...",
  "timestamp": "...",
  "contract_version": "..."
}
```

### Microservice Pipeline

**Reusable workflow:** [.github/workflows/microservice-stacks-provision.yaml](.github/workflows/microservice-stacks-provision.yaml)

**Job flow:**

```
resolve_contract → validate_and_plan → approval_gate* → apply → service_tests
```

The `resolve_contract` job downloads the specified contract version from S3 and validates its schema. If the contract is missing or schema-incompatible, the workflow fails before any plan runs.

#### Booking service workflows

| Workflow | Trigger | Apply |
|---|---|---|
| [microservice-booking-production.yaml](.github/workflows/microservice-booking-production.yaml) | `workflow_dispatch` or push to `master` | `apply_changes=true` or push to master |
| [microservice-booking-staging.yaml](.github/workflows/microservice-booking-staging.yaml) | `workflow_dispatch` or push to `master` | `apply_changes=true` or push to master |
| [microservice-booking-test.yaml](.github/workflows/microservice-booking-test.yaml) | `workflow_dispatch` or `pull_request` | Never (plan only) |

## Infrastructure Stack Components

### Network module

| Resource | Description |
|---|---|
| `aws_vpc` | VPC with DNS hostnames/resolution enabled |
| `aws_subnet` (private × AZ) | Private subnets tagged for EKS internal load balancers |
| `aws_subnet` (public × AZ) | Public subnets tagged for EKS external load balancers |
| `aws_nat_gateway` | One NAT gateway per AZ |
| `aws_security_group` (elasticache) | Allows port 6379 inbound from VPC CIDR |

### Kubernetes Control Plane module

| Resource | Description |
|---|---|
| `aws_eks_cluster` | EKS cluster with private endpoint, API+ConfigMap auth mode |
| `aws_iam_role` (cluster) | Cluster IAM role with `AmazonEKSClusterPolicy` |
| `aws_iam_openid_connect_provider` | OIDC provider for IRSA |

### Node Group module

| Resource | Description |
|---|---|
| `aws_eks_node_group` | Managed node group in private subnets |
| `aws_iam_role` (node) | Node IAM role with worker, CNI, and ECR read policies |

## Microservice Stack Components (booking template)

Components deploy in this order: `secret` → `elasticache` and `ecr` → `irsa`.

| Component | Resources |
|---|---|
| `secret` | `aws_secretsmanager_secret` + `aws_secretsmanager_secret_version` |
| `elasticache` | Serverless `aws_elasticache_serverless_cache`, user group, disabled default user, service user with `random_password` |
| `ecr` | `aws_ecr_repository` (IMMUTABLE tags, KMS encryption) + lifecycle policy |
| `irsa` | `aws_iam_role` with OIDC trust policy + least-privilege inline policies for `elasticache:Connect` and Secrets Manager read |

## Adding a New Service

1. Edit `scripts/setup-microservice-stacks.sh` and add the service name to `SERVICES`.
2. Run the scaffold script:
   ```bash
   bash scripts/setup-microservice-stacks.sh
   ```
3. Customise the generated `stacks/services/<service>/<service>.tfdeploy.hcl` — replace the infrastructure placeholder values with outputs from the published contract.
4. Commit and push; the generated workflows will be picked up by GitHub Actions.

## Security Notes

- All AWS authentication uses OIDC workload identity — no long-lived access keys.
- `identity_token` variables are declared `ephemeral = true` so they never persist in Terraform state.
- `secret_string` variables are declared `sensitive = true` and `ephemeral = true`.
- ElastiCache default user is disabled (`off -@all`); only the service user has access.
- Service pods use IRSA with an OIDC trust policy scoped to a single Kubernetes service account.
- ECR repositories use KMS encryption and immutable image tags by default.
- Concurrency groups prevent overlapping applies on the same environment.
- Production apply requires a manual approval in the `infra-release` GitHub environment.
