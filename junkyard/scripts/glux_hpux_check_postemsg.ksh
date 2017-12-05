#!/bin/ksh
#--------------------------------------------------------------------------------# 
# Created By: Edmund Wong               Created Date: Mar 2017
#
# Script name: glux_hpux_check_postemsg.ksh
# Description: Custom HPUX health check script to generate postesmg event for HPOA
# Location   : /local/users/root/bin/
#
# Code Defination:
# HPUXCHK-001: ignite image backup error  
# HPUXCHK-002: Found potentially runaway processes 
# HPUXCHK-003: NO ntp servers in ntp.conf
# HPUXCHK-004: NO ntp.conf found
# HPUXCHK-005: xntpd does not start
# HPUXCHK-006: Disk path error       
# HPUXCHK-007: Disk NO_HW error 
# HPUXCHK-008: SmartArray disk error 
# HPUXCHK-009: vg00 not mirrored
# HPUXCHK-010: Found mounted filesystem, not in /etc/fstab 
# HPUXCHK-011: Ethernet Link Aggregation error 
# HPUXCHK-012: Connect:Direct process is down
# HPUXCHK-013: Found too many Defunct processes
#
#--------------------------------------------------------------------------------# 

# global variables:
VERSION=1.12
ERROR_FOUND=FALSE # stays false untill set to TRUE by set_error()
NOT_MIRROR=FALSE
LOG=/tmp/glux_hpux_check_postemsg.log
POSTEMSG_LOG=/tmp/postemsg.log
POSTEMSG=TRUE

# Usage
Usage()
{
        echo "Version $VERSION "
        echo "Usage: $0 [-pm] "
        echo "          -p : Disable postemsg output. "
        echo "          -m : Print Management Summary. "
        echo "          -h : Print usage. "
}
# get options
while getopts mph c
do
  case $c in
    m) MGMT=true;;
    p) POSTEMSG=FALSE;;
    h) Usage; exit 0;;
    *) Usage; exit 0;;
  esac
done

set_error()
{
ERROR_FOUND=TRUE
}

postemsg()
{
if [ $POSTEMSG = TRUE ]; then
_DATE=`date +%Y-%m-%d`
_TIME=`date +%H:%M:%S`
_TIMEZONE=`date +%Z`
_CINAME=`hostname`
_CITYPE="unix"
_HOSTEDON="server"
_VAR1=$2
_VAR2=$3
_SEVERITY=$1
_MESSAGE=$4

echo $_DATE";"$_TIME";"$_TIMEZONE";"$_CINAME";"$_CITYPE";"$_HOSTEDON";"$_VAR1";"$_VAR2";"$_SEVERITY";"$_MESSAGE >> $POSTEMSG_LOG

fi 

} # postemsg

clean_postemsg_log()
{
_OLDMONTH=$(expr `date +%m` - 2 | awk '{printf("%02d",$1)}')
_DELMONTH=`date +%Y-`$_OLDMONTH

#echo $_OLDMONTH
#echo $_DELMONTH
#echo `TZ=GMT+1440 date +%Y-%m-%d`
#sed  '/^.*\(2017-07-11\).*$/d' postemsg.log

grep -v ^$_DELMONTH $POSTEMSG_LOG > $POSTEMSG_LOG.tmp
mv $POSTEMSG_LOG.tmp $POSTEMSG_LOG

} # clean_postemsg_log

