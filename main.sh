#!/bin/bash

source config.env
source module/metrics.sh
source module/services.sh
source module/alert.sh


#SERVICES=("nginx" "docker" "sshd")
SERVICES=("docker" "sshd")
check_service "${SERVICES[@]}"
check_metrics