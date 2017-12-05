#!/bin/ksh
#set -x
#ident "@(#)check_hpoa   1.0     12/12/16 TSI"
#
VER=1.0
#
echo "checkcpu.sh v$VER"
#
OS=`uname`
tempfile=/etc/profile.tmp
eval=0
if [ -d /cAppCom ]; then
   OENV="DCS"
   echo "Non-Classic environment..."
   exit 1
else
   OENV="Classic"
fi

echo "[OUTPUT]"
echo "Image        : $OS $OENV"
echo "Date         : $(date)"
echo "Hostname     : $(hostname)"
echo ""
echo "Modifying user profile umask value...."
echo ""

case $OS in
 Linux|AIX|HP-UX|SunOS )
        echo "Server $(hostname)"
	cp -p /etc/profile ${tempfile}
        sed  's/umask.*/umask 022/g' ${tempfile} > /etc/profile 2> /dev/null
	if [ $? -eq 0 ]; then
	        echo "User umask value set done.."
	        else 
		eval=1	
	fi
	rm ${tempfile}
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
