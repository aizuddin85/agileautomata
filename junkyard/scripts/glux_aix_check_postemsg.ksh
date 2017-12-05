#!/bin/ksh
#---------------------------------------------------------------------------------# 
# Created By: Edmund Wong 		Created Date: Mar 2017
#
# Script name: glux_aix_check_postemsg.ksh
# Description: Custom AIX health check script to generate postesmg event for HPOA
# Location   : /local/bin/scripts
#
# Code Defination:
# AIXCHK-001: mksysb filesystem missing
# AIXCHK-002: There is no recent mksysb 
# AIXCHK-003: NO ntp servers in ntp.conf
# AIXCHK-004: NO ntp.conf found
# AIXCHK-005: xntpd does not start
# AIXCHK-006: Incorrect owner /       
# AIXCHK-007: Incorrect permissions /
# AIXCHK-008: failed paths
# AIXCHK-009: rootvg not prop. mirrored
# AIXCHK-010: Found mounted filesystem, no automount
# AIXCHK-011: inittab entry that is not executable
# AIXCHK-012: Connect:Direct process is down
# AIXCHK-013: errpt report Hardware PERM,PERF,PEND
# AIXCHK-014: Found potentially runaway processes
# AIXCHK-015: bootlist error
# AIXCHK-016: paging space is low
# AIXCHK-017: default gateway issue
# AIXCHK-018: dns issue 
# AIXCHK-019: fs space above threshold 
# AIXCHK-020: NIC issue 
#
#---------------------------------------------------------------------------------# 
#set -x
# global variables:
VERSION=1.19
ERROR_FOUND=FALSE # stays false untill set to TRUE by set_error()
LOG=/tmp/glux_aix_check_postemsg.log
POSTEMSG_LOG=/tmp/postemsg.log
POSTEMSG=TRUE

# Usage 
Usage()
{
        echo "Version $VERSION " 
        echo "Usage: $0 [-pm] " 
        echo "   	-p : Disable postemsg output. "
        echo "   	-m : Print Management Summary. "
        echo "   	-h : Print usage. "
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
_CINAME=`uname -n`
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
         echo "check_ntpd\t\t\t: NO ntp servers defined"
         postemsg MINOR "ntp.conf" "AIXCHK-003" "No ntp server defined."        
         NTPCONF_RIGHT=FALSE
         set_error
      fi
   else
      echo "check_ntpd\t\t\t: No $NTPCONF found"
      postemsg MINOR "ntp.conf" "AIXCHK-004" "No ntp.conf file found"
      NTPCONF_RIGHT=FALSE
      set_error
   fi
# now try to start ntp
# only when correct ntp.conf file found
if [ "$NTPCONF_RIGHT" = "TRUE" ]
   then
      #echo $NTPCONF " contains server definition."
      /usr/bin/lssrc -s xntpd | tail -1 | grep -i active  > /dev/null 
      if [ $? -ne 0 ] 
        then
         echo "check_nptd\t\t\t: xntpd not found running. \c "
         set_error
         # try to start
         echo "try to start it with slewing option."
         startsrc -a "-x"  -s xntpd
         /usr/bin/lssrc -s xntpd | tail -1 | grep -i active
         if [ $? -ne 0 ]
            then
              # it seems to fail starting ntp  
              echo "check_ntpd\t\t\t: ntp start not succesfull"
              postemsg MINOR "xntpd" "AIXCHK-005" "xntpd does not start"
              set_error
         fi
       else
          echo "check_ntpd\t\t\t: OK"
      fi
fi
return
} # check_ntp

check_vscsipath()
{
if [ $LPAR = FALSE ]; then
  echo "check_vscsipath\t\t\t: n.a."
  return
fi

lsdev -Cc adapter | grep "Virtual SCSI Client Adapter" | wc -l | read ADAPT
  if [ $ADAPT -ge 2 ]
   then 
       # echo "Found a virtual adapter."
       # Ok we have at least two scsi adapters
       # let's see if there are path disabled, or failed
       lspath | grep -v Enabled | wc -l | read NOTOK
       if [ $NOTOK -ne 0 ] 
          then 
              # found a path that is not enabled
              echo "check_vscsipath\t\t\t: Found path(s) that is not enabled."
              postemsg MAJOR "failed_vscsi_path" "AIXCHK-008" "Failed path(s) discovered with lspath."
              set_error
          else 
              echo "check_vscsipath\t\t\t: OK"
       fi
   else
     echo "check_vscsipath\t\t\t: n.a."
  fi

} # check_vscsipath

