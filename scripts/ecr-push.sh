#!/usr/bin/env bash
# =============================================================================
# ECR Push Script
# Builds and pushes Docker images to Amazon Elastic Container Registry (ECR)
# =============================================================================
# Usage:
#   ./scripts/ecr-push.sh [OPTIONS]
#
# Options:
#   -r, --region       AWS region (default: us-east-1)
#   -a, --account-id   AWS account ID
#   -p, --profile      AWS CLI profile (default: default)
#   -i, --image        Image name to push
#   -t, --tag          Image tag (default: latest)
#   -h, --help         Show this help message
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Default values
# ---------------------------------------------------------------------------
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID=""
AWS_PROFILE="default"
IMAGE_NAME=""
IMAGE_TAG="latest"
ECR_REGISTRY=""

# ---------------------------------------------------------------------------
# Colors for output
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ---------------------------------------------------------------------------
# Logging helpers
# ---------------------------------------------------------------------------
log_info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# ---------------------------------------------------------------------------
# Usage / help
# ---------------------------------------------------------------------------
usage() {
  grep '^#' "$0" | sed 's/^# \{0,1\}//'
  exit 0
}

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--region)      AWS_REGION="$2";     shift 2 ;;
    -a|--account-id)  AWS_ACCOUNT_ID="$2"; shift 2 ;;
    -p|--profile)     AWS_PROFILE="$2";    shift 2 ;;
    -i|--image)       IMAGE_NAME="$2";     shift 2 ;;
    -t|--tag)         IMAGE_TAG="$2";      shift 2 ;;
    -h|--help)        usage ;;
    *) log_error "Unknown option: $1"; usage ;;
  esac
done

# ---------------------------------------------------------------------------
# Validate required arguments
# ---------------------------------------------------------------------------
if [[ -z "$IMAGE_NAME" ]]; then
  log_error "Image name is required. Use -i or --image to specify."
  exit 1
fi

if [[ -z "$AWS_ACCOUNT_ID" ]]; then
  log_info "AWS account ID not provided, attempting to detect via STS..."
  AWS_ACCOUNT_ID=$(aws sts get-caller-identity \
    --profile "$AWS_PROFILE" \
    --query 'Account' \
    --output text 2>/dev/null) || {
      log_error "Failed to detect AWS account ID. Please provide it with -a or --account-id."
      exit 1
    }
  log_info "Detected AWS account ID: ${AWS_ACCOUNT_ID}"
fi

ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
ECR_IMAGE="${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"

# ---------------------------------------------------------------------------
# Authenticate Docker with ECR
# ---------------------------------------------------------------------------
log_info "Authenticating Docker with ECR registry: ${ECR_REGISTRY}"
aws ecr get-login-password \
  --region "$AWS_REGION" \
  --profile "$AWS_PROFILE" \
| docker login \
    --username AWS \
    --password-stdin "$ECR_REGISTRY"

# ---------------------------------------------------------------------------
# Ensure ECR repository exists
# ---------------------------------------------------------------------------
log_info "Ensuring ECR repository '${IMAGE_NAME}' exists..."
aws ecr describe-repositories \
  --repository-names "$IMAGE_NAME" \
  --region "$AWS_REGION" \
  --profile "$AWS_PROFILE" > /dev/null 2>&1 || {
    log_warn "Repository not found. Creating '${IMAGE_NAME}'..."
    aws ecr create-repository \
      --repository-name "$IMAGE_NAME" \
      --region "$AWS_REGION" \
      --profile "$AWS_PROFILE" \
      --image-scanning-configuration scanOnPush=true \
      --encryption-configuration encryptionType=AES256
    log_info "Repository created successfully."
  }

# ---------------------------------------------------------------------------
# Tag and push the image
# ---------------------------------------------------------------------------
log_info "Tagging local image '${IMAGE_NAME}:${IMAGE_TAG}' -> '${ECR_IMAGE}'"
docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${ECR_IMAGE}"

log_info "Pushing image to ECR: ${ECR_IMAGE}"
docker push "${ECR_IMAGE}"

log_info "Image pushed successfully: ${ECR_IMAGE}"
