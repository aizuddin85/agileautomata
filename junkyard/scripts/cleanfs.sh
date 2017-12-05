#!/bin/ksh
# clean up old compressed files in root fs on Linux Classic server only
VER=1.1

echo "cleanfs.sh v$VER"

OS=`uname`
THRESHOLD=95

if [ -d /cAppCom ]; then
   OENV="DCS"
else
   OENV="Classic"
fi

echo "[OUTPUT]"
echo "Image        : $OS $OENV"
echo "Date         : $(date)"
echo "Hostname     : $(hostname)"
echo ""

case $OS in 
 Linux )
	if [ -f /etc/shell-release ]; then
	 echo "RHEL Classic Image detected. Running clean up routine..."
	 totalsize=`df  -hP  / | grep root | awk '{print $2}'`
	 freesize=`df  -hP  / | grep root | awk '{print $4}'`
	 sizepct=`df  -hP / | grep root | awk '{print $5}' | cut -d "%" -f 1`

    	 echo "- Deleting any .tgz file with access time older than 90 days in /var/log/ directory..."
    	 find /var/log -atime +90 -name "*.tgz" -ls -delete
    	 echo "- Deleting any .tar.gz file with access time older than 90 days in /var/log/ directory..."
    	 find /var/log -atime +90 -name "*.tar.gz" -ls -delete
    	 echo "- Deleting any .gz file with access time older than 90 days in /var/log/ directory..."
    	 find /var/log -atime +90 -name "*.gz" -ls -delete

    	 postsize=`df -hP / | grep root | awk '{print $5}' | cut -d "%" -f 1`

	else 
	 echo "None Supported Image found. Exiting"
	 exit 1
	fi	
	;;
     * )
        echo "Non Supported OS Type. Exit script"
        echo "[RESULT]"
        echo "CODE:UNKNOWN"
        exit 1
        ;;
esac

echo ""
echo "[OUTPUT]"
echo "Root FS usage before cleanup"
echo "Total Size    : $totalsize"
echo "Free Size     : $freesize"
echo "Free %        : $sizepct%"
echo ""
echo "Root FS usage after cleanup"
echo "Free %        : $postsize%"
echo ""

echo "[RESULT]"
    if [ $postsize -lt $THRESHOLD ]; then
        echo "CODE:PASS"
        echo "ACTION: Ticket Closure"
    else
        echo "CODE:FAIL"
        echo "ACTION: Dispath Ticket To L2"
    fi