check_mpiopath()
{
lsdev -Cc adapter | grep "FC Adapter" | wc -l | read ADAPT
if [ $ADAPT -ge 2 ]; then
 lspath | grep fscsi | grep -v Enabled | wc -l | read NOTOK
 if [ $NOTOK -ne 0 ]; then 
   echo "check_mpiopath\t\t\t: Found path(s) that is not enabled."
   postemsg MINOR "failed_mpio_path" "AIXCHK" "Failed path(s) discovered with lspath."
   set_error
 else
   echo "check_mpiopath\t\t\t: OK"
 fi
else
 echo "check_mpiopath\t\t\t: n.a."
fi

} # check_mpio_path


check_rootvg_mirr()
{
#if [ $LPAR = TRUE ]; then
#  echo "check_rootvg_mirr\t\t: n.a."
#  return
#fi
   
# check if all lv-s in rootvg are mirrored
# except:
# sysdump
alt_rootvg=`lsvg | grep _rootvg`
if [ -n "$alt_rootvg" ]; then
    if [ -n "$(find /dev/ -mtime +14 -name $alt_rootvg)" ]; then
       echo "check_rootvg_mirr\t\t: found $alt_rootvg older than 14 days."
       OLD_ALTROOTVG=1
    else
       echo "check_rootvg_mirr\t\t: skip. found recent $alt_rootvg."
       return
    fi
 fi

ROOTVG_MIRR=/tmp/check_rootvg_error$$
lsvg -l rootvg | \
     grep -v sysdump |\
     grep -v "LV NAME" | grep -v "rootvg:" |\
     while read LINE
     do
     echo $LINE | awk '{mir=$4/$3; print mir}'  | read COPY
     if [ $COPY -ne 2 ] 
        then
             #echo $LINE
             echo $LINE >> $ROOTVG_MIRR
             #set_error
        fi
     done
# only if we found something, process the following:
if [ -s $ROOTVG_MIRR ]  # bigger than 0
   then
     if [  $(lsvg -l rootvg | grep syncd | egrep -v sysdump | wc -l ) -eq $(cat $ROOTVG_MIRR | wc -l) ]; then
        if [ "$OLD_ALTROOTVG" -eq 1 ]; then
          echo "check_rootvg_mirr\t\t: WARNING. rootvg is not mirrored."
          postemsg MINOR "rootvg_not_mirrored." "AIXCHK-009" "$alt_rootvg is older than 14 days but rootvg is still not mirrored."
          set_error
        else
          echo "check_rootvg_mirr\t\t: rootvg is not mirrored"
        fi
     else
        echo "check_rootvg_mirr\t\t: WARNING. rootvg is not mirrored correctly! "
        postemsg MINOR "rootvg_not_mirrored." "AIXCHK-009" "All lv-s in rootvg need to be mirrored except from dumpdevices. Please check for any change in progress, re-mirror it if none."
        set_error
        rm $ROOTVG_MIRR
     fi
 else
      echo "check_rootvg_mirr\t\t: OK"
 fi

} # check_rootvg_mirr

check_vg_state()
{
VG1=/tmp/check_vg_state1.$$
VG2=/tmp/check_vg_state2.$$
VGOFF=/tmp/check_vg_state3.$$
EXCLUDEVG="altinst_rootvg|old_rootvg"

/usr/sbin/lsvg > $VG1 2>/dev/null
/usr/sbin/lsvg -o > $VG2 2>/dev/null

for i in $(cat $VG1 | egrep -v $EXCLUDEVG)
do
   grep $i $VG2 >/dev/null 2>&1
   if [ $? -ne 0 ]; then
      echo $i "\c" >> $VGOFF
   fi
done

if [ -s $VGOFF ]; then 
  echo "check_vg_state\t\t\t: WARNING. Found VGs not in active state ( `cat $VGOFF`)"
  postemsg INFO "vg_problem" "AIXCHK" "Found VGs not in active state ( `cat $VGOFF`)"
  set_error
  rm $VGOFF
else
  echo "check_vg_state\t\t\t: OK"
fi

rm $VG1 $VG2

} # check_vg_state

