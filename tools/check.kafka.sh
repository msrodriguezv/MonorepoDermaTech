#!/bin/bash

# Kafka Health Check Script
# Purpose: Verify Kafka cluster is ready to accept producer/consumer connections
# Usage: ./scripts/check-kafka.sh
# Exit codes: 0 = healthy, 1 = unhealthy

set -e

echo "================================================"
echo "🔍 KAFKA HEALTH CHECK"
echo "================================================"
echo ""

# ANSI color codes for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONTAINER_KAFKA="dermatech_kafka"
CONTAINER_ZOOKEEPER="dermatech_zookeeper"
CONTAINER_INIT="dermatech_init_kafka"
TOPIC_REQUIRED="booking.events"

# Helper function to print status
print_status() {
    local status=$1
    local message=$2
    
    if [ "$status" = "success" ]; then
        echo -e "${GREEN}✅ ${message}${NC}"
    elif [ "$status" = "error" ]; then
        echo -e "${RED}❌ ${message}${NC}"
    elif [ "$status" = "warning" ]; then
        echo -e "${YELLOW}⚠️  ${message}${NC}"
    else
        echo -e "${BLUE}ℹ️  ${message}${NC}"
    fi
}

# 1. Check if Kafka container is running
echo "1️⃣  Checking Kafka container status..."
if docker ps | grep -q "$CONTAINER_KAFKA"; then
    print_status "success" "Kafka container is running"
else
    print_status "error" "Kafka container is NOT running"
    echo "   Fix: docker-compose up -d kafka"
    exit 1
fi
echo ""

# 2. Check if Zookeeper container is running
echo "2️⃣  Checking Zookeeper container status..."
if docker ps | grep -q "$CONTAINER_ZOOKEEPER"; then
    print_status "success" "Zookeeper is running"
else
    print_status "error" "Zookeeper is NOT running"
    echo "   Fix: docker-compose up -d zookeeper"
    exit 1
fi
echo ""

# 3. Verify Kafka broker is responsive
echo "3️⃣  Testing Kafka broker connectivity..."
if docker exec "$CONTAINER_KAFKA" kafka-broker-api-versions \
    --bootstrap-server localhost:9092 > /dev/null 2>&1; then
    print_status "success" "Kafka broker is responsive"
else
    print_status "error" "Kafka broker is not responding"
    echo "   This usually means Kafka is still starting up"
    echo "   Wait 30-60 seconds and try again"
    exit 1
fi
echo ""

# 4. List all topics in the cluster
echo "4️⃣  Listing available topics..."
TOPICS=$(docker exec "$CONTAINER_KAFKA" kafka-topics \
    --bootstrap-server localhost:9092 --list 2>/dev/null)

if [ -z "$TOPICS" ]; then
    print_status "warning" "No topics found in cluster"
    echo "   Fix: docker-compose up -d init-kafka"
    echo "   Then wait for init-kafka to complete (check logs)"
else
    print_status "success" "Topics found:"
    echo "$TOPICS" | while read topic; do
        echo "   📌 $topic"
    done
fi
echo ""

# 5. Verify required topic exists with leader
echo "5️⃣  Verifying topic '$TOPIC_REQUIRED'..."
if echo "$TOPICS" | grep -q "$TOPIC_REQUIRED"; then
    print_status "success" "Topic '$TOPIC_REQUIRED' exists"
    
    echo ""
    echo "   📊 Topic details:"
    TOPIC_DESC=$(docker exec "$CONTAINER_KAFKA" kafka-topics \
        --bootstrap-server localhost:9092 \
        --describe \
        --topic "$TOPIC_REQUIRED" 2>/dev/null)
    
    echo "$TOPIC_DESC"
    
    # Check if topic has a leader assigned
    if echo "$TOPIC_DESC" | grep -q "Leader:.*[0-9]"; then
        print_status "success" "Topic has elected leader (ready for use)"
    else
        print_status "error" "Topic has NO leader assigned"
        echo "   This is the root cause of your error!"
        echo "   Fix: docker-compose restart kafka"
        echo "   Then: docker-compose up -d init-kafka"
        exit 1
    fi
else
    print_status "error" "Topic '$TOPIC_REQUIRED' does NOT exist"
    echo "   Fix: docker-compose up -d init-kafka"
    exit 1
fi
echo ""

# 6. Check consumer groups (if any services are running)
echo "6️⃣  Checking for active consumer groups..."
GROUPS=$(docker exec "$CONTAINER_KAFKA" kafka-consumer-groups \
    --bootstrap-server localhost:9092 --list 2>/dev/null)

if [ -z "$GROUPS" ]; then
    print_status "info" "No consumer groups active yet"
    echo "   This is normal if microservices haven't started"
else
    print_status "success" "Active consumer groups:"
    echo "$GROUPS" | while read group; do
        echo "   👥 $group"
    done
fi
echo ""

# 7. Test message production capability
echo "7️⃣  Testing message production..."
TEST_MSG='{"test":"health-check","timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}'

if echo "$TEST_MSG" | docker exec -i "$CONTAINER_KAFKA" kafka-console-producer \
    --bootstrap-server localhost:9092 \
    --topic "$TOPIC_REQUIRED" > /dev/null 2>&1; then
    print_status "success" "Test message sent successfully"
else
    print_status "error" "Failed to send test message"
    echo "   This indicates a serious problem with Kafka"
    exit 1
fi
echo ""

# 8. Check init-kafka container logs (if exists)
echo "8️⃣  Checking init-kafka status..."
if docker ps -a | grep -q "$CONTAINER_INIT"; then
    INIT_STATUS=$(docker inspect -f '{{.State.Status}}' "$CONTAINER_INIT" 2>/dev/null || echo "not-found")
    
    case "$INIT_STATUS" in
        "running")
            print_status "info" "init-kafka is currently running"
            ;;
        "exited")
            EXIT_CODE=$(docker inspect -f '{{.State.ExitCode}}' "$CONTAINER_INIT")
            if [ "$EXIT_CODE" = "0" ]; then
                print_status "success" "init-kafka completed successfully (exit code 0)"
            else
                print_status "error" "init-kafka failed (exit code $EXIT_CODE)"
                echo "   Check logs: docker logs $CONTAINER_INIT"
            fi
            ;;
        *)
            print_status "warning" "init-kafka status: $INIT_STATUS"
            ;;
    esac
else
    print_status "warning" "init-kafka container not found"
    echo "   This is normal if you haven't run it yet"
    echo "   Run: docker-compose up -d init-kafka"
fi
echo ""

# Summary
echo "================================================"
echo "🎉 HEALTH CHECK COMPLETE"
echo "================================================"
echo ""
echo "💡 Useful commands:"
echo "   View Kafka logs:      docker logs $CONTAINER_KAFKA -f"
echo "   View init-kafka logs: docker logs $CONTAINER_INIT"
echo "   Restart Kafka:        docker-compose restart kafka"
echo "   Recreate topics:      docker-compose up -d --force-recreate init-kafka"
echo "   Consume messages:     docker exec -it $CONTAINER_KAFKA kafka-console-consumer \\"
echo "                         --bootstrap-server localhost:9092 \\"
echo "                         --topic $TOPIC_REQUIRED \\"
echo "                         --from-beginning"
echo ""