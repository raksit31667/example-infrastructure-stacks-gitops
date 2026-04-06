# ArgoCD Stacks From Scratch Plan (Human-Controlled)

## Objective
Deploy ArgoCD (GitOps continuous delivery platform) as a separate Terraform Stack to existing EKS clusters with human-controlled provisioning. ArgoCD deployment is triggered after infrastructure provisioning and enables GitOps-driven microservice deployments via ApplicationSets.

## Operating Model
- ArgoCD apply: manual only (`workflow_dispatch`).
- Cluster credential injection via AWS during workflow execution.
- Optional plan-only checks can run automatically, but no automatic apply.
- Human operator controls promotion from infratest → staging → production.
- Repositories and ApplicationSets configured separately after ArgoCD deployment.

## Scope
- Included:
  - New ArgoCD stack implementation using Helm chart for all environments.
  - Automated cluster credential fetching (endpoint, CA, token) from AWS EKS.
  - Manual GitHub Actions workflows with approvals and validations.
  - Post-deployment verification (namespace, deployments, RBAC, service availability).
  - Environment-specific configurations (replicas, SSO enablement, resource limits).
- Excluded:
  - Auto-apply on push or PR merge.
  - Automated repository registration (manual CLI or future controller).
  - Automated ApplicationSet creation (manual setup after deployment).
  - Multi-cluster ArgoCD controller (single controller per cluster; delegation via clusters-in-clusters future pattern).

## Target Directory Layout
```text
stacks/
  argocd/
    .terraform-version
    providers.tfcomponent.hcl
    variables.tfcomponent.hcl
    components.tfcomponent.hcl
    outputs.tfcomponent.hcl
    infratest.tfdeploy.hcl
    staging.tfdeploy.hcl
    production.tfdeploy.hcl
    README.md
    MIGRATION.md
    ARGOCD_STACKS_FROM_SCRATCH_PLAN.md
    modules/
      argocd/
        main.tf
        variables.tf
        outputs.tf
        argocd-values.tftpl
```

## Implementation Phases

### Phase A: Stack Foundation
1. Create stack root at `stacks/argocd`.
2. Add `.terraform-version` (Terraform >= 1.14.x pinned).
3. Add provider configuration with AWS OIDC role assumption (AWS only; Kubernetes/Helm are module-internal).
4. Add stack variables: cluster credentials (endpoint, CA, token), ArgoCD config (replicas, versions).
5. Define component that references local `./modules/argocd` module.

### Phase B: Local Module Implementation
1. Create `modules/argocd/` with Terraform module code (not stack code).
2. Add Kubernetes and Helm providers to the module.
3. Implement resources: namespace, Helm release, RBAC, optional GitHub secrets.
4. template Helm values file (`argocd-values.tftpl`) with conditionals for environment-specific config.
5. Export module outputs: namespace, release name/version, service FQDN, next steps documentation.

### Phase C: Multi-Environment Deployment Files
1. Create `infratest.tfdeploy.hcl`: 1 replica, Dex SSO disabled, cost-optimized resource requests.
2. Create `staging.tfdeploy.hcl`: 2 replicas, Dex SSO enabled, medium resources.
3. Create `production.tfdeploy.hcl`: 3 replicas, Dex SSO enabled, high resources & HA.
4. Placeholder cluster credentials in each `.tfdeploy.hcl` to be injected by workflow.

### Phase D: Manual Workflow Controls
1. Create `argocd-stack-provision.yaml` reusable workflow:
   - fetch cluster credentials from EKS (endpoint, CA, token).
   - inject credentials into `.tfdeploy.hcl` file.
   - validate/plan/apply sequence.
   - environment-based approval gate before apply.
   - post-deploy verification (namespace, rollout status, service, RBAC).
2. Use `infra-release` environment for approval gates.
3. Add concurrency lock per environment to prevent overlaps.
4. Store plan and apply logs as artifacts for audit trail.

### Phase E: Documentation and Migration Support
1. Create `README.md` with usage, configuration, customization, troubleshooting.
2. Create `MIGRATION.md` with step-by-step migration from bash-based `argocd-setup.sh` to Terraform Stack.
3. Document placeholder values and required AWS Secrets Manager secrets.
4. Provide examples for GitHub SSO configuration (Dex).

## Workflow Design (Manual First)

### ArgoCD Workflow (Manual)
1. `workflow_call` inputs:
   - `environment` (infratest|staging|production) — choice selector
   - `cluster_name` (e.g., `<PROJECT_OR_STACK_NAME>-infratest-eks`)
   - `apply_changes` (boolean, default false)
2. Jobs:
   - `fetch_cluster_credentials` → retrieve EKS endpoint, CA, token
   - `validate_and_plan` → init, validate, inject credentials, plan
   - `approval_gate` (environment: infra-release) → if `apply_changes=true`
   - `apply` → init, inject credentials, apply
   - `verify_deployment` → check namespace, deployments, service, RBAC
   - `summary` → report workflow status

### Calling the Workflow (Example)
```yaml
jobs:
  deploy_argocd_infratest:
    uses: ./.github/workflows/argocd-stack-provision.yaml
    with:
      environment: infratest
      cluster_name: my-project-infratest-eks
      apply_changes: false  # true to deploy, false for plan-only
    secrets: inherit
```