check_lv_state()
{
LVALERT=/tmp/check_lv_state.$$

/usr/sbin/lsvg -o | xargs -I {} lsvg -Ll {} | egrep -v ":|LV NAME" | awk '{print $1"="$6}' | while read LINE; do
 STATE=`echo $LINE | cut -d= -f2 | cut -d/ -f2`
 if [ "$STATE" != "syncd" ]; then 
   echo $LINE "\c" >> $LVALERT
 fi
done

if [ -s $LVALERT ]; then 
  echo "check_lv_state\t\t\t: WARNING. Found LVs not in syncd state ( `cat $LVALERT`)"
  postemsg MINOR "lv_problem" "AIXCHK" "Found LVs not in syncd state ( `cat $LVALERT`)"
  set_error
  rm $LVALERT
else
  echo "check_lv_state\t\t\t: OK" 
fi

} # check_lv_state

check_mksysb()
{
if [ -f /usr/ios/cli/ioscli ];then
   echo "check_mksysb\t\t\t: skip. VIOS."
   return
fi

# check whether mksysb has been created recently
MAX_AGE=14 # mksysb file should be less than 14 days old
SAVEFS=/local/backup/image/  # preferred one
SAVEFS2=/mksysb_image/ # still exists... 2nd choice
FOUND_FS=FALSE
for FS in  $SAVEFS  $SAVEFS2
    do
      #echo "check " $FS 
      #lsfs $FS  > /dev/null 2>&1 
      if [ -d $FS ] 
         then
            # check if it is also mounted
            MOUNT=`df -k $FS | grep -v Filesystem | awk '{print $NF}'` 
            if [ "$MOUNT" != "/" ]
               then
                   FOUND_FS=TRUE
                   MKSYSB_FS=$FS
                   # echo $MKSYSB_FS " is filesystem used for mksysb"
               fi
         fi
    done
if [ $FOUND_FS = "FALSE" ]
   then
         echo "check_mksysb\t\t\t: ERROR. filesystem to write mksysb to is missing"
         postemsg MINOR "mksysb_missing" "AIXCHK-001" "/local/backup/image is missing or not mounted. Also check mksysb scripts in crontab"
         set_error
   else
         # echo "checking for mksysb"
         find $MKSYSB_FS -mtime -14 -name "*image*" -exec file {} \;  |\
             grep "backup/restore format file" > /dev/null 2>&1 
         if [ $? -ne 0 ] 
            then 
            echo "check_mksysb\t\t\t: WARNING. No recent mksysb file found."
            postemsg MINOR "mksysb_problem" "AIXCHK-002" "There is no recent mksysb. Check mksysb scripts in crontab and error in /var/adm/imagebackup.log"
            set_error
         else
            echo "check_mksysb\t\t\t: OK" 
         fi
   fi
} # check_mksysb
#
check_rootfs_perm()
{
PERM_ERR=FALSE
# check permissions and ownership of rootfs ( / ) 
# should be owned by root.system and 755 (rwxr-xr-x)
# echo first write to log for later checking
if [ `ls -ld / | awk '{printf("%s.%s\n",$3,$4)}'` != "root.system" ]
   then
      PERM_ERR=TRUE
      echo "check_rootfs_perm\t\t: ERROR found: incorrect ownership! " 
      echo "\nShould be owned by root.system"
      echo "Currently: ls -ld / "
      ls -ld / 
      ls -ld / | awk '{printf("%s.%s\n",$3,$4)}' | read CURR_OWNER
      # generate ticket using msend
      postemsg INFO "rootfs_ownership_problem" "AIXCHK-006" "Serious error: Incorrect ownership of / found ($CURR_OWNER). Ownership will be changed back to root.system. Find cause of this."
      echo "check_rootfs_perm\t\t: changed ownership to root.system \n" 
      chown root.system /
      set_error
   fi
# check perms
if [ `ls -ld / | awk '{print $1}'` != "drwxr-xr-x" ]
   then
      PERM_ERR=TRUE
      echo "check_rootfs_perm\t\t: ERROR found: incorrect permissions! "
      echo "\nPermissions should be drwxr-xr-x to make ssh work." 
      echo "Currently: ls -ld / "
      ls -ld / 
      ls -ld / | awk '{print $1}' | read CURR_PERM
      postemsg INFO "rootfs_permission_problem" "AIXCHK-007" "Serious error: Incorrect permissions of / found ($CURR_PERM). Permissions will be changed back to rwxr-xr-x."
      echo "check_rootfs_perm\t\t: changed permissions to rwxr-xr-x \n"
      chmod 755 /
      set_error
   fi

if [ $PERM_ERR = FALSE ]; 
   then
     echo "check_rootfs_perm\t\t: OK"
fi
} # check_rootfs_perm

