#!/bin/bash
# This Rally test starts an instance, assigns a floating IP, connects to it over SSH and runs a script that pings Google five times
cd /root/rally
rally task start boot-runcommand-delete_ping.json

# this part checks the status of the report and alerts in case of failures
alert_address="your_email@server.com"

last_check=`rally task list | tail -n2| head -n1| awk -F"|" '{print $2}'`
rally task report $last_check --out  /var/www/html/rally/ping_reports/`date +%b-%d-%y_%H:%M`.html

task_status_temp=`rally task list|  tail -n2| head -n1| awk -F"|" '{print $6}'`
task_status=`echo ${task_status_temp//[[:blank:]]/}`

result=`rally task results | grep packet_loss| awk -F":" '{print$2}'`
detailed_task_result=`rally task results`

if [ $task_status != "finished" ]
then /usr/lib/zabbix/alertscripts/gmail_alert.sh ${alert_address} "The status of the last Rally health ping check is $task_status, please investigate why." "The detailed result of the last rally task is: \"$detailed_task_result\"";
exit 1
fi

result=`rally task results | grep packet_loss | awk -F":" '{print $2}' | awk -F"}" '{print $1}'`
if [ -z $result ]
then /usr/lib/zabbix/alertscripts/gmail_alert.sh ${alert_address} "The status of the last Rally health ping check failed to run, please investigate why." "$detailed_task_result";
exit 1
fi
if [ $result -ge 2 ]
then /usr/lib/zabbix/alertscripts/gmail_alert.sh ${alert_address} "The Rally health ping check failed because the ping packet data loss was $result%" "$detailed_task_result";
fi


# Check the SLA status
result=`rally task sla_check | grep "max_seconds_per_iteration"| grep PASS| wc -l`
detailed_task_result=`rally task results`
if [ $result -ne 1 ]
then /usr/lib/zabbix/alertscripts/gmail_alert.sh ${alert_address} "The Rally ping check failed its SLA of 150 seconds, please investigate why." "The detailed result of the last rally task is: \"$detailed_task_result\"";
exit 1
fi

# Send the runtime to Ghraphite
runtime=`rally task sla_check | grep "max_seconds_per_iteration"| awk -F"|" '{print $6}'| awk '{print $5}' | sed 's/s//'`
echo "rally.ping_test  $runtime `date +%s`" | nc localhost 2003;

