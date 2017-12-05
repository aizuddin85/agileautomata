#!/usr/bin/ksh
##
## Performance report list
#
OS=`uname`
host=`hostname`
IP=`getent hosts ${host}|awk '{print $1}'`

if [ -d /cAppCom ]; then
   ENV="DCS"
else
   ENV="Classic"
fi

echo "[OUTPUT]"
echo "Image        : $OS $ENV"
echo "Date         : $(date)"
echo "Hostname     : $(hostname)"
echo "IP Address   : ${IP}"
echo ""
echo "Getting server healthcheck info..."
echo "Please be patient as may take longer time to run this reporting.."
echo ""
CODE=0
HOSTNAME=`uname -n|tr '[a-z]' '[A-Z]'`
PATH=/usr/bin
AWK=${PATH}/awk
WC=${PATH}/wc
EGREP=${PATH}/egrep
UPTIME=${PATH}/uptime
UP=`${UPTIME}|sed s/^.*up//|${AWK} -F, '{print $1}'|tr -d ' '`
TOP=/usr/local/bin/top
REPORT=/tmp/hreport.out
> ${REPORT}
N=0
echo "" >> ${REPORT}
date '+DATE: %d/%h/%Y%nTIME:%H:%M:%S'>> ${REPORT}
echo "" >> ${REPORT}
omsg="HealthCheck Report for ${HOSTNAME} node - Uptime(${UP})"
omsg1=`echo "${omsg}"|${WC}|awk '{print $3}'`
echo "${omsg}" >> ${REPORT}
#printf "%${omsg1}s\n" "${omsg}" >>${REPORT}
printf "%${omsg1}s"|tr ' ' '+' >> ${REPORT}
echo "" >> ${REPORT}
echo "" >> ${REPORT}
#
(( N=N+1))
## Hardware
FM=/usr/sbin/fmadm
ECODE="faulty"
   if [ ! -d /local/sar/hw ]; then mkdir -p /local/sar/hw
   fi
HLOG=/local/sar/hw/hlog
HWSTAT=`${FM} ${ECODE}` > $HLOG
   if [ ! "$HWSTAT" ]; then
	echo "$N: No hardware error found.." >> ${REPORT}
	else
	echo "$N: Found hardware issue in ${HOSTNAME}" >> ${REPORT}
	printf "%2s Please run \"fmadm faulty\" command for more details..\n" >> ${REPORT}
	CODE=1
   fi
echo "" >> ${REPORT}
#
(( N=N+1))
## CPU state
SAR=${PATH}/sar
MPSTAT=/usr/bin/mpstat
CLOCATE=/var/adm/sa
CFILE=`ls -lrt $CLOCATE |grep sa\`date +%d\`|head -1|${AWK} '{print $9}'`
    if [ "$CFILE" ]; then
        CPUPER=`${SAR} -u -f /$CLOCATE/$CFILE |tail -1 |${AWK} '{print $5}'`
        else CPUPER=`${MPSTAT} -a |grep -v SET|${AWK} '{print $16}'`
    fi
	echo "$N: Average CPU Idle time ${CPUPER}%" >> ${REPORT}
echo "" >>${REPORT}
#
(( N=N+1))
## Memory Usage
MEMCAP=`$TOP|grep Mem|${AWK} '{print substr($2,length($2))}'`
MEMCAP1=`$TOP|grep Mem|${AWK} -F, '{print $2}'|tr -d "emory|phys|real|free|' '"|${AWK} '{print substr($1,length($1))}'`
TOTALMEM=`$TOP|grep Mem|${AWK} -F, '{print $1}' |tr -d "Memory:|phys|real|free|' '" |${AWK} -F${MEMCAP} '{print $1}'`
#echo ${TOTALMEM}
if [ ${MEMCAP1} != ${MEMCAP} ] && [ ${MEMCAP1} == "M" ]; then
FRMEM=$(expr `$TOP|grep Mem|${AWK} -F, '{print $2}' |tr -d "emory:|phys|real|free" |${AWK} -F${MEMCAP1} '{print $1}'` / 1024 )
else FRMEM=`$TOP|grep Mem|${AWK} -F, '{print $2}' |tr -d "emory:|phys|real|free" |${AWK} -F${MEMCAP} '{print $1}'`
fi
USAGEMEM=$(expr ${TOTALMEM} - ${FRMEM} )
PERFRMEM=$(expr ${FRMEM} \* 100 / ${TOTALMEM} )
        echo "$N: Total Memory Usage - ${USAGEMEM}${MEMCAP}b/${TOTALMEM}${MEMCAP}b (${PERFRMEM}% free)" >> ${REPORT}