check_nomount_fs()
{
# first check if hacmp installed 
# if so: do not do anything
# if not: find automount=no filesystems
# check if mount=no filesystem are in exception list
# check if it is mounted now
#
#
# first check if this might be a HACMP cluster. 
# if it is do not perform this check. 
# as hacmp managed fs should not be automounted
lslpp -L "cluster." > /dev/null 2>&1 
if [ $? -eq 0 ]
   then
       echo "check_nomount_fs\t\t: HACMP cluster: No filesystem mount check."
       return
   fi
# check if exception list exists
EXCEPT_LIST=/etc/fscheck_exceptlist
TMP_EXCEPT_LIST=/tmp/fscheck_exceptlist$$
NO_MOUNT_LIST=/tmp/fscheck_nomountlist$$
DF_LIST=/tmp/df_list$$
PROB_FS_FOUND=/tmp/probs_fs_found
if [ -r $EXCEPT_LIST ]
   then
       grep -v "^#" $EXCEPT_LIST | sed 's/#..*//' > $TMP_EXCEPT_LIST
   else
       echo "Filesystem" > $TMP_EXCEPT_LIST
   fi
# select jfs filesystems, check automount, filter defined exceptions
lsfs -c | grep -e jfs | awk -F: '{printf ("%s mount_%s\n", $1, $8)}' |\
          grep "mount_no" | grep -v -F  -f $TMP_EXCEPT_LIST  \
          | awk '{print $1}' > $NO_MOUNT_LIST
# see what is mounted
mount > $DF_LIST
for FS in `cat $NO_MOUNT_LIST `
    do
      grep $FS $DF_LIST >> $PROB_FS_FOUND
    done
if [ -s $PROB_FS_FOUND ]
   then 
       # found something potent. wrong
       # mounted filesystem, no automount, not in exceptionlist
       echo "check_nomount_fs\t\t: Following filesystems are mounted, but do not have automount=yes"
       echo "\t\t\t\t \c" 
       cat $PROB_FS_FOUND | awk '{printf $2}'
       echo ""
       postemsg MINOR "fs_automount_problem" "AIXCHK-010" "Found a mounted filesystem that will not be mounted at boot time. Adjust"
      set_error
   else 
       echo "check_nomount_fs\t\t: OK" 
   fi

rm $TMP_EXCEPT_LIST
rm $NO_MOUNT_LIST
rm $DF_LIST
rm -f $PROB_FS_FOUND
return
} # check_nomount_fs

check_inittab_exec()
{
#to check  exec inittab entries
# in development
INITTAB_ENTRYLIST=/tmp/inittablist$$
> $INITTAB_ENTRYLIST
PROBFILE_LIST=/tmp/prob_file_list$$
cat /etc/inittab | grep -v "^:" |\
  awk -F ':' '{print $4}' | awk '{print $1}' |\
  grep "^/" > $INITTAB_ENTRYLIST
# grep on ^/ to exclude cmds like startsrc
# now check if all that is found is executable
for FILE in `cat $INITTAB_ENTRYLIST`
    do
      # only check when the file is there 
      if [ -a $FILE ] 
         then
         if [ ! -x $FILE ]
            then
             echo "check_inittab_exec\t\t: $FILE is not executable!"
             # write to file so that all problem files can be in ticket
             echo $FILE >> $PROBFILE_LIST
            fi
      fi
    done
if [ -s $PROBFILE_LIST ]
   then
       TXTFILE=/tmp/txtfile$$
       # we found at least one problem
       printf '%s\n' "AIXCHK-011: Found an entry/entries in inittab that is/are not an executable files.  Adjust: " > $TXTFILE
       cat $PROBFILE_LIST >> $TXTFILE
       postemsg MINOR "inittab_problem" "AIXCHK-011" "`cat $TXTFILE`"
       set_error
       rm $TXTFILE
   else
       echo "check_inittab_exec\t\t: OK"
   fi
rm $INITTAB_ENTRYLIST
rm -f $PROBFILE_LIST
return

} # check_inittab_exec

