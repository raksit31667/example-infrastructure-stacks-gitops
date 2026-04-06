# Infrastructure Stacks From Scratch Plan (Human-Controlled)

## Objective
Build Terraform Stacks for infrastructure from scratch with human-controlled provisioning. Infrastructure and microservice provisioning remain decoupled and are triggered manually.

## Operating Model
- Infrastructure apply: manual only (`workflow_dispatch`).
- Microservice apply: manual only (`workflow_dispatch`).
- Optional plan-only checks can run automatically, but no automatic apply.
- Human operator controls promotion from infratest -> staging -> production.

## Scope
- Included:
  - New infrastructure stack implementation for network, kubernetes-controlplane, and nodegroup.
  - Contract publication of infrastructure outputs for microservice handoff.
  - Manual GitHub Actions workflows with approvals and guardrails.
- Excluded:
  - Auto-apply on push.
  - Unified infra + microservice pipeline.
  - Multi-environment rollout in a single initial change.

## Target Directory Layout
```text
stacks/
  infrastructure/
    .terraform-version
    providers.tfcomponent.hcl
    variables.tfcomponent.hcl
    components.tfcomponent.hcl
    outputs.tfcomponent.hcl
    infratest.tfdeploy.hcl
    staging.tfdeploy.hcl
    production.tfdeploy.hcl
    modules/
      network/
      kubernetes-controlplane/
      nodegroup/
```

## Implementation Phases

### Phase A: Stack Foundation
1. Create stack root at `stacks/infrastructure`.
2. Add `.terraform-version` (Terraform >= 1.13, recommended pinned 1.14.x).
3. Add provider configuration with AWS OIDC role assumption.
4. Add stack variables and deployment files (start with `infratest`).

### Phase B: Module Interface Refactor
1. Convert network module to export required outputs (vpc id, subnet ids, tgw id if needed).
2. Remove SSM output publishing where used only for inter-module wiring.
3. Convert controlplane and nodegroup modules to consume explicit inputs instead of SSM data reads.
4. Validate variable contracts between components.

### Phase C: Stack Component Graph
1. Define component `network`.
2. Define component `kubernetes_controlplane` consuming network outputs.
3. Define component `nodegroup` consuming controlplane + network outputs.
4. Enforce dependency order via explicit output references and `depends_on` only when necessary.

### Phase D: Manual Workflow Controls
1. Create infrastructure workflow (manual trigger only):
   - validate -> plan -> approval gate -> apply -> tests -> publish contract.
2. Use environment protection for approval (`infra-release` or stricter prod env).
3. Add concurrency lock key per account/environment.
4. Store plan and apply artifacts for audit.

### Phase E: Contract Publication and Handoff
1. Publish infrastructure contract after successful apply:
   - required keys: `vpc_id`, `private_subnets`, `public_subnets`, `cluster_name`, `cluster_endpoint`, `cluster_ca`, `cluster_sg_id`, `elasticache_sg_id`, `oidc_provider_arn`, `oidc_provider_url`.
   - metadata: `account_id`, `environment`, `git_sha`, `run_id`, `timestamp`, `contract_version`.
2. Store contract in durable location (recommended S3 with versioning).
3. Microservice workflow requires operator-supplied `contract_version` input.
4. Fail microservice plan if contract missing or schema incompatible.

### Phase F: ArgoCD Stack Foundation
1. Create stack root at `stacks/argocd`.
2. Add `.terraform-version` pinned to Terraform 1.14.x.
3. Add provider configuration: AWS (for Secrets Manager), Kubernetes, Helm.
4. Add stack variables for cluster credentials (endpoint, CA, token).
5. Create module `argocd/` with:
   - Kubernetes namespace resource.
   - Helm release for ArgoCD chart with templated values.
   - RBAC cluster role binding for application controller.
   - Optional: Secrets for GitHub OAuth/deploy keys.
6. Create environment deployment files: `infratest.tfdeploy.hcl`.
7. Define stack outputs: namespace, release name/version, service endpoint.

## Workflow Design (Manual First)

### Infrastructure Workflow (manual)
1. `workflow_dispatch` inputs:
   - `environment` (infratest|staging|production)
   - `apply_changes` (boolean)
2. Jobs:
   - `validate`
   - `plan`
   - `approval_gate` (environment approval)
   - `apply` (if approved and `apply_changes=true`)
   - `publish_contract`

### Microservice Workflow (manual)
1. `workflow_dispatch` inputs:
   - `service_name`
   - `environment`
   - `contract_version`
   - `apply_changes`
2. Jobs:
   - `resolve_contract`
   - `service_validate`
   - `service_plan`
   - `approval_gate`
   - `service_apply`
   - `service_tests`

## Verification Checklist
1. Infratest stack validate/plan succeeds and shows expected dependency order.
2. Infratest apply succeeds and existing infra tests pass:
   - `infrastructure/network/scripts/test_vpc_network.sh`
   - `infrastructure/network/scripts/test_bcs_connectivity.sh`
   - `infrastructure/kubernetes-controlplane/scripts/test_controlplane_health.sh`
   - `infrastructure/kubernetes-controlplane/scripts/test_fargate_nodepool.sh`
   - `infrastructure/nodegroup/scripts/test_nodepool.sh`
3. Contract artifact is published with required schema + metadata.
4. Microservice manual plan succeeds only with valid contract version.
5. Invalid/missing contract blocks microservice workflow before apply.
6. Promote unchanged pattern to staging and production with sign-off.

## Risk Controls
- Manual approvals before apply for each environment.
- Concurrency lock per account/environment to avoid overlapping applies.
- Rollback runbook attached to workflow (state restore and controlled re-apply).
- Plan artifact review required before production apply.

## Rollout Strategy
1. Pilot infratest only.
2. Capture run timings, failures, and contract gaps.
3. Apply improvements.
4. Roll to staging.
5. Roll to production after staging sign-off.