check_bootlist()
{
BOOTERR=FALSE
BOOTDSK=$(lvlnboot -v vg00 | grep "Boot Disk" | awk '{print $1}') 
BOOTLIST1=$(lvlnboot -v vg00 | grep "Boot Disk" | awk '{print $2}' | sed 's/[()]//g' | sort)

DRDDSK=$(/opt/drd/bin/drd status 2>/dev/null)
if [ $? -eq 0 ]; then 
   BOOTLIST2=$(setboot -v | grep -i "primary bootpath" | awk '{print $NF}')
else
   BOOTLIST2=$(setboot -v | grep bootpath | grep "/[0-9]/" | awk '{print $NF}' | sort)
fi

if [ $(uname -r) = "B.11.31" ]; then
   BOOTLIST1=$(lvlnboot -v vg00 | grep "Boot Disk" | awk '{print $1}' | cut -d_ -f1 | cut -d/ -f4)
   BOOTLIST2=$(echo $BOOTLIST2 | sed 's/[()]//g' | cut -d/ -f4)
fi

  if [ "$BOOTLIST1" != "$BOOTLIST2" ]; then
     echo "check_bootlist\t\t\t: check if all boot disks are on setboot list"
     postemsg MINOR "bootlist_problem" "HPUXCHK" "Bootlist mismatch. check if all boot disks are on setboot list "
     set_error
     BOOTERR=TRUE
  fi

  for i in $BOOTDSK; do 
   lifcp $i:AUTO - >/dev/null 2>&1
    if [ $? -ne 0 ]; then
      echo  "check_bootlist\t\t\t: $i is not a LIF volume"
      postemsg MINOR "bootlist_problem" "HPUXCHK" "$i is not a LIF volume"
      set_error
      BOOTERR=TRUE
    fi
  done

if [ $BOOTERR = FALSE ]; then
   echo "check_bootlist\t\t\t: OK"
fi

} # check_bootlist

check_ntp()
{ 
# first check if there is a conf file and the contents
NTPCONF=/etc/ntp.conf
NTPCONF_RIGHT=TRUE
if [ -r $NTPCONF ]
   then
      grep -v "^#" $NTPCONF | grep server 2>&1 > /dev/null
      if [ $? -ne 0 ] 
         then
         echo "check_ntp\t\t\t: NO ntp servers defined"
         postemsg MINOR "ntp.conf" "HPUXCHK-003" "No ntp server defined."        
         NTPCONF_RIGHT=FALSE
         set_error
      fi
   else
      echo "check_ntp\t\t\t: No $NTPCONF found"
      postemsg MINOR "ntp.conf" "HPUXCHK-004" "No ntp.conf file found"
      NTPCONF_RIGHT=FALSE
      set_error
   fi
# now try to start ntp
# only when correct ntp.conf file found
if [ "$NTPCONF_RIGHT" = "TRUE" ]
   then
      #echo $NTPCONF " contains server definition."
      ps -ef | grep -v grep | grep ntpd > /dev/null 
      if [ $? -ne 0 ] 
         then
         echo "check_ntp\t\t\t: ntpd not running. restarting it. "
         set_error
         # try to start
         /sbin/init.d/xntpd start > /dev/null 2>&1; sleep 5;
         ps -ef | grep -v grep | grep ntpd > /dev/null 
         if [ $? -ne 0 ]
             then
              # it seems to fail starting ntp  
              echo "check_ntp\t\t\t: xntp start not succesfull"
              postemsg MINOR "xntpd" "HPUXCHK-005" "xntpd does not start"
              set_error
          fi
        else
           echo "check_ntp\t\t\t: OK"
        fi
   fi
return
} # check_ntp

check_vg00_mirr()
{
if [ -f /opt/drd/bin/drd ]; then
 DRDDSK=$(/opt/drd/bin/drd status 2>/dev/null)
 if [ $? -eq 0 ]; then
   LASTSYNC=`grep -i "Last Sync Date" /var/opt/drd/drd.log | tail -1 | awk '{print $5}'`
   echo "check_vg00_mirr\t\t\t: DRD clone disk found. Last synced on $LASTSYNC"
   return
 fi
fi

if [ "$(uname -r)" = "B.11.31" ]; then
 ROOTDSK=$(/usr/sbin/vgdisplay -v vg00 | grep "PV Name" | awk '{print $3}' | tail -1)
 /usr/sbin/ioscan -m lun $ROOTDSK | grep "LOGICAL VOLUME" >/dev/null 2>&1
 if [ $? -eq 0 ]; then 
   echo "check_vg00_mirr\t\t\t: skip. root disk on logical volume"
   return
 fi
fi 
 
for lv in $(ls -l /dev/vg00 | grep ^br | sort -nk6 | awk '{print $NF}')
 do
 MIRRORCOPIES=`/usr/sbin/lvdisplay /dev/vg00/$lv | grep "Mirror copies" | awk '{print $NF}'`
 if [ $MIRRORCOPIES -eq 0 ]; then
   NOT_MIRROR=TRUE
 fi
done

if [ $NOT_MIRROR = TRUE ]
 then
 echo "check_vg00_mirr\t\t\t: Not all LVs in vg00 was mirrored correctly."
 postemsg MINOR "vg00_mirror_problem" "HPUXCHK-009" "Not all LVs in vg00 was mirrored correctly."
 set_error
 else
  echo "check_vg00_mirr\t\t\t: OK"
fi 

} # check_vg00_mirr