check_errpt_hw()
{
#STARTDATE=`date +%m%d0000%y`
STARTDATE=`date +%m:%d:%H%M%y | awk -vFS=":" '{if ($2!=1) $2=$2-1;printf $1;printf("%02d",$2);printf $3$4$5}'`
errpt -d H -T PERM,PERF,PEND -s $STARTDATE | grep -v DESCRIPTION > /dev/null 2>&1
if [ $? -eq 0 ]
  then
   echo "check_errpt_hw\t\t\t: ERROR Found!" 
   HWLIST=`errpt -d H -T PERM,PERF,PEND -s $STARTDATE | grep -v DESCRIPTION | awk '{print $5}' | sort | uniq`
   postemsg MAJOR "hardware_problem" "AIXCHK-013" "ERRPT reported hardware issue on $HWLIST"
   set_error
  else
   echo "check_errpt_hw\t\t\t: OK"
fi
} # check_errpt_hw

check_runaway_proc()
{
RUNAWAY_PROC=/tmp/chk.runaway_proc.$$
MINTIME=5000000
EXCLUDEPROC="COMMAND|sync|ora_.mon_"
#ps -ea | egrep -v $EXCLUDEPROC | sort -rnk 3 | head -20 | sed -e 's/\://g' | \
# awk -v MIN=$MINTIME '$3 > MIN {print $1"("$4")"}' > $RUNAWAY_PROC

ps -ef -o pid,time,comm,args | egrep -v $EXCLUDEPROC | awk '{print $1,$2,$3,$4}' | sort -rk2 | head -20 | sed -e 's/[\:\-]//g' | \
 awk -v MIN=$MINTIME '$2 > MIN {print $1"("$3")"}' > $RUNAWAY_PROC 2>/dev/null

if [ -s $RUNAWAY_PROC ]
   then
   echo "check_runaway_proc\t\t: Found potential runaway processes `cat $RUNAWAY_PROC | tr '\n' ' '`"
   echo ""
   postemsg MINOR "runaway_proc_problem" "AIXCHK-014" "Found potential runaway processes `cat $RUNAWAY_PROC`"
   set_error
   else
   echo "check_runaway_proc\t\t: OK" 
fi
rm $RUNAWAY_PROC

} # check_runaway_proc

check_defunct_proc()
{

THRESHOLD=16
DEFCOUNT=$(ps -ef | grep defunct | wc -l)

if [ "$DEFCOUNT" -gt "$THRESHOLD" ]; then
  echo "check_defunct_proc\t\t: WARNING. Found more than $THRESHOLD defunct processes."
  postemsg MINOR "defunct_proc_problem" "AIXCHK" "Found more than $THRESHOLD defunct processes"
  set_error
  else
  echo "check_defunct_proc\t\t: OK"
fi

} # check_defunct_proc

check_hpoa_proc()
{
HPOAERR=FALSE
OVC=/usr/lpp/OV/bin

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
    return
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
    postemsg INFO "tad4d_proc_problem" "AIXCHK" "tlmagent process is not running"
    set_error
    else
    echo "check_tad4d_proc\t\t: OK"
 fi
} # check_tad4d_proc

check_nmon_proc()
{
ps -ef | grep -v grep | grep nmon > /dev/null 2>&1
 if [ $? -ne 0 ]
    then
    echo "check_nmon_proc\t\t\t: nmon process is not running"
    #postemsg INFO "nmon_proc_problem" "AIXCHK" "nmon process is not running"
    #set_error
    else 
    echo "check_nmon_proc\t\t\t: OK"
 fi
} # check_nmon_proc

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
        postemsg MAJOR "cdunix_problem" "AIXCHK-012" "Connect:Direct process is DOWN. Please check and restart" 
        set_error
        else
        echo "check_connect_direct\t\t: OK"
     fi
   else
     echo "check_connect_direct\t\t: n.a."
