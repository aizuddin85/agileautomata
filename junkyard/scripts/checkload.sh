if [ -f /etc/shell-release ]; then
    echo '[OUTPUT]'
    echo 'Image: RHEL Classic'
    echo 'Date: `date`'
    echo 'Hostname: `hostname`'
    echo 'Getting Online processors count...'
    processor_count=`cat /proc/cpuinfo  | grep processor | wc -l`
    echo  "Total Processors: $processor_count"
    echo
    current_load=`cat /proc/loadavg | awk '{print $1}'`
    raw_load=`cat /proc/loadavg`
    echo "/proc/loadavg: $raw_load"
    echo "Current Load Average: $current_load"
    echo
    echo '[RESULT]'
    if [ $current_load -ge $processor_count ]; then
        echo "CODE:FAIL"
    else
        echo "CODE:PASS"
    fi
elif [ "AIX" == `uname` ]; then
    echo 'OUTPUT]'
    current_idle=`sar 1 1 | tail -n 1 | awk '{print $5}'`
    echo "Current Idle: $current_idle %"
    echo
    echo '[RESULT]'
    if [ $current_idle -ge 10 ]; then
        echo "CODE:PASS"
        echo "ACTION:Ticket Closure"
    else
        echo "CODE:FAIL"
        echo "ACTION: Escalate to L2"
    fi

fi

