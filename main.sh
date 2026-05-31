#!/bin/bash

source config.env
source module/metrics.sh
source module/services.sh
source module/alert.sh


SERVICES=("nginx" "dockerd" "sshd")

check_service "${SERVICES[@]}"
check_metrics