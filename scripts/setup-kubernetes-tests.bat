@echo off
echo 🚀 Setting up Kubernetes environment for tests...

REM Apply ingress if not exists
echo 📡 Applying ingress configuration...
kubectl apply -f ../../src/kubernetes/ingress.yaml

REM Wait for ingress to be ready
echo ⏳ Waiting for ingress to be ready...
ping 127.0.0.1 -n 6 > nul

REM Check if port-forward is already running on port 80
curl -s -H "Host: cinemaabyss.example.com" http://127.0.0.1/health > nul 2>&1
if %ERRORLEVEL% == 0 (
    echo ✅ Port-forward is already working correctly
) else (
    echo 🔄 Starting port-forward for ingress-nginx...
    start /B kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 80:80

    REM Wait for port-forward to be ready
    echo ⏳ Waiting for port-forward to be ready...
    ping 127.0.0.1 -n 9 > nul

    REM Test connection
    curl -s -H "Host: cinemaabyss.example.com" http://127.0.0.1/health > nul 2>&1
    if %ERRORLEVEL% == 0 (
        echo ✅ Port-forward is working correctly
    ) else (
        echo ❌ Port-forward failed to start properly
        exit /b 1
    )
)

echo ✅ Kubernetes environment is ready for tests!
echo 🔗 API accessible at: http://127.0.0.1 with Host: cinemaabyss.example.com