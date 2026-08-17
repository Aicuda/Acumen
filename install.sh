#!/usr/bin/env sh

set -e

MS_YAML=compose.ms.yaml
AS_YAML=compose.as.yaml
SS_YAML=compose.ss.yaml

cleanup() {
    rm -f "$MS_YAML" "$AS_YAML" "$SS_YAML"
}

trap cleanup EXIT

export PRODUCT_HOME="${PRODUCT_HOME:-/opt/aicuda/acumen}"
export PRODUCT_NAME="${PRODUCT_NAME:-acumen}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
IMAGE_PREFIX="${IMAGE_PREFIX:-quay.io/aicuda}"

MS_IMAGE_TAG="${MS_IMAGE_TAG:-${IMAGE_TAG}}"
AS_IMAGE_TAG="${AS_IMAGE_TAG:-${IMAGE_TAG}}"
SS_IMAGE_TAG="${SS_IMAGE_TAG:-${IMAGE_TAG}}"

if [ -n "$MS_IMAGE" ]; then
    export MS_IMAGE=${MS_IMAGE}
else
    export MS_IMAGE="${IMAGE_PREFIX}/${PRODUCT_NAME}-ms:${MS_IMAGE_TAG}"
fi
if [ -n "$AS_IMAGE" ]; then
    export AS_IMAGE=${AS_IMAGE}
else
    export AS_IMAGE="${IMAGE_PREFIX}/${PRODUCT_NAME}-as:${AS_IMAGE_TAG}"
fi
if [ -n "$SS_IMAGE" ]; then
    export SS_IMAGE=${SS_IMAGE}
else
    export SS_IMAGE="${IMAGE_PREFIX}/${PRODUCT_NAME}-ss:${SS_IMAGE_TAG}"
fi

if [ -n "$MS_HOST" ] && [ "$MS_HOST" != "127.0.0.1" ] && [ "$MS_HOST" != "host-gateway" ]; then
    export MS_HOST="$MS_HOST"
fi
if [ -n "$AS_HOST" ] && [ "$AS_HOST" != "127.0.0.1" ] && [ "$AS_HOST" != "host-gateway" ]; then
    export AS_HOST="$AS_HOST"
fi
if [ -n "$SS_HOST" ] && [ "$SS_HOST" != "127.0.0.1" ] && [ "$SS_HOST" != "host-gateway" ]; then
    export SS_HOST="$SS_HOST"
fi

if [ -n "$TIMESCALEDB_IMAGE" ]; then
    export TIMESCALEDB_IMAGE="$TIMESCALEDB_IMAGE"
fi


MODELS_DIR="${PRODUCT_HOME}/models"
LOG_DIR="${PRODUCT_HOME}/logs"
VIDEOS_METADATA_DIR="${PRODUCT_HOME}/metadata/videos"
TIMESCALEDB_METADATA_DIR="${PRODUCT_HOME}/metadata/pgdata"
RECORDINGS_METADATA_DIR="${PRODUCT_HOME}/metadata/recordings"
SNAPSHOTS_METADATA_DIR="${PRODUCT_HOME}/metadata/snapshots"

if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo -E"
else
    SUDO=""
fi
if docker compose version >/dev/null 2>&1; then
    COMPOSE="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE="docker-compose"
else
    echo "Docker Compose is not installed." >&2
    exit 1
fi

$SUDO mkdir -p "$VIDEOS_METADATA_DIR" "$TIMESCALEDB_METADATA_DIR" \
   "$MODELS_DIR" "$LOG_DIR" "$RECORDINGS_METADATA_DIR" "$SNAPSHOTS_METADATA_DIR"
$SUDO chown -R 1000 "$TIMESCALEDB_METADATA_DIR"
$SUDO chmod -R 777 "$PRODUCT_HOME"

cd "$PRODUCT_HOME"

echo "Start to pull the image ${MS_IMAGE}"
$SUDO docker pull $MS_IMAGE \
    || echo "Unable to pull the image ${MS_IMAGE}. Falling back to the local image."
$SUDO docker run --rm $MS_IMAGE cat /opt/aicuda/acumen-ms/compose.yaml > "$MS_YAML"
echo "Start to pull the image ${AS_IMAGE}"
$SUDO docker pull $AS_IMAGE \
    || echo "Unable to pull the image ${AS_IMAGE}. Falling back to the local image."
$SUDO docker run --rm --entrypoint=cat $AS_IMAGE /opt/aicuda/acumen-as/compose.yaml > "$AS_YAML"
echo "Start to pull the image ${SS_IMAGE}"
$SUDO docker pull $SS_IMAGE \
    || echo "Unable to pull the image ${SS_IMAGE}. Falling back to the local image."
$SUDO docker run --rm --entrypoint=cat $SS_IMAGE /opt/aicuda/acumen-ss/compose.yaml > "$SS_YAML"

$SUDO $COMPOSE -f "$MS_YAML" -f "$AS_YAML" -f "$SS_YAML" config > compose.yaml 2>/dev/null
$SUDO $COMPOSE down --remove-orphans
echo "Start containers..."
$SUDO $COMPOSE up -d