check_lv_status()
{
LVALERT=/tmp/check_lv_status.$$
LVNAME=$(/usr/sbin/vgdisplay -v 2>/dev/null | grep "LV Name" | awk '{print $3}')
for i in $LVNAME
 do
  LVSTATUS=$(/usr/sbin/lvdisplay $i | grep "LV Status" | awk '{print $NF}')
  if [ "$LVSTATUS" != "available/syncd" ]; then 
     echo $i "\c" >> $LVALERT
  fi
done

if [ -s $LVALERT ]; then 
  echo "check_lv_status\t\t\t: ERROR. Found LVs not in available/syncd status (`cat $LVALERT`)"
  postemsg MINOR "lv_problem" "HPUXCHK" "Found LVs not in available/syncd status (`cat $LVALERT`)"
  set_error
  rm $LVALERT
else
  echo "check_lv_status\t\t\t: OK"
fi

} # check_lv_status

check_ignite()
{
IGNITE_FS=/var/opt/ignite/recovery
find $IGNITE_FS -mtime -14 -name "previews" -exec file {} \; | grep text > /dev/null 2>&1
 if [ $? -ne 0 ]; then
  echo "check_ignite\t\t\t: ERROR: No recent ignite previews file found"
  postemsg MINOR "ignite_problem" "HPUXCHK-001" "No recent ignite backup found. Check ignite log"
  set_error
 else
  echo "check_ignite\t\t\t: OK"
 fi 
} # check_ignite

check_connect_direct()
{
CDHOME=`cat /etc/passwd | grep cdunix | cut -d":" -f6`
CDCHK=$CDHOME/scripts/postemsg.enable
if [ -a $CDCHK ]
   then 
     ps -ef | grep -v grep  | grep ndm/bin/cdpmgr > /dev/null 2>&1
     if [ $? -ne 0 ]
        then 
        echo "check_connect_direct\t\t: ERROR"
        postemsg MAJOR "cdunix_problem" "HPUXCHK-012" "Connect:Direct process is DOWN. Please check and restart" 
        set_error
        else
        echo "check_connect_direct\t\t: OK"
     fi
   else
     echo "check_connect_direct\t\t: n.a." 
fi
} # check_connect_direct

check_runaway_proc()
{
RUNAWAY_PROC=/tmp/chk.runaway_proc.$$
MINTIME=999999
EXCLUDEPROC="vxfsd|statdaemon|kmemdaemon"
ps -ea | egrep -v $EXCLUDEPROC | sort -rnk 3 | head -20 | sed -e 's/\://g' | \
 awk -v MIN=$MINTIME '$3 > MIN {print $1"("$4")"}' > $RUNAWAY_PROC

if [ -s $RUNAWAY_PROC ]
   then
   echo "check_runaway_proc\t\t: Found potential runaway processes `cat $RUNAWAY_PROC | tr '\n' ' '`"
   postemsg MINOR "runaway_proc_problem" "HPUXCHK-002" "Found potential runaway processes `cat $RUNAWAY_PROC`"
   set_error
   else
   echo "check_runaway_proc\t\t: OK"
fi
rm $RUNAWAY_PROC

} # check_runaway_proc   

