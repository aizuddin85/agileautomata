#!/bin/ksh
#ident "@(#)check_uptime   1.0     12/12/16 TSI"
#
VER=1.0
#
echo "check_uptme.sh v$VER"
echo ""
OS=`uname`
eval=0
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
echo "Getting server uptime info...."
echo ""

case $OS in
 AIX|HP-UX|SunOS )
        echo "Server $(hostname)"
	printf  "Uptime is "
	uptime|sed 's/.*up \([^,]*\), .*/\1/'
	if [ $? -eq 0 ]; then
	  printf "Last Reboot Time :"
	  who -b|awk '{print $4,$5,$6}'
		if [ $? -ne 0 ]; then
		eval=1	
		fi
	fi
        ;;

   Linux )
        echo "Server $(hostname)"
        printf  "Uptime is "
        uptime|sed 's/.*up \([^,]*\), .*/\1/'
        if [ $? -eq 0 ]; then
          printf "Last Reboot Time :"
          who -b|awk '{print $3,$4}'
                if [ $? -ne 0 ]; then
                eval=1
                fi
        fi
        ;;

     * )
        echo "Invalid OS Type. Exit script"
        echo "[RESULT]"
        echo "CODE:UNKNOWN"
        exit 1
        ;;
esac
#
echo ""
echo "[RESULT]"
   if [ $eval -eq 0 ]; then
        echo "CODE:PASS"
        echo "ACTION: Ticket Closure"
    else
        echo "CODE:FAIL"
        echo "ACTION: Dispath Ticket To L2"
    fi
