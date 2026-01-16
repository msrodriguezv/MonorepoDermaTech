#!/bin/bash
# ==============================================================================
# SCRIPT: deploy-all.sh
# PURPOSE: Orchestrates the deployment of the entire infrastructure across 
#          multiple AWS accounts (Events, State, Nodes, Gateways).
# USAGE:   ./deploy-all.sh [plan|apply|destroy]
# ==============================================================================

ACTION=$1

if [[ -z "$ACTION" ]]; then
    echo "Usage: ./deploy-all.sh [plan|apply|destroy]"
    exit 1
fi

echo "🚀 STARTING INFRASTRUCTURE ORCHESTRATION: $ACTION"
echo "==================================================="

# List of environments in dependency order
# 1. Events & State (Must exist first so Nodes can connect)
# 2. Nodes (App Logic)
# 3. Gateways (Load Balancers - need Nodes IPs)
ENVIRONMENTS=(
    "account-03-events"
    "account-04-state"
    "account-05-node-a"
    "account-06-node-b"
    "account-01-gateway-qa"
    "account-02-gateway-prod"
)

BASE_PATH="infrastructure/terraform/environments"

for env in "${ENVIRONMENTS[@]}"; do
    echo "---------------------------------------------------"
    echo "🔹 Processing Environment: $env"
    echo "---------------------------------------------------"
    
    cd "$BASE_PATH/$env" || exit
    
    # Initialize if .terraform folder is missing
    if [ ! -d ".terraform" ]; then
        echo "   Initializing Terraform..."
        terraform init -upgrade > /dev/null
    fi

    if [ "$ACTION" == "destroy" ]; then
        # On destroy, we might get errors due to 'prevent_destroy' on EIPs/Disks.
        # We allow it to fail gracefully on those resources.
        echo "   💥 Destroying resources..."
        terraform destroy -auto-approve
    else
        echo "   🛠️  Applying configuration..."
        terraform apply -auto-approve
    fi

    # Return to root for next iteration
    cd - > /dev/null || exit
    
    echo "✅ $env processed."
    sleep 2 # Cool down to avoid API rate limits
done

echo "==================================================="
echo "🎉 INFRASTRUCTURE OPERATION COMPLETED SUCCESSFULLY"
echo "==================================================="