check_mount_fs()
{
ps -ef | grep cmclconfd | grep -v grep >/dev/null 2>&1
if [ $? -eq 0 ]; then
   echo "check_mount_fs\t\t\t: skip. found cluster service. Please check manually"
   return
fi

MOUNTED_LIST=/tmp/fsmount.$$
EXCEPT_LIST="/mnt|/net|/bc/|ignite/recovery"
UNKNOWN_FS=/tmp/unknown_fs_found.$$

mount | egrep -v $EXCEPT_LIST | awk '{print $1}' > $MOUNTED_LIST

for FS in `cat $MOUNTED_LIST`
  do
    grep $FS /etc/fstab > /dev/null 
    if [ $? -ne 0 ]; then
       echo $FS "\c" >> $UNKNOWN_FS
    fi
done 

if [ -s $UNKNOWN_FS ]
   then
   echo "check_mount_fs\t\t\t: Found a mounted filesystem that not in /etc/fstab ( `cat $UNKNOWN_FS`)"
   postemsg MINOR "fs_mount_problem" "HPUXCHK-010" "Found a mounted filesystem that not in /etc/fstab ( `cat $UNKNOWN_FS`)" 
   set_error
   rm $UNKNOWN_FS
   else
   echo "check_mount_fs\t\t\t: OK"
fi

rm $MOUNTED_LIST

} # check_mount_fs

check_hpoa_proc()
{
HPOAERR=FALSE
OVC=/opt/OV/bin

if [ ! -f $OVC/ovc ]
  then
    echo "check_hpoa_proc\t\t\t: HP OA is not installed"
    return
  fi

$OVC/ovc -status AGENT | wc -l | read HPOA
 if [ $HPOA -le 3 ]; then
    echo "check_hpoa_proc\t\t\t: ERROR. HP OA processes might not running"
    #postemsg MINOR "hpoa_proc_problem" "HPUXCHK" "HP OA processes might not running"
    set_error
    HPOAERR=TRUE
 fi

PROXY=`$OVC/ovconfget | grep MANAGER= | cut -d= -f2`
$OVC/bbcutil -ping $PROXY >/dev/null 2>&1
 if [ $? -ne 0 ]; then
    echo "check_hpoa_proc\t\t\t: ERROR. bbcutil ping to mgmt server $PROXY is failing"
    #postemsg MINOR "hpoa_proc_problem" "HPUXCHK" "bbcutil ping to mgmt server $PROXY is failing" 
    set_error
    HPOAERR=TRUE
 fi

$OVC/ovcert -check | grep "Check succeeded." >/dev/null 2>&1
 if [ $? -ne 0 ]; then
    echo "check_hpoa_proc\t\t\t: ERROR. ovcert check reports errors"
    #postemsg MINOR "hpoa_proc_problem" "HPUXCHK" "ovcert check report errors"
    set_error
    HPOAERR=TRUE
 fi

$OVC/ovpolicy -list | grep -i enabled | grep t_po_os_basic | wc -l  | read OAPOLICY
 if [ $OAPOLICY -le 5 ]; then 
    echo "check_hpoa_proc\t\t\t: WARNING. HP OA Policies might be missing or disabled."
    #postemsg MINOR "hpoa_proc_problem" "HPUXCHK" "HP OA Policies might be missing or disabled."
    set_error
    HPOAERR=TRUE
 fi

if [ "$HPOAERR" = "FALSE" ]; then
    echo "check_hpoa_proc\t\t\t: OK"
fi

} # check_hpoa_proc

check_tad4d_proc()
{
ps -ef | grep -v grep | grep tlmagent > /dev/null 2>&1
 if [ $? -ne 0 ]
    then
    echo "check_tad4d_proc\t\t: ERROR"
    postemsg INFO "tad4d_proc_problem" "HPUXCHK" "tlmagent process is not running"
    set_error
    else
    echo "check_tad4d_proc\t\t: OK"
 fi
} # check_tad4d_proc

