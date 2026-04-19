#!/usr/bin/env bash
# =============================================================================
# Build script for devopscorner-container
# Handles building, tagging, and pushing Docker images
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

REGISTRY="${REGISTRY:-ghcr.io}"
ORG="${ORG:-devopscorner}"
IMAGE_NAME="${IMAGE_NAME:-devopscorner-container}"
TAG="${TAG:-latest}"
PLATFORM="${PLATFORM:-linux/amd64,linux/arm64}"
DOCKERFILE="${DOCKERFILE:-Dockerfile}"
BUILD_CONTEXT="${BUILD_CONTEXT:-.}"

FULL_IMAGE="${REGISTRY}/${ORG}/${IMAGE_NAME}:${TAG}"

# ---------------------------------------------------------------------------
# Logging helpers
# ---------------------------------------------------------------------------
log_info()  { echo "[INFO]  $*"; }
log_warn()  { echo "[WARN]  $*" >&2; }
log_error() { echo "[ERROR] $*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Functions
# ---------------------------------------------------------------------------
check_dependencies() {
  log_info "Checking required dependencies..."
  for cmd in docker git; do
    command -v "$cmd" &>/dev/null || log_error "'$cmd' is not installed or not in PATH"
  done
}

get_git_metadata() {
  GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
  GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
  BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  log_info "Git commit : $GIT_COMMIT"
  log_info "Git branch : $GIT_BRANCH"
  log_info "Build date : $BUILD_DATE"
}

build_image() {
  log_info "Building image: $FULL_IMAGE"
  docker buildx build \
    --platform "$PLATFORM" \
    --file "$DOCKERFILE" \
    --tag "$FULL_IMAGE" \
    --label "org.opencontainers.image.created=${BUILD_DATE}" \
    --label "org.opencontainers.image.revision=${GIT_COMMIT}" \
    --label "org.opencontainers.image.source=https://github.com/${ORG}/${IMAGE_NAME}" \
    --build-arg "BUILD_DATE=${BUILD_DATE}" \
    --build-arg "GIT_COMMIT=${GIT_COMMIT}" \
    --build-arg "GIT_BRANCH=${GIT_BRANCH}" \
    --push \
    "$BUILD_CONTEXT"
  log_info "Image built and pushed successfully: $FULL_IMAGE"
}

tag_additional() {
  if [[ "$TAG" != "latest" ]]; then
    LATEST_IMAGE="${REGISTRY}/${ORG}/${IMAGE_NAME}:latest"
    log_info "Also tagging as: $LATEST_IMAGE"
    docker buildx imagetools create -t "$LATEST_IMAGE" "$FULL_IMAGE"
  fi
}

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -r, --registry   Container registry (default: ghcr.io)
  -o, --org        Organisation/namespace (default: devopscorner)
  -i, --image      Image name (default: devopscorner-container)
  -t, --tag        Image tag (default: latest)
  -f, --file       Dockerfile path (default: Dockerfile)
  -h, --help       Show this help message
EOF
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--registry) REGISTRY="$2"; shift 2 ;;
    -o|--org)      ORG="$2"; shift 2 ;;
    -i|--image)    IMAGE_NAME="$2"; shift 2 ;;
    -t|--tag)      TAG="$2"; shift 2 ;;
    -f|--file)     DOCKERFILE="$2"; shift 2 ;;
    -h|--help)     usage; exit 0 ;;
    *) log_error "Unknown option: $1" ;;
  esac
done

FULL_IMAGE="${REGISTRY}/${ORG}/${IMAGE_NAME}:${TAG}"

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
check_dependencies
get_git_metadata
build_image
tag_additional

log_info "Done."
