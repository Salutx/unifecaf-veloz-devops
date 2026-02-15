#!/bin/bash

set -e

echo "🧪 Testando Endpoints - Loja Veloz"
echo "==================================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

test_endpoint() {
    local name=$1
    local url=$2
    
    echo -n "Testing $name... "
    response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    
    if [ "$response" = "200" ]; then
        echo -e "${GREEN}✅ OK${NC} (HTTP $response)"
        return 0
    else
        echo -e "${RED}❌ FAIL${NC} (HTTP $response)"
        return 1
    fi
}

# Detectar ambiente
if docker ps 2>/dev/null | grep -q "loja-veloz-api-gateway"; then
    echo "📦 Ambiente: Docker Compose"
    BASE_URL="http://localhost:8080"
    DIRECT_ACCESS=true
    
elif kubectl get namespace loja-veloz &> /dev/null; then
    echo "☸️  Ambiente: Kubernetes"
    
    CONTEXT=$(kubectl config current-context)
    
    # Detectar tipo de cluster
    if [[ "$CONTEXT" == *"docker-desktop"* ]]; then
        echo "🐳 Cluster: Docker Desktop"
        BASE_URL="http://localhost:30080"
        DIRECT_ACCESS=true
        
    elif [[ "$CONTEXT" == *"kind"* ]]; then
        echo "📦 Cluster: Kind"
        BASE_URL="http://localhost:8080"
        DIRECT_ACCESS=true
        
    elif [[ "$CONTEXT" == *"minikube"* ]]; then
        echo "🔧 Cluster: Minikube"
        BASE_URL=$(minikube service api-gateway-service -n loja-veloz --url 2>/dev/null)
        DIRECT_ACCESS=true
        
    else
        echo "🔍 Cluster: Genérico/Remoto"
        echo "⚡ Usando port-forward para acesso..."
        
        # Verificar se já existe port-forward
        if lsof -i :8080 &> /dev/null; then
            echo "  ℹ️  Port-forward já está ativo na porta 8080"
        else
            echo "  🔌 Iniciando port-forward..."
            kubectl port-forward -n loja-veloz svc/api-gateway-service 8080:8080 > /dev/null 2>&1 &
            PORT_FORWARD_PID=$!
            sleep 3
        fi
        
        BASE_URL="http://localhost:8080"
        DIRECT_ACCESS=false
    fi
else
    echo -e "${RED}❌ Nenhum ambiente detectado!${NC}"
    exit 1
fi

echo "🌐 Base URL: $BASE_URL"
echo ""

# Testar API Gateway
echo -e "${BLUE}🏥 API Gateway:${NC}"
test_endpoint "  Health" "$BASE_URL/health"
echo ""

# Testar Microserviços via Gateway
echo -e "${BLUE}📦 Serviço de Pedidos (via Gateway):${NC}"
test_endpoint "  /api/pedidos/health    " "$BASE_URL/api/pedidos/health"
test_endpoint "  /api/pedidos/data.json " "$BASE_URL/api/pedidos/data.json"
test_endpoint "  /api/pedidos/          " "$BASE_URL/api/pedidos/"
echo ""

echo -e "${BLUE}💳 Serviço de Pagamentos (via Gateway):${NC}"
test_endpoint "  /api/pagamentos/health    " "$BASE_URL/api/pagamentos/health"
test_endpoint "  /api/pagamentos/data.json " "$BASE_URL/api/pagamentos/data.json"
test_endpoint "  /api/pagamentos/          " "$BASE_URL/api/pagamentos/"
echo ""

echo -e "${BLUE}📊 Serviço de Estoque (via Gateway):${NC}"
test_endpoint "  /api/estoque/health    " "$BASE_URL/api/estoque/health"
test_endpoint "  /api/estoque/data.json " "$BASE_URL/api/estoque/data.json"
test_endpoint "  /api/estoque/          " "$BASE_URL/api/estoque/"
echo ""

# Limpar port-forward se foi criado
if [ -n "$PORT_FORWARD_PID" ]; then
    echo "🧹 Encerrando port-forward..."
    kill $PORT_FORWARD_PID 2>/dev/null || true
fi

echo "✅ Todos os testes concluídos!"