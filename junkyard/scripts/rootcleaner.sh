


if [ -f /etc/shell-release ]; then

    export env TZ="Asia/Kuala_Lumpur"

    echo `date`
    echo `hostname`
    sizepct=`df  -hP / | grep root | awk '{print $5}' | cut -d "%" -f 1`
    totalsize=`df  -hP  / | grep root | awk '{print $2}'`
    freesize=`df  -hP  / | grep root | awk '{print $4}'`
    
    echo "Classic Image detected... Running classic image clean up routine.."

    echo "******[PRE-TASK]******"
    echo "Root usage before cleanup:"
    echo "Free Size: $freesize"
    echo "Total Size: $totalsize"
    echo "Free %: $sizepct%"

    echo 
    echo "******[TASKS]******"
    echo "Finding .tgz file with access time older than 90 days in /var/log/ directory for clean up..."
    find /var/log -atime +90 -name "*.tgz" | xargs rm -rvf
    echo "Finding .tar.gz file with access time older than 90 days in /var/log/ directory for clean up..."
    find /var/log -atime +90 -name "*.tar.gz" | xargs rm -rvf
    echo "Finding .gz file with access time older than 90 days in /var/log/ directory for clean up..."
    find /var/log -atime +90 -name "*.gz" | xargs rm -rvf


    postsize=`df -hP / | grep root | awk '{print $5}' | cut -d "%" -f 1`

    echo
    echo "******[RESULT]******"
    if [ $postsize -lt 95 ]; then
        echo "Result:OK"
        echo "Free Size: $freesize"
        echo "Total Size: $totalsize"
        echo "Usage: $sizepct%"

    else
        echo "Result:FAIL"
        echo "Free Size: $freesize"
        echo "Total Size: $totalsize"
        echo "Usage: $sizepct%"

    fi

fi

