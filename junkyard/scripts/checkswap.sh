#!/bin/ksh
# checkswap.sh by Edmund.Wong @ Mar-2017
#
VER=1.2

echo "checkswap.sh v$VER"

OS=`uname`
THRESHOLD=80

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
echo "Getting SWAP info..."

case $OS in 
 Linux )
	SWAPTOTAL=$(free -m | grep Swap: | awk '{print $2}')
	SWAPUSED=$(free -m | grep Swap: | awk '{print $3}')
	SWAPUSEDPCT=$(echo "($SWAPUSED*100)/$SWAPTOTAL" | bc)
	;;
   AIX )
	SWAPTOTAL=$(lsps -s | tail -1 | awk '{print $1}')
	SWAPUSEDPCT=$(lsps -s | tail -1 | awk '{print $2}' | sed 's/%//')
	;;
 HP-UX )
	SWAPTOTAL=$(swapinfo -tam | grep -i total | awk '{print $2}')
	SWAPUSEDPCT=$(swapinfo -tam | grep -i total | awk '{print $5}' | sed 's/%//')
	;;
 SunOS )
	SWAPTOTAL=$(echo "`swap -l | awk '{print $4}' | grep -v block` / 1024" | bc)
	SWAPUSED=$(echo "$SWAPTOTAL - (`swap -l | awk '{print $5}' | grep -v free` / 1024)" | bc)
	SWAPUSEDPCT=$(echo "($SWAPUSED*100)/$SWAPTOTAL" | bc)
	;;
     * )
	echo "Invalid OS Type. Exit script"
	echo "[RESULT]"
        echo "CODE:UNKNOWN"
	exit 1
	;;
esac

echo "Swap Total   : $SWAPTOTAL MB"
echo "Swap Used    : $SWAPUSEDPCT %"
echo ""

echo '[RESULT]'
    if [ $SWAPUSEDPCT -le $THRESHOLD ]; then
        echo "CODE:PASS"
        echo "ACTION: Ticket Closure"
    else
        echo "CODE:FAIL"
        echo "ACTION: Dispath Ticket To L2"
    fi
