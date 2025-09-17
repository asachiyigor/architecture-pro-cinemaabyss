#!/bin/bash

echo "🚀 Setting up Kubernetes environment for tests..."

# Apply ingress if not exists
echo "📡 Applying ingress configuration..."
kubectl apply -f src/kubernetes/ingress.yaml

# Wait for ingress to be ready
echo "⏳ Waiting for ingress to be ready..."
sleep 5

# Check if port-forward is already running on port 80
if lsof -Pi :80 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "✅ Port 80 is already in use (port-forward likely running)"
else
    echo "🔄 Starting port-forward for ingress-nginx..."
    kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 80:80 &
    PORTFORWARD_PID=$!
    echo "📝 Port-forward PID: $PORTFORWARD_PID"

    # Wait for port-forward to be ready
    echo "⏳ Waiting for port-forward to be ready..."
    sleep 5

    # Test connection
    if curl -s -H "Host: cinemaabyss.example.com" http://127.0.0.1/health > /dev/null; then
        echo "✅ Port-forward is working correctly"
    else
        echo "❌ Port-forward failed to start properly"
        exit 1
    fi
fi

echo "✅ Kubernetes environment is ready for tests!"
echo "🔗 API accessible at: http://127.0.0.1 with Host: cinemaabyss.example.com"