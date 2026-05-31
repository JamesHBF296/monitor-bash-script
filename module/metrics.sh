#!/usr/bin/env bash
set -euo pipefail 

check_metrics(){
    #CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
    CPU=$(mpstat 1 1 | awk '$2=="all" {print 100 - $NF}' | tail -1)
    CPUAvg=$(cat /proc/loadavg | awk '{print "Load Average (1m, 5m, 15m): " $1, $2, $3}')
    MEM=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    MemTotal=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    DISKUsed=$(df / | awk 'NR==2 {print $3}')
    DISKTotal=$(df / | awk 'NR==2 {print $2}')
    DISKPercentage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//g')
    # awk 'NR==2 {gsub(/%/, "", $5); print $5}'

    MESSAGE=$(cat <<EOF
    {
      "cpu": "${CPU}%",
      "cpu_load_avg": "${CPUAvg}",
      "mem_usage": "$((100 * MEM / MemTotal))%",
      "disk_usage": "${DISKPercentage}%"
    }
EOF
    )

    alert "$MESSAGE"
}

