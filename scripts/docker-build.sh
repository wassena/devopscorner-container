#!/usr/bin/env bash
# =============================================================================
# Docker Build Script for devopscorner-container
# Handles multi-stage Docker image builds with tagging and pushing
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Default values (can be overridden by environment variables)
DOCKER_REGISTRY="${DOCKER_REGISTRY:-docker.io}"
DOCKER_NAMESPACE="${DOCKER_NAMESPACE:-devopscorner}"
IMAGE_NAME="${IMAGE_NAME:-devopscorner-container}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
DOCKERFILE="${DOCKERFILE:-Dockerfile}"
BUILD_CONTEXT="${BUILD_CONTEXT:-$PROJECT_ROOT}"
PLATFORM="${PLATFORM:-linux/amd64}"
PUSH_IMAGE="${PUSH_IMAGE:-false}"

# Derived values
FULL_IMAGE_NAME="${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/${IMAGE_NAME}"
DATE_TAG="$(date +%Y%m%d)"
GIT_COMMIT="$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
GIT_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')"

# ---------------------------------------------------------------------------
# Helper Functions
# ---------------------------------------------------------------------------
log_info() {
    echo "[INFO]  $(date '+%Y-%m-%d %H:%M:%S') $*"
}

log_warn() {
    echo "[WARN]  $(date '+%Y-%m-%d %H:%M:%S') $*" >&2
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2
    exit 1
}

check_dependencies() {
    local deps=("docker" "git")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            log_error "Required dependency '$dep' is not installed or not in PATH."
        fi
    done
    log_info "All dependencies satisfied."
}

print_build_info() {
    log_info "========================================"
    log_info " Docker Build Configuration"
    log_info "========================================"
    log_info " Registry   : ${DOCKER_REGISTRY}"
    log_info " Namespace  : ${DOCKER_NAMESPACE}"
    log_info " Image      : ${IMAGE_NAME}"
    log_info " Tag        : ${IMAGE_TAG}"
    log_info " Platform   : ${PLATFORM}"
    log_info " Dockerfile : ${DOCKERFILE}"
    log_info " Context    : ${BUILD_CONTEXT}"
    log_info " Git Commit : ${GIT_COMMIT}"
    log_info " Git Branch : ${GIT_BRANCH}"
    log_info " Push Image : ${PUSH_IMAGE}"
    log_info "========================================"
}

build_image() {
    log_info "Building Docker image: ${FULL_IMAGE_NAME}:${IMAGE_TAG}"

    docker build \
        --platform "${PLATFORM}" \
        --file "${DOCKERFILE}" \
        --tag "${FULL_IMAGE_NAME}:${IMAGE_TAG}" \
        --tag "${FULL_IMAGE_NAME}:${DATE_TAG}" \
        --tag "${FULL_IMAGE_NAME}:${GIT_COMMIT}" \
        --label "org.opencontainers.image.created=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --label "org.opencontainers.image.revision=${GIT_COMMIT}" \
        --label "org.opencontainers.image.source=https://github.com/devopscorner/devopscorner-container" \
        --label "org.opencontainers.image.version=${IMAGE_TAG}" \
        "${BUILD_CONTEXT}"

    log_info "Build completed successfully."
}

push_image() {
    if [[ "${PUSH_IMAGE}" == "true" ]]; then
        log_info "Pushing image tags to registry..."
        docker push "${FULL_IMAGE_NAME}:${IMAGE_TAG}"
        docker push "${FULL_IMAGE_NAME}:${DATE_TAG}"
        docker push "${FULL_IMAGE_NAME}:${GIT_COMMIT}"
        log_info "Push completed successfully."
    else
        log_warn "Skipping push (PUSH_IMAGE=${PUSH_IMAGE}). Set PUSH_IMAGE=true to push."
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
    check_dependencies
    print_build_info

    if [[ ! -f "${DOCKERFILE}" ]]; then
        log_error "Dockerfile not found at path: ${DOCKERFILE}"
    fi

    build_image
    push_image

    log_info "Docker build script finished."
}

main "$@"