fi
} # check_connect_direct

check_bootlist()
{
BOOTERR=FALSE
#BOOTLV=$(lsvg -l rootvg | grep boot | awk '{print $1}')
BOOTLV=$(bootinfo -v)
BOOTLIST1=$(lslv -l $BOOTLV 2> /dev/null | grep hdisk | cut -d" " -f1 | sort)
BOOTLIST2=$(bootlist -m normal -o | grep hdisk | cut -d" " -f1 | sort -u)

  if [ "$BOOTLIST1" != "$BOOTLIST2" ]; then
     echo "check_bootlist\t\t\t: check if hd5 is on all hdisks"
     postemsg MINOR "bootlist_problem" "AIXCHK-015" "Bootlist mismatch. check if hd5 is on all hdisks "
     set_error
     BOOTERR=TRUE
  fi

  for i in $BOOTLIST1; do
    bosboot -vd $i >/dev/null 2>&1
     if [ $? -ne 0 ]; then
         echo  "check_bootlist\t\t\t: bosboot verify fails on $i"
         postemsg MINOR "bootlist_problem" "AIXCHK-015" "bosboot verify fails on $i"
         set_error
         BOOTERR=TRUE
     fi
  done    

#BOOTSTRAPLIST=`ipl_varyon -i |grep YES |awk '{print $1}'`
#  for i in $BOOTLIST1; do
#    echo $BOOTSTRAPLIST | grep -w "$i" >/dev/null 2>&1
#   if [ $? -ne 0 ]; then
#      echo  "check_bootlist\t\t\t: bootstrap not correct for $i"
#      postemsg MINOR "bootlist_problem" "AIXCHK-015" "bootstrap not correct for $i"
#      set_error
#      BOOTERR=TRUE
#    fi
#  done

if [ $BOOTERR = FALSE ]; then
   echo "check_bootlist\t\t\t: OK"
fi

} # check_bootlist

check_cpu_avg()
{
CPUIDLE=`sar -u 10 | tail -1 | awk '{print $5}'`
CPUBUSY=`echo $CPUIDLE | awk '{print (100-$1)}'`
MINIDLE=10

if [ $MINIDLE -ge $CPUIDLE ]; then
   echo "check_cpu_avg\t\t\t: WARNING. Avg CPU usage = $CPUBUSY% "
else
   echo "check_cpu_avg\t\t\t: OK. Avg CPU usage = $CPUBUSY%"
fi
}

check_paging_usage()
{
MAXPS=80
PSUSED=`lsps -s | tail -1 | awk '{print $NF}' | cut -d% -f1`
if [[ $PSUSED -ge $MAXPS ]]; then
  echo "check_paging_usage\t\t: WARNING. paging space used = $PSUSED%"
  postemsg INFO "paging_problem" "AIXCHK-016" "paging space is low"
  set_error
else
  echo "check_paging_usage\t\t: OK. Paging space used = $PSUSED%"
fi

} # check_paging_usage

check_ip_interface()
{
  ifup=`/etc/ifconfig -lu`
  ifdown=""
  iferr=0
  for i in $ifup
  do
    ifconfig $i |grep flags |grep RUNNING > /dev/null 2>&1
    stat=$?
    [[ $stat -ne 0 ]] &&  ifdown=`echo $ifdown $i`
  done

  # check for errors and collisions
  iferr=$(netstat -in |grep en | grep -v "link#" |awk '{print $1,$(NF-3),$(NF-1),$NF}' | grep -v " 0 0 0" | tr "\n" "/" )

  if [[ $ifdown != "" ]] || [[ $iferr != "" ]]; then
     echo "check_ip_interface\t\t: WARNING. One or more NIC has errors.ifdown=$ifdown,iferr=$iferr"
     postemsg MINOR "nic_problem" "AIXCHK-020" "One or more IP Interface has errors.ifdown=$ifdown,iferr=$iferr"
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
  postemsg WARNING "gateway_problem" "AIXCHK-017" "more than 1 default gateway found"
  set_error
else
  defgw_ip=`netstat -rn | grep default | grep -v "link#" | awk '{ print $2 }'`
  ping -qc 3 $defgw_ip > /dev/null 2>&1
  if [[ $? -eq 0 ]]; then
   echo "check_default_gateway\t\t: OK"
  else
   echo "check_default_gateway\t\t: ERROR. Default gateway $defgw_ip is not reachable"
   postemsg MAJOR "gateway_problem" "AIXCHK-017" "Default gateway $defgw_ip is not reachable"
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
        /usr/bin/dig @$DNS_IP -x $DNS_IP +time=2 +retry=2 > /dev/null 2>&1
        if [[ $? -ne 0 ]]; then
           DNSERR=1
        fi
     done
  fi
  if [[ $DNSERR = 1 ]];then
     echo "check_dns\t\t\t: ERROR. One of more DNS is not reachable"
     postemsg MINOR "dns_problem" "AIXCHK-018" "One of more DNS is not reachable"
     set_error
  else
     echo "check_dns\t\t\t: OK"
  fi
} # check_dns

