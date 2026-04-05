#!/usr/bin/env bash
# setup-microservice-stacks.sh
#
# Scaffolds Terraform Stack directories and GitHub Actions workflows for
# additional microservices, using the booking stack as the reference template.
#
# Usage:
#   ./scripts/setup-microservice-stacks.sh
#
# The SERVICES array below must be populated with all service names before
# running.  Each service will receive:
#   - stacks/services/<service>/ — Stack configuration (copied from booking template)
#   - .github/workflows/microservice-<service>-{production,staging,test}.yaml

set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────

# Populate with your service names (booking is the template, skip it here).
SERVICES=(
  # "<service-name-1>"
  # "<service-name-2>"
)

ENVIRONMENTS=("production" "staging" "test")

# ── Paths ─────────────────────────────────────────────────────────────────────

REPO_ROOT="$(git rev-parse --show-toplevel)"
TEMPLATE_STACK="${REPO_ROOT}/stacks/services/booking"
STACKS_DIR="${REPO_ROOT}/stacks/services"
WORKFLOWS_DIR="${REPO_ROOT}/.github/workflows"

# ── Helpers ───────────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo -e "${GREEN}✓${NC} $*"; }
warning() { echo -e "${YELLOW}⏭${NC} $*"; }
error()   { echo -e "${RED}✗${NC} $*" >&2; }

# ── Preflight checks ──────────────────────────────────────────────────────────

if [[ "${#SERVICES[@]}" -eq 0 ]]; then
  error "No services defined. Edit the SERVICES array in this script before running."
  exit 1
fi

if [[ ! -d "${TEMPLATE_STACK}" ]]; then
  error "Template stack not found: ${TEMPLATE_STACK}"
  exit 1
fi

echo ""
echo "Repository root : ${REPO_ROOT}"
echo "Template stack  : ${TEMPLATE_STACK}"
echo "Services        : ${SERVICES[*]}"
echo ""

# ── Phase 1: Create Stack directory structure ─────────────────────────────────

echo -e "${YELLOW}Phase 1: Create stack directory structure${NC}"

for service in "${SERVICES[@]}"; do
  SERVICE_STACK_DIR="${STACKS_DIR}/${service}"

  if [[ -d "${SERVICE_STACK_DIR}" ]]; then
    warning "Skipping ${service} stack (directory already exists)"
    continue
  fi

  mkdir -p "${SERVICE_STACK_DIR}/modules"

  # Copy module source files from the template
  for module in ecr elasticache secret; do
    if [[ -d "${TEMPLATE_STACK}/modules/${module}" ]]; then
      cp -r "${TEMPLATE_STACK}/modules/${module}" "${SERVICE_STACK_DIR}/modules/"
    else
      error "Template module not found: ${TEMPLATE_STACK}/modules/${module}"
      exit 1
    fi
  done

  info "Created module directory structure for ${service}"
done

# ── Phase 2: Generate Stack configuration files ───────────────────────────────

echo ""
echo -e "${YELLOW}Phase 2: Generate stack configuration files${NC}"

for service in "${SERVICES[@]}"; do
  SERVICE_STACK_DIR="${STACKS_DIR}/${service}"

  # Static files shared across all services
  for file in \
    .terraform-version \
    providers.tfcomponent.hcl \
    variables.tfcomponent.hcl \
    components.tfcomponent.hcl \
    outputs.tfcomponent.hcl; do

    if [[ ! -f "${SERVICE_STACK_DIR}/${file}" ]]; then
      cp "${TEMPLATE_STACK}/${file}" "${SERVICE_STACK_DIR}/${file}"
    fi
  done

  info "Generated stack config files for ${service}"
done

# ── Phase 3: Generate per-service deployment files ────────────────────────────

echo ""
echo -e "${YELLOW}Phase 3: Generate deployment files (.tfdeploy.hcl)${NC}"