echo "" >> ${REPORT}
#
(( N=N+1))
## DiskPath
MODINFO=/usr/sbin/modinfo
echo "$N: Disk MultiPathing details.." >>${REPORT}
for MP in `${MODINFO}|${EGREP} "vhci|vxdmp"|${AWK} '{print $6}'`; do
   case ${MP} in
   scsi_vhci)
     MPATH=/usr/sbin/mpathadm
     TOTALSD=`${MPATH} list lu |grep "/dev/rdsk"|wc -l|tr -d ' '`
     TOTALSP=`${MPATH} list lu |grep "Total Path Count" |sort -u|${AWK} -F: '{print $2}'|tr -d ' '`
     printf "%2s Total MPxIO disk/LUN(s) = ${TOTALSD}\n" >>${REPORT}
     printf "%2s MPxIO disk path(s) count = ${TOTALSP}\n" >>${REPORT}
     ;;
   vxdmp)
     VXDMP=/usr/sbin/vxdmpadm
     VENCLNAME=`${VXDMP} listenclosure all|grep '\<CONNECTED'|grep -v DISKS|${AWK} '{print $1}'`
     VDMPCOUNT=`${VXDMP} listctlr enclosure=${VENCLNAME}|${EGREP} -v "^=|^CTLR"|wc -l|tr -d ' '`
     TOTALVD=`${VXDMP} getdmpnode enclosure=${VENCLNAME}|${EGREP} -v "^=|^NAME"|wc -l|tr -d ' '`
           printf "%2s Total VxVM disk(s) = ${TOTALVD}\n" >>${REPORT}
           printf "%2s VxVM disk path(s) count = ${VDMPCOUNT}\n" >>${REPORT}
     ;;
   esac
done
#MDISK=`$MPATH list LU $DISK|grep -i Total|${AWK} -d: '{print $4}'`
#if [ "$MDISK" -eq 2 ]; then
#	echo "$N: All disk paths ($MDISK) are online." >> ${REPORT}
#	else
#	echo "$N: Warning and please check diskpath in ${HOSTNAME}.." >> ${REPORT}
#fi
echo "" >> ${REPORT}
#
(( N=N+1))
## DiskDevice
echo "$N: Current disk devices status." >> ${REPORT}
DF=${PATH}/df
METASTAT=/usr/sbin/metastat
FTYP=`${DF} -n |${EGREP} "zfs|ufs|vxfs" |${AWK} -F: '{print $2}'|sort -u|tr -d ' '`
for aa in ${FTYP}; do
case ${aa} in
zfs)
        ZPOOLLIST=`/usr/sbin/zpool list |sed '/^NA.*OT/d'|${AWK} '{print $1,":",$6}'|tr -d ' '`
        #echo ${ZPOOLLIST}
        for bb in ${ZPOOLLIST}; do
          POOLN=`echo ${bb}|${AWK} -F: '{print $1}'`
          POOLS=`echo ${bb}|${AWK} -F: '{print $2}'`
          if [ "${POOLS}" != "ONLINE" ]; then
                printf "%6s Please check ${POOLN} pool - ${POOLS}..\n" ZFS >>${REPORT}
                else printf "%6s pool ${POOLN} - ${POOLS}..\n" ZFS >>${REPORT}
          fi
        done
        ;;