check_cpu_usage()
{
#CPUIDLE=`sar -u 10 | tail -1 | awk '{print $5}'`
#CPUBUSY=`echo $CPUIDLE | awk '{print (100-$1)}'`
#MINIDLE=10

/opt/perf/bin/glance -q > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "check_cpu_usage\t\t\t: glance not installed."
  return
fi

THRESHOLD=90
echo "print gbl_cpu_total_util" > /tmp/glance.cpu.$$

CPUBUSY=`/opt/perf/bin/glance -j2 -adviser_only -nosort -iterations 1 -syntax /tmp/glance.cpu.$$ 2>/dev/null | tail -1 | awk '{print $1}'`

#if [ $MINIDLE -ge $CPUIDLE ]; then
if [ $CPUBUSY -ge $THRESHOLD ]; then
   echo "check_cpu_usage\t\t\t: WARNING. cpu used = $CPUBUSY% "
else
   echo "check_cpu_usage\t\t\t: OK. cpu used = $CPUBUSY%"
fi

rm /tmp/glance.cpu.$$

} # check_cpu_usage

check_mem_usage()
{
/opt/perf/bin/glance -q > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "check_mem_usage\t\t\t: glance not installed."
  return
fi

THRESHOLD=90
echo "print gbl_mem_util" > /tmp/glance.mem.$$

MEMUSED=`/opt/perf/bin/glance -j2 -adviser_only -nosort -iterations 1 -syntax /tmp/glance.mem.$$ 2>/dev/null | tail -1 | awk '{print $1}'`

if [[ $MEMUSED -ge $THRESHOLD ]]; then 
  echo "check_mem_usage\t\t\t: WARNING. mem used = $MEMUSED%"
  postemsg MINOR "mem_util_problem" "HPUXCHK" "memory usage above threshold. $MEMUSED%"
  set_error
else
  echo "check_mem_usage\t\t\t: OK. mem used = $MEMUSED%"
fi

rm /tmp/glance.mem.$$

} # check_mem_usage

check_swap_usage()
{
THRESHOLD=80
SWAPUSED=`swapinfo -tam | grep -i total | awk '{print $5}' | cut -d% -f1`
if [[ $SWAPUSED -ge $THRESHOLD ]]; then
  echo "check_swap_usage\t\t: WARNING. swap used = $SWAPUSED%"
  postemsg INFO "swap_problem" "HPUXCHK" "free swap space is low"
  set_error
else
  echo "check_swap_usage\t\t: OK. swap used = $SWAPUSED%"
fi

} # check_swap_usage

check_ip_interface()
{
ps -ef | grep cmclconfd | grep -v grep >/dev/null 2>&1
if [ $? -eq 0 ]; then
   echo "check_ip_interface\t\t: skip. found cluster service. Please check manually"
   return
fi

  ifup=`netstat -in | awk '{print $1}' | grep ^lan | sed 's/\*//'`
  ifdown=""
  iferr=0

  if [ ! -n "$ifup" ]; then
     ifdown="No IP configured!"  
  else
    for i in $ifup
     do
      /usr/sbin/ifconfig $i 2>/dev/null |grep flags |grep RUNNING > /dev/null 2>&1
      stat=$?
      [[ $stat -ne 0 ]] &&  ifdown=`echo $ifdown $i`
    done
  fi

  # check for errors and collisions
  #netstat -in |grep en |awk '{print $(NF-3) $(NF-1) $NF}' |grep -vq 000
  iferr=$(netstat -in |grep lan |awk '{print $1,$(NF-3),$(NF-1),$NF}' | grep -v " 0 0 0" | tr "\n" "/" )
  #stat=$?
  #[[ $stat -ne 1 ]] && iferr=1

  if [[ $ifdown != "" ]] || [[ $iferr != "" ]]; then
     echo "check_ip_interface\t\t: WARNING. One or more NIC has errors.ifdown=$ifdown,iferr=$iferr"
     postemsg MINOR "nic_problem" "HPUXCHK" "One or more IP Interface has errors.ifdown=$ifdown,iferr=$iferr "
     set_error
  else
     echo "check_ip_interface\t\t: OK"
  fi

} # check_ip_interface

