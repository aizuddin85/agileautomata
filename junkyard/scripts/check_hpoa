#!/usr/bin/ksh
#set -x
#ident "@(#)check_hpoa   1.0     12/12/16 TSI"
#ident "@(#)check_hpoa   1.1     09/03/17 TSI"
#
# System Commands
#
CMDOPT=${1}
AWK=/usr/bin/awk
TAIL=/usr/bin/tail
DATE=/usr/bin/date
MAILX=/usr/bin/mailx
NODENAME=`uname -n`
NODEARC=`uname -s`
RM=/usr/bin/rm
PS=/usr/bin/ps
PKILL=/usr/bin/pkill
#GREP=/usr/bin/grep
#
# HPOA commands
OVPATH=/opt/OV/bin
OVAIXPATH=/usr/lpp/OV/bin
OVC=/${OVPATH}/ovc
OPCAGT=/${OVPATH}/opcagt
AIXOPCAGT=/${OVAIXPATH}/opcagt
AIXOVC=/${OVAIXPATH}/ovc
#
# Log location
TEMPDIR="/tmp"
TEMPFILE="/${TEMPDIR}/hpoa_err.log"
MAILTO="weng-leong.yap@t-systems.com Siu-Siong.Lim@t-systems.com"
#
# Initialization
EVAE=0
stop_comm ()
{
   echo "Stopping HPOA agent processes..."
   ${OVPATH}/opcagt -stop
   ${OVPATH}/opcagt -kill
   ${OVPATH}/ovc -stop
   ${OVPATH}/ovc -kill
}
start_comm ()
{
   echo "Starting HPOA agent processes...."
   ${OVPATH}/opcagt -cleanstart
}
stop_aix ()
{
   echo "Stopping HPOA agent processes..."
   ${OVAIXPATH}/opcagt -stop
   ${OVAIXPATH}/opcagt -kill
   ${OVAIXPATH}/ovc -stop
   ${OVAIXPATH}/ovc -kill
}
start_aix ()
{
   echo "Starting HPOA agent processes...."
   ${OVAIXPATH}/opcagt -cleanstart
}
#
case ${NODEARC} in
        SunOS)
		OPCSTAT=`${OPCAGT}| grep Stopped`
		HPOASTAT=`${OVC}|grep Stopped`
		PLATFORM=1
		;;
	Linux)
                OPCSTAT=`${OPCAGT}|grep Stopped`
                HPOASTAT=`${OVC}|grep Stopped`
		PLATFORM=1
                ;;
	HP-UX)
                OPCSTAT=`${OPCAGT}|grep Stopped`
                HPOASTAT=`${OVC}|grep Stopped`
		PLATFORM=1
                ;;
	AIX)
		OPCSTAT=`${AIXOPCAGT}|grep Stopped`
		HPOASTAT=`${AIXOVC}|grep Stopped`
		PLATFORM=2
		;;
	*)
                echo "Unknown platform detected!!!"
                echo "Please contact LUX L3 to further investigate.."
                ;;
esac

	

if [ "${OPCSTAT}" ] || [ "${HPOASTAT}" ] || [ "${CMDOPT}" = "-force" ]; then
	EVAE=1
	#
	case ${NODEARC} in
	SunOS)
		stop_comm
		start_comm
		;;

	AIX)
		stop_aix
		start_aix
		;;

	Linux)
		stop_comm
		start_comm
		;;
	HP-UX)
		stop_comm
		start_comm
                ;;


	*)
		echo "Unknown platform detected!!!"
		echo "Please contact LUX L3 to further investigate.."
		;;
	esac
	EVAE=0
	else 	if [ "${CMDOPT}" = "-help" ]; then echo "Use -force option to KILL all HPOA agent services.."
		echo "Usage: check_hpoa -force "
		exit
		fi
fi
#
if [ "${PLATFORM}" = "1" ]; then
	FCHECK=`${OPCAGT} -status |grep "Agent buffering"`
else
	if [ "${PLATFORM}" = "2" ]; then
		FCHECK=`${AIXOPCAGT} -status |grep "Agent buffering"`
	fi
fi

if [ "${FCHECK}" ]; then EVAE=1
${OPCAGT} -status >${TEMPFILE} 2>&1
fi
echo ""
echo "[RESULT]"
if [ ${EVAE} != 0 ]; then
	echo "CODE:FAIL"
        echo "ACTION: Dispath Ticket To L2"
	#${MAILX} -s "${NODENAME} - HPOA service restarted with error and need further investigation.." ${MAILTO}<${TEMPFILE}
	${RM} ${TEMPFILE}
	else 
        echo "CODE:PASS"
        echo "ACTION: Ticket Closure"
	exit ${EVAE}
fi
