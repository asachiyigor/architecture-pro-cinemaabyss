#!/bin/bash

# Скрипт для генерации PNG изображений из PlantUML диаграмм

echo "🖼️  Generating PlantUML diagrams..."

# Создаем папку для изображений если её нет
mkdir -p diagram/images

# Метод 1: Через PlantUML Server (требует интернет)
generate_via_server() {
    echo "📡 Generating via PlantUML Server..."

    for puml_file in diagram/*.puml; do
        if [ -f "$puml_file" ]; then
            filename=$(basename "$puml_file" .puml)
            echo "  Processing: $filename"

            # Отправляем файл на PlantUML сервер и сохраняем PNG
            curl -X POST \
                --data-binary "@$puml_file" \
                "http://www.plantuml.com/plantuml/png/" \
                -o "diagram/images/${filename}.png" \
                --silent

            if [ $? -eq 0 ] && [ -s "diagram/images/${filename}.png" ]; then
                echo "  ✅ Generated: diagram/images/${filename}.png"
            else
                echo "  ❌ Failed: $filename"
                return 1
            fi
        fi
    done
    return 0
}

# Метод 2: Через локальный PlantUML (требует Java и plantuml.jar)
generate_via_local() {
    if command -v java >/dev/null 2>&1; then
        if [ -f "tools/plantuml.jar" ]; then
            echo "☕ Generating via local PlantUML..."
            cd diagram
            java -jar ../tools/plantuml.jar -tpng -o images/ *.puml
            cd ..
        else
            echo "⬇️  Downloading PlantUML..."
            mkdir -p tools
            curl -L -o tools/plantuml.jar "https://github.com/plantuml/plantuml/releases/download/v1.2024.0/plantuml-1.2024.0.jar"
            if [ $? -eq 0 ]; then
                cd diagram
                java -jar ../tools/plantuml.jar -tpng -o images/ *.puml
                cd ..
            else
                echo "❌ Failed to download PlantUML"
                return 1
            fi
        fi
    else
        echo "❌ Java not found for local generation"
        return 1
    fi
}

# Метод 3: Через npm планtuml пакет
generate_via_npm() {
    if command -v plantuml >/dev/null 2>&1; then
        echo "📦 Generating via npm plantuml..."
        cd diagram
        plantuml -tpng -o images/ *.puml
        cd ..
    else
        echo "📦 Installing plantuml via npm..."
        if command -v npm >/dev/null 2>&1; then
            npm install -g plantuml
            cd diagram
            plantuml -tpng -o images/ *.puml
            cd ..
        else
            echo "❌ npm not found"
            return 1
        fi
    fi
}

# Метод 4: Через Docker
generate_via_docker() {
    if command -v docker >/dev/null 2>&1; then
        echo "🐳 Generating via Docker PlantUML..."
        docker run --rm \
            -v "$(pwd):/workspace" \
            -w /workspace/diagram \
            plantuml/plantuml:latest \
            -tpng -o images/ *.puml

        if [ $? -eq 0 ]; then
            return 0
        else
            echo "❌ Docker generation failed"
            return 1
        fi
    else
        echo "❌ Docker not found"
        return 1
    fi
}

# Проверяем наличие исходных файлов
if [ ! -d "diagram" ] || [ ! -f "diagram/c4-architecture-diagram.puml" ]; then
    echo "❌ No PlantUML files found in diagram/ directory"
    exit 1
fi

# Пробуем разные методы
echo "🚀 Trying different generation methods..."

if generate_via_server; then
    echo "✅ Successfully generated diagrams via server"
elif generate_via_docker; then
    echo "✅ Successfully generated diagrams via Docker"
elif generate_via_npm; then
    echo "✅ Successfully generated diagrams via npm"
elif generate_via_local; then
    echo "✅ Successfully generated diagrams via local PlantUML"
else
    echo "❌ All generation methods failed"
    echo ""
    echo "🔧 Troubleshooting tips:"
    echo "   1. Check internet connection for server method"
    echo "   2. Install Docker for Docker method"
    echo "   3. Install Java for local PlantUML method"
    echo "   4. Install Node.js/npm for npm method"
    exit 1
fi

echo ""
echo "📁 Generated images saved in: diagram/images/"
echo "🔗 You can now reference them in markdown as:"
echo "   ![Architecture Diagram](diagram/images/c4-architecture-diagram.png)"
echo ""
echo "📋 Available files:"
ls -la diagram/images/*.png 2>/dev/null || echo "   No PNG files generated"