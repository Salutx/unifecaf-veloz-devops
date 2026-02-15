# Setup local

./scripts/setup-local.sh
docker ps
curl http://localhost:8080/health

# Kubernetes

kubectl get nodes
kubectl get pods -n loja-veloz
kubectl get svc -n loja-veloz
kubectl get hpa -n loja-veloz

# Health check

./scripts/test-endpoints.sh

# CI/CD

cat .github/workflows/ci-build.yml | head -20

# Observability

kubectl get pods -n loja-veloz | grep prometheus

# All

kubectl get all -n loja-veloz