## Verification Checklist
1. Local Terraform Stack syntax validation succeeds (`terraform stacks validate`).
2. Infratest plan succeeds and shows correct component, module, and resource dependencies.
3. Infratest apply succeeds (no errors, Helm release stable).
4. Post-deploy verification passes:
   - `kubectl get namespace argocd` returns active namespace.
   - `kubectl get deploy -n argocd` shows server, repo-server, controller deployments.
   - `kubectl get svc argocd-server -n argocd` returns service with ClusterIP.
   - `kubectl get clusterrolebinding argocd-manager` confirms RBAC binding.
5. ArgoCD UI accessible via port-forward: `kubectl port-forward -n argocd svc/argocd-server 8080:443`.
6. Admin credentials retrievable from AWS Secrets Manager secret.
7. (Optional) GitHub SSO configuration validates if Dex enabled.
8. Promote unchanged pattern to staging and production with sign-off.

## Risk Controls
- Manual approvals before apply on each environment (environment protection: `infra-release`).
- Concurrency lock per environment to prevent overlapping applies.
- Cluster credentials are ephemeral: fetched fresh at plan/apply time, never stored in state.
- Post-deployment verification catches deployment failures before marking workflow as success.
- Plan artifact review recommended before production apply.
- Rollback: manually uninstall Helm release or destroy via `terraform stacks destroy -deployment <env>`.

## Rollout Strategy
1. **Pilot infratest:**
   - Deploy ArgoCD to infratest cluster with `apply_changes: false` (plan-only).
   - Review plan output for correctness.
   - Re-run with `apply_changes: true` to deploy.
   - Verify post-deployment checks pass.
   - Capture deployment timings and any issues.

2. **Test and refine:**
   - Access ArgoCD UI via port-forward.
   - Retrieve admin password from Secrets Manager.
   - Manually add a test repository (optional).
   - Document any adjustments needed to Helm values or configuration.

3. **Staging rollout:**
   - Apply same plan to staging cluster.
   - Enable Dex SSO if not already enabled in infratest.
   - Increase replicas to 2 for HA.
   - Perform staging-specific tests (GitHub SSO, repository sync).
   - Require sign-off from platform/infra team.

4. **Production rollout:**
   - Apply same pattern to production cluster.
   - Enable all HA and observability features.
   - Run full verification suite.
   - Require explicit approval with change request documentation.
   - Monitor for 30+ minutes post-deployment.

## Next Steps After Deployment
1. **Repository Management:**
   - (Manual) Add Git repositories: `argocd repo add <url> --ssh-private-key-path <key>`
   - (Future) Create `argocd-repositories` Terraform module/stack for GitOps-driven repo management.

2. **ApplicationSet Configuration:**
   - See [MICROSERVICE_STACKS_FROM_SCRATCH_PLAN.md](../services/MICROSERVICE_STACKS_FROM_SCRATCH_PLAN.md) for microservice ApplicationSet setup.
   - Create app-of-apps pattern for centralized deployment orchestration.

3. **SSO and Access Control:**
   - Configure GitHub OAuth in ArgoCD (already templated in Dex config).
   - Set up RBAC policies per team/service.
   - Test authentication flow.

4. **Monitoring and Notifications:**
   - Integrate ArgoCD with Prometheus for metrics.
   - Configure notifications (Slack, email) for deployment events.
   - Set up alerts for sync failures or unhealthy applications.

## Troubleshooting Common Issues

### ArgoCD pods fail to start
Check logs:
```bash
kubectl -n argocd logs deployment/argocd-server
```
Verify Helm release status:
```bash
helm status argocd -n argocd
```

### Cluster credentials not found or invalid
Ensure EKS cluster exists:
```bash
aws eks describe-cluster --name <CLUSTER_NAME> --region <AWS_REGION>
```
Verify IAM role has permissions:
```bash
aws iam get-role --role-name <GITHUB_OIDC_ROLE_NAME>
```

### Terraform Stacks validates but plan fails
Ensure all placeholders are replaced:
```bash
cat infratest.tfdeploy.hcl | grep "PLACEHOLDER"
```
Check that AWS Secrets Manager secrets exist (optional, only if SSO enabled).

### Port-forward works but UI returns 502 or timeout
Wait for rollout to complete:
```bash
kubectl rollout status deployment/argocd-server -n argocd --timeout=5m
```
Check service and endpoints:
```bash
kubectl get svc argocd-server -n argocd
kubectl get endpoints argocd-server -n argocd
```

## Comparison: Bash Script vs. Terraform Stack

| Aspect | Bash Script (`argocd-setup.sh`) | Terraform Stack |
|--------|----------------------------------|-----------------|
| **State management** | None (manual/implicit) | Full Terraform state tracking |
| **Idempotency** | Partial (upsert flags) | Full; safe to re-run |
| **Version pinning** | Manual edits | Explicit in variables and `.terraform-version` |
| **Cluster credentials** | Hardcoded or env var | Fetched fresh at plan/apply time from AWS |
| **Environment config** | Manual file edits | tfvars files per environment |
| **Auditability** | Git history only | Git + Terraform state + workflow artifacts |
| **Testing** | Manual kubectl checks | Automated post-deploy verification jobs |
| **Reproducibility** | Difficult across teams | Guaranteed via Terraform Stack semantics |

## Success Metrics
- [ ] Infratest ArgoCD stack deploys without errors.
- [ ] Post-deploy verification passes all checks.
- [ ] ArgoCD UI is accessible and admin login works.
- [ ] At least one test repository added successfully.
- [ ] Staging deployment completes with sign-off.
- [ ] Production deployment documented and monitored.
- [ ] Team documentation and runbooks created.
- [ ] Rollback procedure tested and documented.
