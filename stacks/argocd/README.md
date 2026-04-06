# ArgoCD Terraform Stack

## Overview
This Terraform Stack deploys ArgoCD (GitOps CD platform) to an existing EKS cluster using the official Helm chart. It supports three environments: `infratest`, `staging`, and `production`, with environment-specific configurations (replica counts, SSO enablement, etc.).

## Files
- `.terraform-version`: Pinned Terraform version (1.14.0)
- `providers.tfcomponent.hcl`: AWS provider with OIDC authentication for the stack
- `variables.tfcomponent.hcl`: Input variables with sensible defaults and validations
- `components.tfcomponent.hcl`: Stack component wiring for the local ArgoCD module
- `outputs.tfcomponent.hcl`: Outputs for accessing ArgoCD and next steps
- `infratest.tfdeploy.hcl`: Deployment configuration for infratest (minimal resources, no SSO)
- `staging.tfdeploy.hcl`: Deployment configuration for staging (2 replicas, GitHub SSO enabled)
- `production.tfdeploy.hcl`: Deployment configuration for production (3 replicas, GitHub SSO enabled)
- `modules/argocd/`: Local Terraform module containing providers, resources, and outputs
- `modules/argocd/argocd-values.tftpl`: Helm chart values template rendered by the module

## Prerequisites
1. **EKS Cluster**: Must exist and be accessible via kubeconfig (or credentials provided)
2. **AWS Secrets Manager**: Create secrets for:
   - `argocd-admin-password-<environment>`: Initial admin password for ArgoCD UI
   - `argocd-github-oauth-<environment>`: GitHub OAuth client ID and secret (for SSO)
3. **Terraform 1.14+**: Version management handled by `.terraform-version`
4. **Providers installed**: AWS, Kubernetes, Helm

## Usage

### Initialize Stack
```bash
cd stacks/argocd
terraform init
```

### Plan ArgoCD Deployment for Infratest
```bash
terraform plan -var-file="infratest.tfvars"
```

### Deploy to Infratest
```bash
terraform apply -var-file="infratest.tfvars"
```

### Deploy to Staging/Production
Repeat with `staging.tfvars` or `production.tfvars` (after creating tfvars files with environment-specific values).

## Configuration

### Variables
See `variables.tfcomponent.hcl` for all inputs. Key variables:
- `cluster_endpoint`: EKS cluster API endpoint
- `cluster_ca`: base64-encoded cluster CA certificate
- `cluster_token`: Authentication token (ephemeral, via IAM/assume-role)
- `argocd_helm_version`: Pinned Helm chart version (e.g., `5.46.8`)
- `argocd_replicas`: Number of server replicas (default: 1 for infratest, 2 for staging, 3 for production)
- `argocd_dex_enabled`: Enable GitHub SSO via Dex (default: false for infratest)

### Environment-Specific Differences

| Setting | Infratest | Staging | Production |
|---------|-----------|---------|------------|
| Replicas | 1 | 2 | 3 |
| SSO enabled | No | Yes | Yes |
| Secrets | `argocd-admin-password-infratest` | `argocd-admin-password-staging` + GitHub OAuth | `argocd-admin-password-production` + GitHub OAuth |
| Resource limits | Low (100m CPU, 128Mi mem) | Medium | High |

### Customization

#### Helm Values
Edit `modules/argocd/argocd-values.tftpl` to modify:
- Server/controller/repo-server resource requests and limits
- Ingress configuration (for production, enable ALB ingress with TLS)
- OIDC/Dex configuration for GitHub SSO
- Notification settings (currently disabled)

#### Placeholders
Replace these before deployment:
- `<AWS_REGION>`: Target AWS region (e.g., `ap-southeast-2`)
- `<GITHUB_OIDC_ROLE_ARN>`: IAM role ARN for GitHub Actions OIDC (e.g., `arn:aws:iam::123456789012:role/github-oidc`)
- `<PROJECT_OR_STACK_NAME>`: Logical stack identifier (e.g., `jedis`)
- `<CLUSTER_ENDPOINT_PLACEHOLDER>`: EKS cluster API endpoint
- `<CLUSTER_CA_CERT_PLACEHOLDER>`: Cluster CA certificate (base64-encoded)
- `<CLUSTER_TOKEN_PLACEHOLDER>`: Cluster authentication token
- `<ARGOCD_HELM_VERSION>`: Specific Helm chart version
- `<GITHUB_OAUTH_CLIENT_ID>`: GitHub OAuth app client ID (if SSO enabled)
- `<GITHUB_ORG>`: GitHub organization for SSO restrictions

## Outputs
After deployment:
- `argocd_namespace`: Kubernetes namespace where ArgoCD is deployed
- `argocd_server_service`: Service name for ArgoCD server
- `argocd_server_namespace_service`: Fully-qualified service DNS name
- `next_steps`: Human-readable instructions for accessing and configuring ArgoCD

## Access ArgoCD

### Port-Forward (for infratest/development)
```bash
kubectl -n argocd port-forward svc/argocd-server 8080:443
# Access https://localhost:8080
# Username: admin
# Password: Retrieved from AWS Secrets Manager
```

### Ingress (for staging/production)
Configure an ALB ingress in Helm values with proper TLS certificates and DNS.

## Adding Repositories
Once ArgoCD is deployed, add Git repositories:
```bash
argocd repo add <REPOSITORY_URL> --upsert --ssh-private-key-path ~/.ssh/<KEY>
```

Repositories can be stored as Kubernetes Secrets within the cluster or in AWS Secrets Manager via a custom controller.

## Next Steps
1. Deploy ArgoCD to infratest
2. Test repository connectivity
3. Create ApplicationSet for microservices (see MICROSERVICE_STACKS_FROM_SCRATCH_PLAN.md)
4. Configure environment protections and approval gates for staging/production

## Troubleshooting

### ArgoCD pod fails to start
Check logs:
```bash
kubectl -n argocd logs deployment/argocd-server
```

### Helm release fails to apply
Validate Helm values syntax:
```bash
helm lint stacks/argocd/modules/argocd --values <RENDERED_VALUES_FILE>
```

### Secrets not accessible
Verify AWS Secrets Manager secrets exist and the OIDC role has `secretsmanager:GetSecretValue` permission.

### Kubernetes provider auth fails
Confirm `cluster_token` is valid and not expired. For OIDC-based auth, verify IAM role trust relationship.

## Cost Optimization (Infratest)
- 1 ArgoCD server replica
- 100m CPU, 128Mi memory limits per container
- No high-availability setup
- Suitable for testing only; increase replicas and resources for staging/production

## Further Reading
- [ArgoCD Official Documentation](https://argo-cd.readthedocs.io/)
- [ArgoCD Helm Chart](https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd)
- [Terraform Kubernetes Provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)
- [Terraform Helm Provider](https://registry.terraform.io/providers/hashicorp/helm/latest/docs)
