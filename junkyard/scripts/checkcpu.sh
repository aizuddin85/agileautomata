#!/bin/ksh
VER=1.1

echo "checkcpu.sh v$VER"

OS=`uname`
THRESHOLD=10

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
echo "Getting CPU info..."

case $OS in 
 Linux ) 
	CPUIDLE=`sar -u 1 10 | tail -1 | awk '{print $NF}'`
	;;
 AIX | HP-UX | SunOS ) 
        CPUIDLE=`sar -u 1 10 | tail -1 | awk '{print $5}'`
	;; 
     * ) 
        echo "Invalid OS Type. Exit script"
        echo "[RESULT]"
        echo "CODE:UNKNOWN"
        exit 1
	;;
esac

CPUBUSY=`echo $CPUIDLE | awk '{print (100-$1)}'`
ROUNDUP=`printf "%.0f" $(echo "scale=2;$CPUIDLE" | bc)`

echo "CPU Busy     : $CPUBUSY%"
echo ""

echo "[RESULT]"
   if [ $ROUNDUP -gt $THRESHOLD ]; then
        echo "CODE:PASS"
        echo "ACTION: Ticket Closure"
    else
        echo "CODE:FAIL"
        echo "ACTION: Dispath Ticket To L2"
    fi

