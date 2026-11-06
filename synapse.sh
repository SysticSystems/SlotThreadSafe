#!/usr/bin/env bash
# ============================================================================
# Synapse Engine - Containerized Execution Entrypoint
# Location: synapse/synapse.sh
# ============================================================================

set -eo pipefail

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[SYNAPSE INFO]${NC} $1"; }
log_error() { echo -e "${RED}[SYNAPSE ERROR]${NC} $1" >&2; }
log_succ()  { echo -e "${GREEN}[SYNAPSE SUCCESS]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(pwd)"

if [[ $# -lt 1 ]]; then
    log_error "Missing required action! You must explicitly pass either 'create' or 'run'."
    echo -e "Usage:\n  $0 create\n  $0 run [arguments...]"
    exit 1
fi

ACTION="$1"
shift

ENV_FILE="$SCRIPT_DIR/.env"
if [[ ! -f "$ENV_FILE" ]]; then
    log_error "Missing configuration: $ENV_FILE"
    exit 1
fi

set -o allexport
source <(grep -v '^#' "$ENV_FILE" | grep -v '^\s*$')
set +o allexport

if command -v podman &> /dev/null; then
    OCI_BIN="podman"
elif command -v docker &> /dev/null; then
    OCI_BIN="docker"
else
    log_error "Neither Podman nor Docker was found in PATH."
    exit 1
fi

PROJECT_NAME="${PROJECT_NAME:-systic}"
IMAGE_NAME="${PROJECT_NAME}_build_image:latest"
CONTAINER_NAME="${PROJECT_NAME}_build_runner"
DOCKERFILE_PATH="$SCRIPT_DIR/.github/workflows/Dockerfile"
BUILD_CONTEXT="$SCRIPT_DIR/.github/workflows"

PROFILE="${CONAN_PROFILE:-clang21}"
CONAN_CACHE_DIR="$SCRIPT_DIR/.conan/cache/${PROFILE,,}"
mkdir -p "$CONAN_CACHE_DIR"

case "$ACTION" in
    create)
        log_info "Building base environment image '$IMAGE_NAME'..."
        if [[ ! -f "$DOCKERFILE_PATH" ]]; then
            log_error "Dockerfile not found at $DOCKERFILE_PATH"
            exit 1
        fi
        $OCI_BIN build -f "$DOCKERFILE_PATH" -t "$IMAGE_NAME" "$BUILD_CONTEXT"
        log_succ "Environment image created."
        ;;
    run)
        if ! $OCI_BIN image inspect "$IMAGE_NAME" &> /dev/null; then
            log_error "Build image '$IMAGE_NAME' not found. Run '$0 create' first."
            exit 1
        fi

        if $OCI_BIN ps -aq -f name="^/${CONTAINER_NAME}$" | grep -q .; then
            $OCI_BIN rm -f "$CONTAINER_NAME" > /dev/null
        fi

        TTY_ARGS=""
        [[ -t 0 && -t 1 ]] && TTY_ARGS="-it"

        log_info "Launching Synapse from base image library..."

        # Mount host project to /project and execute via image's native ENTRYPOINT
        $OCI_BIN run --rm $TTY_ARGS \
          --name "$CONTAINER_NAME" \
          --network host \
          --security-opt seccomp=unconfined \
          --env-file "$ENV_FILE" \
          -v "$PROJECT_ROOT:/project:z" \
          -v "$CONAN_CACHE_DIR:/root/.conan2:z" \
          -w /project \
          "$IMAGE_NAME" \
          "$@"

        log_succ "Synapse execution finished."
        ;;
    *)
        log_error "Invalid action '$ACTION'."
        exit 1
        ;;
esac