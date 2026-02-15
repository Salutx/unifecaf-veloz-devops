#!/bin/bash

set -e

echo "🚀 Configurando Kubernetes - Loja Veloz"
echo "========================================"
echo ""

# Verificar kubectl
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl não instalado!"
    exit 1
fi

# Verificar conexão com cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Não foi possível conectar ao cluster Kubernetes!"
    echo "   Verifique seu kubeconfig e conexão."
    exit 1
fi

echo "✅ Conectado ao cluster:"
kubectl config current-context
echo ""

# Detectar tipo de cluster
CONTEXT=$(kubectl config current-context)
if [[ "$CONTEXT" == *"docker-desktop"* ]]; then
    CLUSTER_TYPE="docker-desktop"
    echo "🐳 Cluster detectado: Docker Desktop Kubernetes"
elif [[ "$CONTEXT" == *"kind"* ]]; then
    CLUSTER_TYPE="kind"
    echo "📦 Cluster detectado: Kind"
elif [[ "$CONTEXT" == *"minikube"* ]]; then
    CLUSTER_TYPE="minikube"
    echo "🔧 Cluster detectado: Minikube"
elif [[ "$CONTEXT" == *"gke"* ]] || [[ "$CONTEXT" == *"gcp"* ]]; then
    CLUSTER_TYPE="gke"
    echo "☁️  Cluster detectado: Google Kubernetes Engine (GKE)"
elif [[ "$CONTEXT" == *"eks"* ]] || [[ "$CONTEXT" == *"aws"* ]]; then
    CLUSTER_TYPE="eks"
    echo "☁️  Cluster detectado: Amazon EKS"
else
    CLUSTER_TYPE="generic"
    echo "🔍 Cluster genérico detectado"
fi

echo ""

# Build de imagens (apenas para clusters locais)
if [[ "$CLUSTER_TYPE" == "docker-desktop" ]]; then
    echo "🔨 Construindo imagens Docker (Docker Desktop)..."
    cd "$(dirname "$0")/.."
    
    docker build -t loja-veloz/api-gateway:latest ./services/api-gateway
    docker build -t loja-veloz/pedidos:latest ./services/pedidos
    docker build -t loja-veloz/pagamentos:latest ./services/pagamentos
    docker build -t loja-veloz/estoque:latest ./services/estoque
    
    echo "✅ Imagens construídas"
    
elif [[ "$CLUSTER_TYPE" == "kind" ]]; then
    echo "🔨 Construindo e carregando imagens no Kind..."
    cd "$(dirname "$0")/.."
    
    docker build -t loja-veloz/api-gateway:latest ./services/api-gateway
    docker build -t loja-veloz/pedidos:latest ./services/pedidos
    docker build -t loja-veloz/pagamentos:latest ./services/pagamentos
    docker build -t loja-veloz/estoque:latest ./services/estoque
    
    kind load docker-image loja-veloz/api-gateway:latest
    kind load docker-image loja-veloz/pedidos:latest
    kind load docker-image loja-veloz/pagamentos:latest
    kind load docker-image loja-veloz/estoque:latest
    
    echo "✅ Imagens carregadas no Kind"
    
elif [[ "$CLUSTER_TYPE" == "minikube" ]]; then
    echo "🔨 Construindo imagens no Minikube..."
    eval $(minikube docker-env)
    cd "$(dirname "$0")/.."
    
    docker build -t loja-veloz/api-gateway:latest ./services/api-gateway
    docker build -t loja-veloz/pedidos:latest ./services/pedidos
    docker build -t loja-veloz/pagamentos:latest ./services/pagamentos
    docker build -t loja-veloz/estoque:latest ./services/estoque
    
    echo "✅ Imagens construídas no Minikube"
else
    echo "⚠️  Cluster em nuvem/remoto detectado"
    echo "    As imagens devem estar em um registry (Docker Hub, GCR, ECR, etc.)"
    echo "    Certifique-se de fazer push das imagens antes de continuar."
    echo ""
    read -p "Deseja continuar? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

cd "$(dirname "$0")/.."
echo ""

# Criar namespace
echo "📦 Criando namespace..."
kubectl apply -f k8s/base/namespace.yaml

# Aplicar ConfigMaps e Secrets
echo "🔐 Aplicando ConfigMaps e Secrets..."
kubectl apply -f k8s/base/configmap.yaml
kubectl apply -f k8s/base/secrets.yaml

# Deploy PostgreSQL
echo "🐘 Deployando PostgreSQL..."
kubectl apply -f k8s/base/postgres/

echo "⏳ Aguardando PostgreSQL..."
kubectl wait --for=condition=ready pod \
  -l app=postgres \
  -n loja-veloz \
  --timeout=90s 2>/dev/null || echo "  ⚠️  Timeout - verifique manualmente"

# Deploy RabbitMQ
echo "🐰 Deployando RabbitMQ..."
kubectl apply -f k8s/base/rabbitmq/

echo "⏳ Aguardando RabbitMQ..."
kubectl wait --for=condition=ready pod \
  -l app=rabbitmq \
  -n loja-veloz \
  --timeout=90s 2>/dev/null || echo "  ⚠️  Timeout - verifique manualmente"

# Deploy ConfigMap do API Gateway
echo "🌐 Aplicando configuração do API Gateway..."
kubectl apply -f k8s/base/api-gateway/configmap.yaml

# Deploy microserviços
echo "🚀 Deployando microserviços..."
kubectl apply -f k8s/base/pedidos/
kubectl apply -f k8s/base/pagamentos/
kubectl apply -f k8s/base/estoque/
kubectl apply -f k8s/base/api-gateway/

echo ""
echo "⏳ Aguardando pods ficarem prontos (30s)..."
sleep 30

echo ""
echo "📊 Status dos Pods:"
kubectl get pods -n loja-veloz

echo ""
echo "📋 Services:"
kubectl get svc -n loja-veloz

echo ""
echo "✅ Deploy concluído!"
echo ""

# Instruções de acesso baseadas no tipo de cluster
if [[ "$CLUSTER_TYPE" == "docker-desktop" ]]; then
    echo "🌐 Acesse a aplicação:"
    echo "   http://localhost:30080"
    echo ""
elif [[ "$CLUSTER_TYPE" == "kind" ]]; then
    echo "🌐 Acesse a aplicação:"
    echo "   http://localhost:8080"
    echo ""
elif [[ "$CLUSTER_TYPE" == "minikube" ]]; then
    echo "🌐 Para acessar, execute:"
    echo "   minikube service api-gateway-service -n loja-veloz"
    echo ""
else
    echo "🌐 Para acessar, configure um LoadBalancer ou Ingress"
    echo ""
    echo "   Opção 1 - Port Forward (teste local):"
    echo "   kubectl port-forward -n loja-veloz svc/api-gateway-service 8080:8080"
    echo ""
    echo "   Opção 2 - NodePort (se cluster tem IPs acessíveis):"
    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
    if [ -z "$NODE_IP" ]; then
        NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
    fi
    echo "   http://$NODE_IP:30080"
    echo ""
fi

echo "📌 Comandos úteis:"
echo "  Ver pods:     kubectl get pods -n loja-veloz"
echo "  Ver logs:     kubectl logs -f deployment/api-gateway -n loja-veloz"
echo "  Port-forward: kubectl port-forward -n loja-veloz svc/api-gateway-service 8080:8080"
echo ""