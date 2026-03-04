#!/usr/bin/env bash

# Exit pipeline properly if any piped command fails
set -o pipefail

# Optional Slack webhook URL (set via --webhook flag)
WEBHOOK=""

# Number of retry attempts per service (default: 3)
RETRIES=5

# Delay in seconds between retries (default: 2)
DELAY=2

# Array to store service base URLs
URLS=()

# -------- Terminal Colors (for better CLI readability) --------
RED='\033[0;31m'      # Unhealthy
GREEN='\033[0;32m'    # Healthy
YELLOW='\033[1;33m'   # Info / Retry
NC='\033[0m'          # Reset color

# Returns formatted timestamp
timestamp() {
  date "+%Y-%m-%d %H:%M:%S"
}

# Displays usage instructions and exits
usage() {
  echo "Usage:"
  echo "  $0 [--webhook <url>] [--retries <n>] [--delay <seconds>] <service_url_1> ..."
  exit 1
}

# -------- Argument Parsing --------
# Parses CLI flags and service URLs
while [[ $# -gt 0 ]]; do
  case $1 in
    --webhook)
      WEBHOOK="$2"     # Slack webhook URL
      shift 2
      ;;
    --retries)
      RETRIES="$2"     # Override retry count
      shift 2
      ;;
    --delay)
      DELAY="$2"       # Override delay between retries
      shift 2
      ;;
    *)
      URLS+=("$1")     # Add URL to array
      shift
      ;;
  esac
done

# Ensure at least one service URL is provided
if [ ${#URLS[@]} -eq 0 ]; then
  usage
fi

echo -e "[$(timestamp)] ${YELLOW}Checking ${#URLS[@]} services...${NC}"

HEALTHY_COUNT=0
TOTAL=${#URLS[@]}
UNHEALTHY_SERVICES=()

# -------- Health Check Function --------
# Performs health check with retry logic
check_service() {
  local HEALTH_URL="$1"
  local attempt=1

  # Retry loop
  while [ $attempt -le $RETRIES ]; do

    # curl:
    # -s → silent
    # -m 5 → timeout after 5 seconds
    # -w → append HTTP status code to output
    RESPONSE=$(curl -s -m 5 -w "\n%{http_code}" "$HEALTH_URL")

    # Extract body (everything except last line)
    BODY=$(echo "$RESPONSE" | sed '$d')

    # Extract HTTP status code (last line)
    STATUS_CODE=$(echo "$RESPONSE" | tail -n1)

    # Validate:
    # 1. HTTP 200
    # 2. JSON contains "status": "healthy"
    if [[ "$STATUS_CODE" == "200" ]] && \
       echo "$BODY" | grep -q '"status"[[:space:]]*:[[:space:]]*"healthy"'; then

      # Extract optional version field if present
      VERSION=$(echo "$BODY" | grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)

      echo -e "[$(timestamp)] ${GREEN}$HEALTH_URL - HEALTHY (${VERSION:-unknown}) ✓${NC}"
      return 0
    fi

    # If failed, print retry attempt
    echo -e "[$(timestamp)] ${YELLOW}Retry $attempt/$RETRIES for $HEALTH_URL...${NC}"
    sleep "$DELAY"
    ((attempt++))
  done

  # If all retries fail → mark unhealthy
  echo -e "[$(timestamp)] ${RED}$HEALTH_URL - UNHEALTHY ✗${NC}"
  return 1
}

# -------- Execute Checks --------
# Loop through each provided base URL
for BASE_URL in "${URLS[@]}"; do

  # Normalize URL and append /health
  HEALTH_URL="${BASE_URL%/}/health"

  if check_service "$HEALTH_URL"; then
    ((HEALTHY_COUNT++))
  else
    UNHEALTHY_SERVICES+=("$HEALTH_URL")
  fi
done

echo
echo -e "${YELLOW}Results: $HEALTHY_COUNT/$TOTAL services healthy${NC}"

# -------- Slack Notification --------
# If any service is unhealthy AND webhook provided → send alert
if [[ $HEALTHY_COUNT -ne $TOTAL && -n "$WEBHOOK" ]]; then
  MESSAGE="Health Check Failed: ${UNHEALTHY_SERVICES[*]}"
  curl -s -X POST -H "Content-Type: application/json" \
       --data "{\"text\":\"$MESSAGE\"}" \
       "$WEBHOOK" > /dev/null
fi

# -------- Exit Code --------
# Return non-zero exit code if any service failed
if [[ $HEALTHY_COUNT -ne $TOTAL ]]; then
  exit 1
else
  exit 0
fi