check_fs_space()
{
THRESHOLD="96"
FSALERT=/tmp/check_fs_space$$
EXCLUDE="Mounted|proc|ahafs|oradata|oraredo|sapdata|:/| - |/local/dat[0-9]|/local/nim/"

df -k | egrep -v "(${EXCLUDE})" |  awk '{print $7"="$4}' | while read LINE; do
 PERC=`echo $LINE | cut -d= -f2 | cut -d% -f1`
 if [ $PERC -gt $THRESHOLD ]; then
   echo $LINE >> $FSALERT
 fi
done

if [ -s $FSALERT ]; then
  echo "check_fs_space\t\t\t: WARNING. FS usage above threshold $THRESHOLD%"
  echo "\t\t\t\t ( `cat $FSALERT | tr '\n' ' '`) \n"
  postemsg MINOR "fs_space_problem" "AIXCHK-019" "FS usage above threshold. `cat $FSALERT | tr '\n' ' '`"
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
  echo "check_siux\t\t\t: SIUX is not scheduled in cron"
else
  echo "check_siux\t\t\t: OK"
fi

} # check_siux

check_backup_proc()
{
LIST="simpana/Base/cvd|dsmc|dsmserv"

PROC=$(ps -ef | egrep -i $LIST | grep -v grep | awk -F: '{print substr($NF,3)}' | awk '{print $1}' | sort -u | awk -F/ '{printf $NF" "}')
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
  ping -qc 3 $GDC_IP > /dev/null 2>&1
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

if [ "$_OS" != "AIX" ] || [ -d /cAppCom ]; then
   echo "This is not an AIX Classic server. Exiting. "
   return
fi

_DATE=`date`
_HOSTNAME=`uname -n`
_OSVER=`oslevel`
_PATCHLVL=`oslevel -s`
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

#
# In case this is an LPAR check:
# do we have an etherchannel
which lparstat > /dev/null
if [ $? -eq 0 ]
   then
   # lparstat command found
   # on higher version of 5.3 lparstat is known also if not lpar
   # so check whether it really is lpar
   lparstat -i | grep "Partition Number" | awk -F: '{print $2}' | read TEST
   if [ $TEST = '-' ]
      then
         LPAR=FALSE
      else
         LPAR=TRUE 
      fi
else
   LPAR=FALSE
fi

# calling functions
check_bootlist
check_rootfs_perm
check_inittab_exec
check_rootvg_mirr 
check_vg_state
check_lv_state
check_mksysb
check_ip_interface
check_default_gateway
check_dns
check_ntp
check_cpu_avg
check_paging_usage
check_hpoa_proc
check_tad4d_proc
check_nmon_proc
check_connect_direct
check_siux
check_backup_proc
check_runaway_proc
check_defunct_proc
check_errpt_hw
check_nomount_fs
check_fs_space
check_vscsipath 
check_mpiopath
ping_gdc_ip

# now check if all is OK
# this should be the last part of the script to execute.
if [ $ERROR_FOUND = FALSE ]
   then 
      echo "\nAll seems to be OK"
   else
      echo "\nOne or more problem(s) found. Error event(s) were logged in $POSTEMSG_LOG"
   fi

clean_postemsg_log

}
main > $LOG 2>&1 

if [ "$MGMT" = "true" ]; then
   cat $LOG;
fi

exit
