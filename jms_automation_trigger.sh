#!/bin/sh
#Purpose: To trigger automation suite for JMS after build successfully made.
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

## Triggering automation suite for RBU
#nohup sshpass -p 'automation' ssh cavisson@10.10.30.52 "nohup bash /home/cavisson/work/RBU_Automation_Trigger.sh -r ${Release} -b ${Build}" &> /tmp/automation_rbu_trigger.log &
#nohup sshpass -p 'Cavisson3' ssh cavisson@10.10.30.20 "nohup bash /home/cavisson/NVSM_Controller/NVSM_Build_Upgrade_tool.sh -r ${Release} -b ${Build}" &> /tmp/NVSM_BuildUpgrade_trigger.log &


#Download build from buildHub
cd /home/cavisson/work/upgrade
curl -O http://10.10.30.16:8992/U16/${Release}/netstorm_all.${Release}.${Build}_Ubuntu1604_64.bin 
curl -O http://10.10.30.16:8992/U16/${Release}/thirdparty.${Release}.${Build}_Ubuntu1604_64.bin

if [ $? -eq 0 ];then
echo "build downloaded successfully!!"
export NS_WDIR="/home/cavisson/work"
export TOMCAT_DIR="/home/cavisson/work/apps/apache-tomcat-7.0.91"
export TOMCAT_CMD="tomcat"

bash /home/cavisson/work/upgrade/thirdparty.${Release}.${Build}_Ubuntu1604_64.bin

sleep 5

bash /home/cavisson/work/upgrade/netstorm_all.${Release}.${Build}_Ubuntu1604_64.bin

sleep 5

version=$(nsu_get_version | head -1 | awk -F " " '{print $2}')
build=$(nsu_get_version | head -1 | cut -d " " -f4 | cut -d ")" -f1)

if [ "$version" == "$Release" ] && [ "$build" == "$Build" ];then
   #Going to trigger automation suite
   export NS_WDIR="/home/cavisson/work"
   export HOME_DIR="/home/cavisson"
   export JAVA_HOME="/home/cavisson/apps/jdk1.8.0_161"
   tomcat_pid=$(cat $TOMCAT_DIR/logs/tomcat.pid)
   #Killing tomcat PID as it is not needed and sometimes it causes increase in load avg
   kill -9 $tomcat_pid
   cd /home/automation/workbench/automation/nscore_parallel exec && nohup ant smoke 1>/tmp/start_JMS_automation_${Release}_${Build}.log 2>&1 &
else
  echo "Build is not upgraded properly !!"
fi
fi
fi
exit
