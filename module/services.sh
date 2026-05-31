#!/usr/bin/env bash
set -euo pipefail

check_service(){
        SERVICES=("$@")
        FAILED_SERVICES=() #Initialise an empty array
        for service in "${SERVICES[@]}";do
            running=0
            for i in {1..3}; do
                echo "Checking $service attempt $i..."
                # if pgrep -x "$service" >/dev/null; then
                if systemctl is-active --quiet "$service"; then
                    running=1
                    echo "$service is running"
                    break
                else
                    echo "$service is not running, trying to start it";
                    log "$service is not running, trying to start it" "$service"
                    sudo systemctl start "$service";
                    sleep 3;
                fi
            done
            if [ "$running" -eq 0 ]; then
                log "$service failed to start in 3 attempts" "$service"
                FAILED_SERVICES+=("$service")
            fi
        done

        if [ "${#FAILED_SERVICES[@]}" -gt 0 ]; then
            alert "Services failed: ${FAILED_SERVICES[*]}"
        else
            log "All services are running" "services"
        fi
}