check_default_gateway()
{
count_defgw=`netstat -rn | grep default | grep -v "link#" | wc -l`
if [[ $count_defgw -gt 1 ]]; then
  echo "check_default_gateway\t\t: WARNING. Found more than 1 default gateway"
  postemsg WARNING "gateway_problem" "HPUXCHK" "more than 1 default gateway found"
  set_error
else
  defgw_ip=`netstat -rn | grep default | grep -v "link#" | awk '{ print $2 }'`
  ping $defgw_ip -n 3 -m 3 > /dev/null 2>&1
  if [[ $? -eq 0 ]]; then
   echo "check_default_gateway\t\t: OK"
  else
   echo "check_default_gateway\t\t: ERROR. Default gateway $defgw_ip is not reachable"
   postemsg MAJOR "gateway_problem" "HPUXCHK" "Default gateway $defgw_ip is not reachable"
   set_error
  fi
fi

} # check_default_gateway

check_dns()
{
  I=0
  DNSERR=0
  if [ -f /etc/resolv.conf ]; then
     /usr/bin/grep nameserver /etc/resolv.conf | grep -v "#" | while read nop DNS_IP
     do
        let I=I+1
        ping $DNS_IP -n 3 -m 3 > /dev/null 2>&1
        if [[ $? -ne 0 ]]; then
           DNSERR=1
        fi
     done
  fi
  if [[ $DNSERR = 1 ]];then
     echo "check_dns\t\t\t: ERROR. One of more DNS is not reachable"
     postemsg MINOR "dns_problem" "HPUXCHK" "One of more DNS is not reachable"
     set_error
  else
     echo "check_dns\t\t\t: OK"
  fi
} # check_dns

check_hw_err()
{
EVENTDATE=`date +%b" "%e`
NEWEMS=`grep EMS /var/adm/syslog/syslog.log | grep "$EVENTDATE" | wc -l`
OLDEMS=`grep EMS /var/adm/syslog/syslog.log | wc -l`

if [ "$NEWEMS" -ne 0 ]; then
   echo "check_hw_err\t\t\t: ERROR. new EMS alerts found in syslog."
   postemsg MINOR "hw_problem" "HPUXCHK" "new EMS alerts found in syslog"
   set_error
fi

if [ "$OLDEMS" -ne 0 ]; then
   echo "check_hw_err\t\t\t: INFO. Old EMS alert entries found in syslog"
else
   echo "check_hw_err\t\t\t: OK" 
fi

} # check_hw_err

check_smartarray()
{
SAERROR=/tmp/check_sa.$$
SAUTIL="/usr/sbin/sautil"
if [ ! -x $SAUTIL ]; then
  echo "check_smartarray\t\t: n.a."
  return
fi

CISSDEV=$(/usr/sbin/ioscan -funC ext_bus | grep "/dev/ciss" | awk '{print $1}' 2>/dev/null)

if [ ! -n "$CISSDEV" ]; then
  echo "check_smartarray\t\t: n.a."
  return
fi

for i in $CISSDEV
 do
    $SAUTIL $i | egrep "Battery Status|Drive Status|Device Status" | grep -iv OK > /dev/null 2>&1
    if [ $? -ne 1 ]; then
      echo $i >> $SAERROR
    fi            
done

if [ -s $SAERROR ]; then
   echo "check_smartarray\t\t: ERROR. Issue found in smartarray device ( `cat $SAERROR | tr '\n' ' '`) \n"
   postemsg MINOR "smartarray_problem" "HPUXCHK" "Issue found in smartarray device  ( `cat $SAERROR | tr '\n' ' '`) \n" 
   set_error
   rm $SAERROR
else 
  echo "check_smartarray\t\t: OK"
fi

} # check_smartarray 


check_fs_space()
{
THRESHOLD="95"
FSALERT=/tmp/check_fs_space$$
EXCLUDE="Mounted|oradata|sapdata|/bc/|/ORACLE/"

bdf -l | grep [0-9]% | egrep -v "(${EXCLUDE})" | awk '{print $NF"="$(NF-1)}' | while read LINE; do
 PERC=`echo $LINE | cut -d= -f2 | cut -d% -f1`
 if [ $PERC -gt $THRESHOLD ]; then
   echo $LINE >> $FSALERT
 fi
done

if [ -s $FSALERT ]; then
  echo "check_fs_space\t\t\t: WARNING. FS usage above threshold $THRESHOLD%"
  echo "\t\t\t\t ( `cat $FSALERT | tr '\n' ' '`) \n"
  postemsg MINOR "fs_space_problem" "HPUXCHK" "FS usage above threshold. `cat $FSALERT | tr '\n' ' '`"
  set_error
  rm $FSALERT
else
  echo "check_fs_space\t\t\t: OK"
fi

} # check_fs_space