for service in "${SERVICES[@]}"; do
  SERVICE_STACK_DIR="${STACKS_DIR}/${service}"
  TFDEPLOY_FILE="${SERVICE_STACK_DIR}/${service}.tfdeploy.hcl"

  if [[ -f "${TFDEPLOY_FILE}" ]]; then
    warning "Skipping ${service} deployment file (already exists)"
    continue
  fi

  # Generate from booking template, substituting service name
  sed "s/booking/${service}/g; s/BOOKING/$(echo "${service}" | tr '[:lower:]' '[:upper:]')/g" \
    "${TEMPLATE_STACK}/booking.tfdeploy.hcl" \
    > "${TFDEPLOY_FILE}"

  info "Generated ${service}.tfdeploy.hcl"
done

# ── Phase 4: Generate per-service per-environment workflows ───────────────────

echo ""
echo -e "${YELLOW}Phase 4: Generate GitHub Actions workflows${NC}"

for service in "${SERVICES[@]}"; do
  SERVICE_UPPER="$(echo "${service}" | tr '[:lower:]' '[:upper:]')"

  for env in "${ENVIRONMENTS[@]}"; do
    ENV_UPPER="$(echo "${env}" | tr '[:lower:]' '[:upper:]')"
    WORKFLOW_FILE="${WORKFLOWS_DIR}/microservice-${service}-${env}.yaml"

    if [[ -f "${WORKFLOW_FILE}" ]]; then
      warning "Skipping workflow ${service}-${env} (already exists)"
      continue
    fi

    # Build trigger section — test env uses pull_request; others use push to master
    if [[ "${env}" == "test" ]]; then
      TRIGGER_SECTION=$(cat <<YAML
  pull_request:
    paths:
      - ".github/workflows/microservice-${service}-${env}.yaml"
      - "stacks/services/${service}/**"
YAML
)
      CONCURRENCY_CANCEL="cancel-in-progress: true"
      CONCURRENCY_GROUP="microservice-${service}-${env}-\${{ github.head_ref || github.run_id }}"
      EXTRA_PERMISSIONS="  pull-requests: write"
      APPLY_EXPR="false"
    else
      TRIGGER_SECTION=$(cat <<YAML
  push:
    branches:
      - master
    paths:
      - ".github/workflows/microservice-${service}-${env}.yaml"
      - "stacks/services/${service}/**"
YAML
)
      CONCURRENCY_CANCEL="cancel-in-progress: false"
      CONCURRENCY_GROUP="microservice-${service}-${env}"
      EXTRA_PERMISSIONS=""
      APPLY_EXPR="\${{ inputs.apply_changes == true || (github.event_name == 'push' && github.ref == 'refs/heads/master') }}"
    fi

    cat > "${WORKFLOW_FILE}" <<WORKFLOW
name: ${ENV_UPPER} — ${service} Infrastructure

on:
  workflow_dispatch:
    inputs:
      contract_version:
        description: "Infrastructure contract version (leave blank for latest)"
        required: false
        default: "latest"
      apply_changes:
        description: "Apply changes"
        required: true
        type: boolean
        default: false
${TRIGGER_SECTION}

concurrency:
  group: ${CONCURRENCY_GROUP}
  ${CONCURRENCY_CANCEL}

permissions:
  id-token: write
  contents: read
${EXTRA_PERMISSIONS}

jobs:
  provision:
    name: Provision ${service} — ${ENV_UPPER}
    uses: ./.github/workflows/microservice-stacks-provision.yaml
    with:
      service_name: ${service}
      deployment_name: ${service}-${env}
      stack_path: stacks/services/${service}
      environment: ${env}
      contract_version: \${{ inputs.contract_version || 'latest' }}
      apply_changes: ${APPLY_EXPR}
WORKFLOW

    info "Generated workflow for ${service}-${env}"
  done
done

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Edit each stacks/services/<service>/<service>.tfdeploy.hcl"
echo "   and replace <VPC_ID_*>, <PRIVATE_SUBNET_*>, <ELASTICACHE_SG_ID_*> placeholders"
echo "   with the values from the infrastructure contract published to S3."
echo ""
echo "2. Test one service stack locally:"
echo "   cd stacks/services/<service>"
echo "   terraform stacks init"
echo "   terraform stacks validate"
echo "   terraform stacks plan -deployment <service>-test"
echo ""
echo "3. Commit and push to master to trigger the generated workflows."