ufs)
	METADBC=`/usr/sbin/metadb |sed '/^.*flags.*$/d'|sed s/^.*dsk/\/|tr -d / |sort -u |wc -l`
	if [ ${METADBC} -lt 2 ]; then
		echo "   UFS Please check "metadb" command output.." >>${REPORT}
		else echo "   UFS Solaris "metadb" configuration is okay.." >>${REPORT}
	fi
	eval=0
	for cc in `grep -v "^#" /etc/vfstab|${AWK} '{print $3,$1}'|grep /dev/md| \
        egrep "\/\ ""|\/var\ ""|\/opt\ ""|\/usr\ ""|\-\ """|${AWK} '{print $2}'`; do
	  I=`${METASTAT} -p ${cc}|wc -l`
	  if [ ${I} -lt 3 ]; then
	  echo "   UFS ${cc} is NOT  mirrored on ${HOSTNAME}.." >>${REPORT}
	  eval=1
	  CODE=1
	  fi
	done
	if [ ${eval} -eq "0" ]; then
	  echo "   UFS All meta volumes are mirrored on ${HOSTNAME}.." >>${REPORT}
	fi
	mdtrouble=`${METASTAT} | \
    	${AWK} '/State:/ { if ( $2 != "Okay" && $2 !="Resyncing") print $0 }'`
	if [ "${mdtrouble}" ]; then
	   echo "   SDS Metadevices are not Okay:" >>${REPORT}
	   CODE=1		
	fi
	;;
#
vxfs)
	;;
#
esac
done
echo "" >> ${REPORT}
#
(( N=N+1))
## Network link
KSTAT=${PATH}/kstat
MCAST=224.0.0.0
PINT=`netstat -rn |grep ${MCAST}|${AWK} '{print $6}'`
PINT1=`${KSTAT} -p ::${PINT}|${AWK} '{FS=":";OFS=":"} {print $1, $2}'|sort -u`
PCOM="${KSTAT} -p ${PINT1}::"
echo "$N: Server primary interface \"${PINT}\" checking.." >> ${REPORT}
if [ "`${PCOM}link_state|${AWK} '{print $2}'`" -eq 1 ]; then
        printf "%7s is UP..\n" Link >>${REPORT}
        else printf "%7s is DOWN..\n" Link >>${REPORT}
fi
DUPMODE=`${PCOM}link_duplex|grep mac|${AWK} '{print $2}'`
	if [ $DUPMODE -eq 2 ]; then DUPSTAT="Full"
	else if [ $DUPMODE -eq 1 ]; then DUPSTAT="Half"
	     else DUPSTAT="Unknown"
	     fi
	fi
SPEED=`${PCOM}link_speed|${AWK} '{print $2}'`
case ${SPEED} in
10000)  printf "%8s mode - 10Gbps/%s..\n" Speed $DUPSTAT >>${REPORT}
        ;;
1000)   printf "%8s mode - 1Gbps/%s..\n" Speed $DUPSTAT >>${REPORT}
        ;;
100)    printf "%8s mode - 100Mbps/%s..\n" Speed $DUPSTAT >>${REPORT}
        ;;
*)      printf "%8s mode - Unknown/%s..\n" Speed $DUPSTAT >>${REPORT}
        ;;
esac

DROUTER1=`cat /etc/defaultrouter|head -1`
DROUTER2=`netstat -rn|grep -i default|${AWK} '{print $2}'`
	if [ $DROUTER1 -eq $DROUTER2 ]; then
	  echo "   Gateway IP - `/usr/sbin/ping $DROUTER1`"  >> ${REPORT}
	  else 
	  echo "   Warning!! Please check the network gateway..\n" >> ${REPORT}
	fi
echo "" >> ${REPORT}
#
(( N=N+1))
## GDC IP Ping test
GDCIPS=/tmp/gdc_core_ip.$$
GDCTRACE=/tmp/traceroute_gdc.ip.txt

echo "\
NLAMSDC1MP400-COR 145.26.155.49
NLAMSDC1MP401-COR 145.26.155.50
NLAMSDC2MP400-COR 134.146.255.76
NLAMSDC2MP401-COR 134.146.255.74
NLAMSD2AMP400-COR 145.26.155.51
NLAMSD2AMP401-COR 145.26.155.52
MYCBJCENMP400-COR 156.31.49.240
MYCBJCENMP401-COR 156.31.49.241
MYPEJJBTMP050-COR 156.149.164.8
MYPEJJBTMP051-COR 156.149.164.9
USHOUCY1MP048 138.58.95.206
USHOUCY1MP049 138.58.95.207
USMONTSWMP400-COR 134.163.57.22
USMONTSWMP401-COR 134.163.57.23 \
" > ${GDCIPS}
date +%c > ${GDCTRACE}

