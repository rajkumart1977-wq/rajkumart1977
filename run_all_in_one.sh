
#!/usr/bin/env bash
# ALL-IN-ONE deploy script for Satvik Recipe App (Mac-ready)
# Usage: edit the ENV VARS below or export them before running.
# Ensure you have installed: Homebrew, git, gh (GitHub CLI), docker, docker-compose, doctl (optional), unzip, jq
set -euo pipefail

# --- EDIT THESE BEFORE RUNNING OR EXPORT THEM IN SHELL ---
GITHUB_USER="${GITHUB_USER:-your-github-username}"
REPO_NAME="${REPO_NAME:-satvik-recipe-app}"

DO_API_TOKEN="${DO_API_TOKEN:-}"   # optional: DigitalOcean token for DO deployment
DO_APP_SPEC="${DO_APP_SPEC:-do_app_spec.yaml}"

DOCKER_REGISTRY="${DOCKER_REGISTRY:-ghcr.io}"
DOCKER_USER="${DOCKER_USER:-your-docker-user}"
DOCKER_PASSWORD="${DOCKER_PASSWORD:-your-docker-password}"

BUNDLE_ZIP="${BUNDLE_ZIP:-production_deploy_bundle.zip}"
WORKDIR="${WORKDIR:-$(pwd)/satvik_repo}"

MAX_PERSONS="${MAX_PERSONS:-100000000}"

echo; echo "=== Satvik All-in-One deploy script ==="; echo

echo_step() { echo; echo "### $1"; echo "-----------------------------"; }

echo_step "Unzip bundle to $WORKDIR"
mkdir -p "$WORKDIR"
if [ ! -f "$BUNDLE_ZIP" ]; then
  echo "ERROR: bundle $BUNDLE_ZIP not found in $(pwd). Please copy production_deploy_bundle.zip here or set BUNDLE_ZIP."
  exit 1
fi
unzip -o "$BUNDLE_ZIP" -d "$WORKDIR"

cd "$WORKDIR"

echo_step "Check gh CLI"
if ! command -v gh >/dev/null 2>&1; then
  echo "Please install GitHub CLI (gh) first: https://cli.github.com/"
  exit 1
fi

echo_step "Initialize git and push to GitHub"
git init -q || true
git add -A
git commit -m "Initial import: Satvik Recipe App" || true

if ! gh repo view "$GITHUB_USER/$REPO_NAME" >/dev/null 2>&1; then
  gh repo create "$GITHUB_USER/$REPO_NAME" --private --source=. --remote=origin --push --confirm
else
  git remote add origin "https://github.com/$GITHUB_USER/$REPO_NAME.git" || true
  git branch -M main || true
  git push -u origin main || true
fi

echo_step "Set GitHub secrets (if provided)"
if [ -n "${DO_API_TOKEN}" ]; then
  echo -n "$DO_API_TOKEN" | gh secret set DO_API_TOKEN --repo "$GITHUB_USER/$REPO_NAME"
fi
if [ -n "${DOCKER_PASSWORD}" ]; then
  echo -n "$DOCKER_REGISTRY" | gh secret set DOCKER_REGISTRY --repo "$GITHUB_USER/$REPO_NAME"
  echo -n "$DOCKER_USER" | gh secret set DOCKER_USER --repo "$GITHUB_USER/$REPO_NAME"
  echo -n "$DOCKER_PASSWORD" | gh secret set DOCKER_PASSWORD --repo "$GITHUB_USER/$REPO_NAME"
fi

echo_step "Trigger GitHub Actions workflow (deploy)"
gh workflow run deploy.yml --repo "$GITHUB_USER/$REPO_NAME" || true
echo "Waiting a few seconds for workflow to start..."; sleep 5
gh run watch --repo "$GITHUB_USER/$REPO_NAME" --watch || true

if [ -n "${DO_API_TOKEN}" ]; then
  echo_step "Deploy to DigitalOcean (doctl)"
  if ! command -v doctl >/dev/null 2>&1; then
    echo "doctl not found. Skipping doctl deploy. Install from https://docs.digitalocean.com/reference/doctl/"
  else
    doctl auth init --access-token "$DO_API_TOKEN"
    doctl apps create --spec-file "$DO_APP_SPEC" || true
  fi
fi

echo_step "Start local backend (Postgres + API) with docker-compose"
if [ -f backend_prototype/docker-compose.yml ]; then
  (cd backend_prototype && docker compose up --build -d)
  echo "Waiting 10s for services to start..."; sleep 10
  docker compose ps || true
else
  echo "docker-compose.yml not found in backend_prototype/"
fi

echo_step "Create admin user (inside API container)"
if docker compose ps --services | grep -q api; then
  docker compose exec -T api node api/create_admin.js admin@example.com AdminPass123 || true
else
  echo "API container not found. Run create_admin.js manually with correct DATABASE_URL."
fi

echo_step "Complete. Visit your GitHub repo and CI logs, or DigitalOcean App Platform for deployment status."
