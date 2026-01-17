#!/bin/bash
set -e # Detener script si hay cualquier error

echo "======================================================="
echo "🚀 INICIANDO DESPLIEGUE DE INFRAESTRUCTURA DERMATECH"
echo "======================================================="

# Función para ejecutar terraform
run_terraform() {
    dir=$1
    target=$2
    echo "-------------------------------------------------------"
    echo "📂 Procesando: $dir"
    cd "infrastructure/terraform/environments/$dir"
    
    # Inicializar si no existe .terraform
    if [ ! -d ".terraform" ]; then
        terraform init
    fi

    if [ -z "$target" ]; then
        echo "⚡ Aplicando configuración completa..."
        terraform apply -auto-approve
    else
        echo "🎯 Aplicando SOLO objetivos base (Red y Cómputo)..."
        terraform apply -target=module.networking -target=module.compute -auto-approve
    fi
    
    cd - > /dev/null # Volver a la raíz
    echo "✅ $dir completado."
}

# --- FASE 1: CIMIENTOS (Solo VPC y EC2, sin Peering) ---
echo ""
echo "🏗️  FASE 1: Levantando VPCs y Servidores (Spokes)..."
# Usamos -target para evitar que falle buscando el Peering que QA aún no envía
run_terraform "account-02-events" "partial"
run_terraform "account-03-state" "partial"
run_terraform "account-04-node-a" "partial"
run_terraform "account-06-node-b" "partial"

# --- FASE 2: HUB CENTRAL (QA) ---
echo ""
echo "Mw  FASE 2: Desplegando QA y lanzando Peticiones de Peering..."
# QA se despliega completo. Ahora encontrará las VPCs creadas en Fase 1.
run_terraform "account-01-qa" ""

# --- FASE 3: CONEXIÓN FINAL (Aceptar Peering y Rutas) ---
echo ""
echo "🤝 FASE 3: Aceptando Peerings y Configurando Rutas..."
# Ahora corremos full apply. Encontrarán las peticiones de QA y las aceptarán.
run_terraform "account-02-events" ""
run_terraform "account-03-state" ""
run_terraform "account-04-node-a" ""
run_terraform "account-06-node-b" ""

echo "======================================================="
echo "🏆 INFRAESTRUCTURA DESPLEGADA EXITOSAMENTE AL 100%"
echo "======================================================="