#!/usr/bin/env bash
set -uo pipefail

log() {
    LOGFILE="/var/log/${2}_log.log"

    if [ ! -f "$LOGFILE" ]; then
        sudo touch "$LOGFILE"
    fi

    echo "$(date '+%Y-%m-%d %H:%M:%S') ---- $1" | sudo tee -a "$LOGFILE" >/dev/null
}

telegram(){
    MESSAGE=$1

    if ! curl -s -X POST \
        "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d chat_id="${CHAT_ID}" \
        -d text="${MESSAGE}"; then
        log "telegram failed" "telegram"
        return 1
    fi
}


sns_alert() {
    MESSAGE=$1

    # Validate message length
    if [ ${#MESSAGE} -gt 262144 ]; then
        echo "Message exceeds maximum size"
        return 1
    fi

    PUBLISH_RESULT=$(aws sns publish \
        --topic-arn "$TOPIC_ARN" \
        --message "$MESSAGE" \
        --region "$AWS_REGION" \
        --output json 2>/dev/null)

    if [ $? -ne 0 ]; then
        echo "Failed to publish message"
        log "SNS publish failed" "sns"
        return 1
    fi

    MESSAGE_ID=$(echo "$PUBLISH_RESULT" | jq -r '.MessageId // empty')

    if [ -z "$MESSAGE_ID" ]; then
        echo "No message ID returned"
        return 1
    fi

    echo "Message published successfully with ID: $MESSAGE_ID"
}

alert() {
    telegram "$1"
    sns_alert "$1"
}