check_siux()
{
SIUX="/opt/siux/siuxstart"

if [ ! -x $SIUX ]; then
  echo "check_siux\t\t\t: SIUX is not installed"
  return
fi

crontab -l | grep $SIUX >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "check_siux\t\t\t: SIUX is not schedduled in cron"
else
  echo "check_siux\t\t\t: OK"
fi

} # check_siux

check_backup_proc()
{
LIST="simpana/Base/cvd|dsmc"

PROC=$(ps -ef | egrep -i $LIST | grep -v grep | awk -F/ '{print $NF}' | tr '\n' ' ')
if [ -z "$PROC" ]; then
  echo "check_backup_proc\t\t: No backup apps running."
else
  echo "check_backup_proc\t\t: OK. ( $PROC)"
fi

} # check_backup_proc

ping_gdc_ip()
{
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
" > $GDCIPS
echo $_DATE  > $GDCTRACE

cat $GDCIPS | while read GDC_HOST GDC_IP
do
  ping $GDC_IP -n 3 -m 3 > /dev/null 2>&1
  if [[ $? -eq 0 ]]; then
   echo "ping_gdc_ip $GDC_HOST\t: OK" | tee -a $GDCTRACE
  else
   echo "ping_gdc_ip $GDC_HOST\t: FAILED" | tee -a $GDCTRACE
   set_error
  fi

  traceroute -q1 $GDC_IP >> $GDCTRACE 2>&1
  echo "--------------------------------------------------------------" >> $GDCTRACE
done

echo "traceroute_gdc_ip\t\t: Please refer output in $GDCTRACE"

rm /tmp/gdc_core_ip.$$

} # ping_gdc_ip


#########################################
# MAIN                                  #
#########################################
main()
{
_OS=`uname -s`

if [ "$_OS" != "HP-UX" ] || [ -d /cAppCom ]; then
   echo "This is not HPUX Classic server. Exiting. "
   return
fi

_DATE=`date`
_HOSTNAME=`hostname`
_OSVER=`uname -r`
_PATCHLVL=`swlist -l bundle HPUX*OE* *BASE* 2>/dev/null | grep B.11 | awk '{print $2}' | sort -n | tail -1`
_UPTIME=`uptime | awk '{$1=""; print substr($0,2)}'`

echo "#########################################################################"
echo "                     Server Health Check Summary ($VERSION)"
echo "#########################################################################"
echo "Date      : $_DATE "
echo "Host Name : $_HOSTNAME "
echo "OS        : $_OS "
echo "OS Ver    : $_OSVER "
echo "Patch Lvl : $_PATCHLVL "
echo "Uptime    : $_UPTIME "
echo ""

check_bootlist
check_vg00_mirr 
check_lv_status
check_ignite
check_ip_interface
#check_linkaggr 
check_default_gateway
check_dns
check_ntp
check_cpu_usage
check_mem_usage
check_swap_usage
check_mount_fs
check_fs_space
check_hw_err
#check_device_status
check_smartarray 
check_hpoa_proc
check_tad4d_proc
check_connect_direct
check_siux
check_runaway_proc
check_backup_proc
ping_gdc_ip

# now check if all is OK
# this should be the last part of the script to execute.
if [ $ERROR_FOUND = FALSE ]
   then 
      echo "\nAll seems to be OK"
   else
      echo "\nOne or more problem(s) found. Error events(s) were logged in $POSTEMSG_LOG"
   fi

clean_postemsg_log

}
main > $LOG 2>&1 

if [ "$MGMT" = "true" ]; then
   cat $LOG;
fi

exit
