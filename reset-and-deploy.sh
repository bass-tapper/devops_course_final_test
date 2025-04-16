#!/bin/bash

set -e

APP_NAME="rick"
HELM_CHART_PATH="./sprint4/helm/rick-api"
IMAGE_NAME="rick-api"
IMAGE_TAG="latest"
NAMESPACE="default"
PORT_CONTAINER=5555
PORT_FORWARD=5555
INGRESS_HOST="rick.local"

echo "[INFO] Cleaning up previous resources..."
kubectl delete all --all --namespace "$NAMESPACE" || true
kubectl delete ingress --all --namespace "$NAMESPACE" || true

echo "[INFO] Verifying tunnel is running..."
if ! pgrep -f "minikube tunnel" > /dev/null; then
    echo "[INFO] Please start 'minikube tunnel' in another terminal."
    exit 1
fi

echo "[INFO] Evaluating Minikube Docker environment..."
eval "$(minikube docker-env)"

echo "[INFO] Building Docker image..."
docker build -t $IMAGE_NAME:$IMAGE_TAG ./sprint2/app

echo "[INFO] Deploying with Helm..."
helm upgrade --install $APP_NAME $HELM_CHART_PATH --namespace "$NAMESPACE" --create-namespace

echo "[INFO] Waiting for pod to be ready..."
while true; do
    STATUS=$(kubectl get pods -l app.kubernetes.io/name=$APP_NAME -o jsonpath='{.items[0].status.phase}')
    if [ "$STATUS" = "Running" ]; then
        break
    fi
    echo "  → Waiting for pod to become Running..."
    sleep 2
done

POD_NAME=$(kubectl get pods -l app.kubernetes.io/name=$APP_NAME -o jsonpath='{.items[0].metadata.name}')

echo "[INFO] Forwarding local port $PORT_FORWARD → container port $PORT_CONTAINER"
kubectl port-forward "$POD_NAME" $PORT_FORWARD:$PORT_CONTAINER &
FORWARD_PID=$!
sleep 2

echo "[INFO] Curling healthcheck via port-forward..."
curl --max-time 10 "http://localhost:$PORT_FORWARD/healthcheck" || echo "[ERROR] Port-forwarded healthcheck failed"

echo "[INFO] Testing Ingress routing..."
curl --max-time 10 "http://$INGRESS_HOST/healthcheck" || echo "[ERROR] Ingress healthcheck failed"

kill $FORWARD_PID

echo "[INFO] Done."
