#!/bin/sh
#Purpose: To trigger automation suite for JMS after build successfully made.
#Author: Asheesh Tivaree
##---------------------------------------------------------------------------

function display_help_and_exit()
{
 echo "Provide Release and Version in manner (-r 4.1.2 -b 52)"
}

while getopts r:b:h option
do
  case "$option" in
    r) Release="$OPTARG" ;;
    b) Build="$OPTARG" ;;
    h) display_help_and_exit ;;
  esac
done

if [ -z $Release ] && [ -z $Build ];then
  display_help_and_exit
else

#Download build from buildHub
cd /home/cavisson/NVSM/upgrade
curl -O http://10.10.30.16:8992/U16/${Release}/netstorm_all.${Release}.${Build}_Ubuntu1604_64.bin 
curl -O http://10.10.30.16:8992/U16/${Release}/thirdparty.${Release}.${Build}_Ubuntu1604_64.bin

if [ $? -eq 0 ];then
echo "build downloaded successfully!!"
export NS_WDIR="/home/cavisson/NVSM"
export TOMCAT_DIR="/home/cavisson/NVSM/apps/apache-tomcat-7.0.104"
export TOMCAT_CMD="tomcat"

bash /home/cavisson/NVSM/upgrade/thirdparty.${Release}.${Build}_Ubuntu1604_64.bin

sleep 5

bash /home/cavisson/NVSM/upgrade/netstorm_all.${Release}.${Build}_Ubuntu1604_64.bin

sleep 5

version=$(nsu_get_version | head -1 | awk -F " " '{print $2}')
build=$(nsu_get_version | head -1 | cut -d '#' -f2 | cut -d ')' -f1 | sed -e 's/\ //g')

if [ "$version" == "$Release" ] && [ "$build" == "$Build" ];then
   #Going to trigger automation suite
   export NS_WDIR="/home/cavisson/NVSM"
   export HOME_DIR="/home/cavisson"
   export JAVA_HOME="/home/cavisson/apps/jdk1.8.0_251"
   tomcat_pid=$(cat $TOMCAT_DIR/logs/tomcat.pid)
   #Killing tomcat PID as it is not needed and sometimes it causes increase in load avg
   #kill -9 $tomcat_pid
   sleep 5s
   #nohup sshpass -p 'automation' ssh cavisson@10.10.30.207 "nohup bash /home/cavisson/work/RBU_Automation_Trigger.sh -r ${Release} -b ${Build}" &> /tmp/automation_rbu_trigger.log &
else
  echo "Build is not upgraded properly !!"
fi
fi
fi
exit
