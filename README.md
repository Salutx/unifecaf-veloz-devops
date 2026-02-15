# 🚀 Loja Veloz - Projeto DevOps Demo

Projeto de demonstração de arquitetura cloud-native com foco em **práticas DevOps**, incluindo:

- ✅ Containerização com Docker (multi-stage builds)
- ✅ Orquestração com Kubernetes
- ✅ CI/CD com GitHub Actions
- ✅ Observabilidade (Prometheus + Grafana)
- ✅ IaC com Terraform
- ✅ Boas práticas de segurança

> **Nota:** Este projeto usa serviços mock (Nginx) para demonstrar infraestrutura DevOps sem necessidade de desenvolver aplicações reais.

## 🏗️ Arquitetura

```
┌─────────────┐
│ API Gateway │ (Nginx - Reverse Proxy)
└──────┬──────┘
       │
   ┌───┴────────────────┬─────────────┐
   │                    │             │
┌──▼──────┐  ┌─────────▼──┐  ┌───────▼────┐
│ Pedidos │  │ Pagamentos │  │  Estoque   │
└─────────┘  └────────────┘  └────────────┘
   (Nginx)      (Nginx)         (Nginx)
```

## 🚀 Quick Start

### Pré-requisitos

- Docker 24+
- Docker Compose 2.x
- kubectl (opcional, para K8s)

### 1. Clone o repositório

```bash
git clone [https://github.com/your-org/loja-veloz.git](https://github.com/Salutx/unifecaf-veloz-devops.git)
cd unifecaf-veloz-devops
```

### 2. Suba o ambiente local

```bash
./scripts/setup-kubernetes.sh
```

### 3. Teste os endpoints

```bash
./scripts/test-endpoints.sh
```

### 4. Acesse os serviços

- 🌐 **API Gateway**: http://localhost:8080
- 📦 **Pedidos**: http://localhost:8081
- 💳 **Pagamentos**: http://localhost:8082
- 📊 **Estoque**: http://localhost:8083
- 📈 **Prometheus**: http://localhost:9090
- 📊 **Grafana**: http://localhost:3000 (admin/admin)

Observação: Caso não funcione o proxy-reverse, utilize a inicialização pelo minikube service:
`minikube service [service-name] -n loja-veloz`

## 🧪 Testando

```bash
# Health check de todos os serviços
curl http://localhost:8080/health
curl http://localhost:8081/health
curl http://localhost:8082/health
curl http://localhost:8083/health

# Via API Gateway
curl http://localhost:8080/api/pedidos
curl http://localhost:8080/api/pagamentos
curl http://localhost:8080/api/estoque
```

## ☸️ Deploy no Kubernetes

```bash
# Aplicar manifests
kubectl apply -f k8s/base/

# Verificar pods
kubectl get pods -n loja-veloz

# Verificar serviços
kubectl get svc -n loja-veloz

# Logs
kubectl logs -f deployment/pedidos -n loja-veloz
```

## 📊 Observabilidade

### Prometheus

- Acesse: http://localhost:9090
- Queries úteis:

```
  rate(nginx_http_requests_total[5m])
```

### Grafana

- Acesse: http://localhost:3000
- Login: admin/admin
- Datasource: Prometheus (http://prometheus:9090)

## 🔒 Segurança Implementada

- ✅ Containers rodam como usuário não-root
- ✅ Security contexts no Kubernetes
- ✅ Network Policies
- ✅ Scanning de vulnerabilidades com Trivy
- ✅ Resource limits e requests

## 📦 CI/CD

O pipeline automatiza:

1. **Build**: Constrói imagens Docker
2. **Scan**: Verifica vulnerabilidades
3. **Push**: Envia para registry
4. **Deploy**: Atualiza Kubernetes
5. **Verify**: Confirma saúde dos pods

## 🛠️ Comandos Úteis

```bash
# Parar tudo
cd docker && docker-compose down

# Ver logs
docker-compose logs -f

# Rebuild
docker-compose build --no-cache

# Limpar tudo
docker-compose down -v && docker system prune -af
```

## 📚 Documentação Adicional

- [Arquitetura Detalhada](docs/architecture.md)
- [Runbook de Operação](docs/runbook.md)
- [Guia de Troubleshooting](docs/troubleshooting.md)

## 📄 Licença

MIT License
