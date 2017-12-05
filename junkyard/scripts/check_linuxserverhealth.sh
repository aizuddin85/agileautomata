#/bin/bash
# Author: Zali, Muhammad Aizuddin
# Date: 07 April 2017
# Linux Critical Service Check Chores

echo "Checking crond..."
croncount=`pidof crond | wc -l`
if [ $croncount -gt 1 ];then
    echo  "FAILED: Please check crond, it might be running more than one parent."
elif [ $croncount -eq 0 ];then
    echo "FAILED: Crond might not running, start it if no process!"
else
    echo "PASSED: Crond OK!"
fi

echo
echo "Checking autofs..."
autofscount=`pidof automount|wc -l`
if [ $autofscount -gt 1 ]; then
    echo  "FAILED: Please check , it might be running more than one parent."
elif [ $autofscount -eq 0 ];then
    service autofs start
    autofscount=`pidof automount|wc -l`
    if [  $autofscount -eq 0 ];then
        echo "FAILED: Autofs might not running, start it if no process!"
    fi
else
    echo "PASSED: Autofs OK!"
fi

echo
echo "Checking auto.master..."
automaster=`cat /etc/auto.master| wc -l`
if [ $automaster -lt 5 ]; then
    /opt/adi/sbin/automaster.py
    service autofs reload
    automaster=`cat /etc/auto.master| wc -l`
    if [ $automaster -lt 5 ]; then
        echo "FAILED: /etc/auto.master might be empty."
    fi
else
    echo "PASSED: /etc/auto.master OK!"
fi

hostident=`hostname`
if [ ${hostident:0:3} == "ams" ]; then
      echo
      echo "Checking AMS  /etc/auto.maps/auto.glb.home count"
      homecount=`wc -l /etc/auto.maps/auto.glb.home | awk '{print $1}'`
      if [[ $homecount -lt 1200 ]]; then
          echo "FAILED: /etc/auto.maps/auto.glb.home not fetching all map, do:"
          echo "1. edit /etc/ldap.conf, change uri line to 'uri ldap://amsdc1-s-51003.linux.shell.com:389'"
          echo "2. rm -rf /etc/auto.maps; rm -rf /var/db/*"
          echo "3. /opt/adi/sbin/dumpad.py"
          echo "4. service autofs reload"
      else
          echo "PASSED: auto.glb.home count is $homecount"
      fi
elif [ ${hostident:0:3} == "hou" ]; then
    echo
    echo "Checking HOU /etc/auto.maps/auto.glb.home count"
    homecount=`wc -l /etc/auto.maps/auto.glb.home | awk '{print $1}'`
    if [ $homecount -lt 1200 ];then
        echo "FAILED: /etc/auto.maps/auto.glb.home not fetching all map, do:"
        echo "1. edit /etc/ldap.conf, change uri line to 'uri ldap://amsdc1-s-51003.linux.shell.com:389'"
        echo "2. rm -rf /etc/auto.maps; rm -rf /var/db/*"
        echo "3. /opt/adi/sbin/dumpad.py"
        echo "4. service autofs reload"
    else
        echo "PASSED: auto.glb.home count is $homecount"
    fi
else
    echo
    echo "Checking /etc/auto.maps/auto.glb.home count"
    homecount=`wc -l /etc/auto.maps/auto.glb.home | awk '{print $1}'`
    if [ $homecount -eq 0 ];then
        echo "FAILED: /etc/auto.maps/auto.glb.home count test failed"
    else
        echo "PASSED: auto.glb.home count OK!"
    fi
fi


echo
echo "Checking auto.maps..."
automaps=`ls -lrt  /etc/auto.maps/| wc -l`
if [ $automaps -eq 0 ]; then
    echo "FAILED: /etc/auto.maps dir might be empty. Do:"
    echo "1. edit /etc/ldap.conf, change uri line to 'uri ldap://amsdc1-s-51003.linux.shell.com:389'"
    echo "2. rm -rf /etc/auto.maps; rm -rf /var/db/*"
    echo "3. /opt/adi/sbin/dumpad.py"
    echo "4. service autofs reload"
else
    echo "PASSED: /etc/auto.maps dir OK!"
fi

echo
echo "Checking automount list..."
automountcount=`automount -m| wc -l`
if [ $automountcount -lt 10 ]; then
    echo "FAILED: Check auto.master, auto.maps dir and autofs process."
else
    echo "PASSED: Automount map OK!"
fi

echo
echo "Checking user entries..."
user=`getent passwd|wc -l`
if [ $user -lt 500 ]; then
    echo "FAILED: Check /var/db directory for user or try to su your account, if failed do:"
    echo "1. edit /etc/ldap.conf, change uri line to 'uri ldap://amsdc1-s-51003.linux.shell.com:389'"
    echo "2. rm -rf /etc/auto.maps; rm -rf /var/db/*"
    echo "3. /opt/adi/sbin/dumpad.py"
    echo "4. service autofs reload"

else
    echo "PASSED: User listing OK!"
fi


