@echo off
echo 🚀 CinemaAbyss - Full Deployment and Testing
echo ============================================

REM Check if kubectl is available
kubectl version --client > nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ❌ kubectl is not available. Please install kubectl first.
    exit /b 1
)

echo 📦 Deploying all services to Kubernetes...

REM Apply all Kubernetes manifests
echo 🔄 Applying namespace...
kubectl apply -f src/kubernetes/namespace.yaml 2>nul

echo 🔄 Applying PostgreSQL...
kubectl apply -f src/kubernetes/postgres.yaml

echo 🔄 Applying Kafka & Zookeeper...
kubectl apply -f src/kubernetes/kafka.yaml
kubectl apply -f src/kubernetes/zookeeper.yaml

echo 🔄 Applying microservices...
kubectl apply -f src/kubernetes/monolith.yaml
kubectl apply -f src/kubernetes/movies-service.yaml
kubectl apply -f src/kubernetes/events-service.yaml
kubectl apply -f src/kubernetes/proxy-service.yaml

echo 🔄 Applying ingress...
kubectl apply -f src/kubernetes/ingress.yaml

echo ⏳ Waiting for pods to be ready...
timeout /t 30 /nobreak > nul

REM Wait for all pods to be running
echo 📋 Checking pod status...
kubectl get pods -n cinemaabyss

echo 🧪 Setting up tests environment...
call scripts\setup-kubernetes-tests.bat

if %ERRORLEVEL% neq 0 (
    echo ❌ Failed to setup test environment
    exit /b 1
)

echo 🧪 Running Kubernetes tests...
cd tests\postman
npm run test:kubernetes

echo ✅ Deployment and testing completed!
echo 🌐 Services accessible at:
echo    - API: http://127.0.0.1 (with Host: cinemaabyss.example.com)
echo    - Or add to hosts file: 127.0.0.1 cinemaabyss.example.com