echo "$N: GDC IP Ping Test.. " >> ${REPORT}
cat ${GDCIPS} | while read GDC_HOST GDC_IP
do
  set_error=0
  /usr/sbin/ping -s ${GDC_IP} 64 3 > /dev/null 2>&1
  if [ $? -eq 0 ]; then
   printf "%14s ${GDC_HOST}\t: OK\n" ping_gdc_ip | tee -a ${GDCTRACE} >> ${REPORT}
   #echo "ping_gdc_ip ${GDC_HOST}\t: OK" | tee -a ${GDCTRACE} >> ${REPORT}
  else
   printf "%14s ${GDC_HOST}\t: FAILED\n" ping_gdc_ip | tee -a ${GDCTRACE} >> ${REPORT}
   set_error=1
  fi

  if [ ${set_error} -eq 0 ]; then
   /usr/sbin/traceroute -q1 ${GDC_IP} >> ${GDCTRACE} 2>&1
   echo "--------------------------------------------------------------" >> ${GDCTRACE}
   echo "" >> ${GDCTRACE}
  else
   echo "Ping ${GDC_HOST} failed.." >> ${GDCTRACE}
   echo "--------------------------------------------------------------" >> ${GDCTRACE}
   echo "" >> ${GDCTRACE}
  fi
done

printf "%2s traceroute_gdc_ip\t\t\t: Please refer output in ${GDCTRACE}" >> ${REPORT}
rm /tmp/gdc_core_ip.$$
echo "" >> ${REPORT}
#
(( N=N+1))
## NTP service
ntpq=/usr/sbin/ntpq
printf "%1s: NTP service check\n" $N >>${REPORT}
ntpo=`${ntpq} -p 2>/dev/null|grep '*'`
if [ -n "${ntpo}" ]; then
	printf "%2s NTP time is synchronized and OK..\n" >>${REPORT}
	else
	printf "%2s NTP time is not synchronized and OK..\n" >>${REPORT}
fi
echo "" >> ${REPORT}
(( N=N+1))
## HPOA 
OVPATH=/opt/OV/bin
OVC=/${OVPATH}/ovc
OPCAGT=/${OVPATH}/opcagt
printf "%1s: HPOA Agent service check\n" $N >>${REPORT}
OPCSTAT=`${OPCAGT}| grep Stopped`
HPOASTAT=`${OVC}|grep Stopped`
if [ -z "${OPCSTAT}" ] && [ -z "${HPOASTAT}" ]; then
   printf "%2s Agent is running fine..\n" >>${REPORT}
   else printf "%2s Agent service not fully running..\n" >>${REPORT}
   CODE=1
fi
echo "" >> ${REPORT}
#
(( N=N+1))
## Filesystem
DF=${PATH}/df
FSTYP=`${DF} \-n /|${AWK} -F: '{print $2}'`
LOCALFS=`${DF} \-F ${FSTYP} -h|grep -v ^File |${AWK} '{print $5,":",$6}'|tr -d ' '`
	echo "$N: ${HOSTNAME} realtime filesystem usage check.." >> ${REPORT}
	echo "   Filesystem/Mountpoint(s) which exceeding 90%.." >>${REPORT}
		EVAL=0
		for x in ${LOCALFS}; do 
		DPCT=`echo $x|${AWK} -F: '{print $1}'|cut -d% -f1`
		DFLD=`echo $x|${AWK} -F: '{print $2}'`
		 if [ ${DPCT} -gt 90 ]; then
			echo "   ${DPCT}% - ${DFLD}" >>${REPORT}
			EVAL=1
		 fi
		done
	if [ ${EVAL} = 0 ]; then echo "   All mountpoints usage are below threshold value.." >>${REPORT}; fi
	echo "" >>${REPORT}
	${DF} -F ${FSTYP} -h|head -1 >>${REPORT}
	${DF} -F ${FSTYP} -h|grep -v ^File|sort -nr >>${REPORT}
	echo "" >> ${REPORT}
	echo "HealthCheck Report END..\n " >> ${REPORT}

echo '[RESULT]'
    if [ $CODE -eq 0 ]; then
        echo "CODE:PASS"
        echo "ACTION: Check /tmp/hreport.out file contents for more details.. "
    else
        echo "CODE:FAIL"
        echo "ACTION: Dispath Ticket To L2"
    fi
