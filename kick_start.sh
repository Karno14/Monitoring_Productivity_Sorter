#!/bin/bash

# Production
# JV-TAB-RPT-AWARE - Ex CDATA APIGEE
# curl --location --request GET 'http://10.168.5.145:8081/kettle/status/?xml=Y' --header 'Authorization: Basic Y2x1c3RlcjpjbHVzdGVy'
# cd /repository/pentaho/repositories/DAD_poc
# ./kick_start.sh 10.168.5.145 8081 Basic
# chmod +x kick_start.sh


##Parameter
#  1 : IP Carte
#  2 : Port Carte
#  3 : Log Level [Basic, Detailed, Debug, Rowlevel, Error, Nothing]
#  4 : Authorization (kosongkan saja)
# Example script.sh 10.10.10.10 8081 Basic

# Prerequisite
# 1. buat repositories.xml di server lokal. /app/data-integration
# 1. Nama folder di bawah Repositories, harus sama dengan variable project_name
# 2. Trans Executor -> pemanggilan nama file harus seperti ini .. jangan ada file extention KTR
#    ${Internal.Entry.Current.Directory}/DigitalOffice_Helloworld/DAD_helloworld
#

#########################################################
## PIC update hanya di block ini saja

## System Variable
# Production path
repo_directory=/repository/pentaho/repositories

repoName=DADRepo

log_daily_dir=/repository/pentaho/actions/logs_daily_temp
log_alltime_dir=/repository/pentaho/actions/logs_alltime

# prject_name adalah  nama folder di /repository/pentaho/repositories/
project_name=DAD_Daily_Monitoring_Productivity_Sorter
project_dir=/repository/pentaho/repositories/$project_name
# harus berikut dengan extention nya
job_file_name=DAD_Daily_Monitoring_Productivity_Sorter.kjb
#job_file_name=DAD_poc.ktr

#########################################################


# Default Arguments
destination_carte_ip=${1:-localhost}
destination_carte_port=${2:-8081}
log_level=${3:-Basic}
destination_carte_auth=${4:-"Basic Y2x1c3RlcjpjbHVzdGVy"}

## Auto Initiate Variable
#  ambil Pentaho Directory pada masing2 server dari file ${repo_directory}/config.ini
pentaho_dir_temp=$(sed -nr "/^\[PDI_DIRECTORY\]/ { :l /^${destination_carte_ip}[ ]*=/ { s/[^=]*=[ ]*//; p; q;}; n; b l;}" ${repo_directory}/config.ini)
#  hasil dari pentaho_dir_temp, masih ada carriage return nya, jadi harus di remove
pentaho_dir=$(echo $pentaho_dir_temp | sed -e 's/\r//g')

tgl_log=`date +%Y%m%d`
#log_file=$log_daily_dir/$project_name-${tgl_log}.log
log_cron=$log_alltime_dir/$project_name.cronjob.log

#current_log_file=$log_daily_dir/currentlog_$project_name.log
tgl=`date -d "+0 hours"`
checkrun=`date +%H`
extention=${job_file_name#*.}
extention=${extention^^}
package_name="${job_file_name%%.*}"


# echo $tgl
# echo $extention

#echo $log_cron
#echo $destination_carte_auth
#exit 0

############################################################################################
## MULAI PANGGIL PAN / KITCHEN
############################################################################################
cd $pentaho_dir
start_execution_time=`date -d "+0 hours"`
epoch_start=$(date --date "$start_execution_time" +%s)

#echo "---------------------------START--------------------------------" > $current_log_file
#echo "Start Execution : $start_execution_time" >> $current_log_file

if [ "$extention" = "KTR" ]; then
    echo "ExecuteTrans"
    # sh pan.sh -file:"$project_dir"/$job_file_name >> $current_log_file -level:Minimal
    # Parameter Repo mandatory kalau Execute Trans
    # karena API ini, pakai repo, maka value dari Internal.Entry.Current.Directory di override dari luar
    curl --location --request GET "http://${destination_carte_ip}:${destination_carte_port}/kettle/executeTrans/?rep=${repoName}&trans=/${project_name}/${package_name}&level=${log_level}&DAD.Log.Daily.Directory=${log_daily_dir}&Internal.Entry.Current.Directory=${project_dir}" --header "Authorization: ${destination_carte_auth}"    
elif [ "$extention" = "KJB" ]; then
    echo "ExecuteJob"
    # Api ini tidak bisa send Argument, sehingga tidak bisa override Internal.Entry.Current.Directory
    # API ini, tidak pakai repo, karena tidak bisa deteksi Internal.Entry.Current.Directory
    curl --location --request GET "http://${destination_carte_ip}:${destination_carte_port}/kettle/executeJob/?job=${project_dir}/${job_file_name}&level=${log_level}" --header "Authorization: ${destination_carte_auth}"
else
    echo "Not a Pentaho Package"
fi

end_execution_time=`date -d "+0 hours"`
epoch_end=$(date --date "$end_execution_time" +%s)

diff_in_minutes=$(( ($epoch_end - $epoch_start) / 60 ))
diff_in_seconds=$(( ($epoch_end - $epoch_start) ))

#echo "End Execution : $end_execution_time" >> $current_log_file
#echo "Running time : $diff_in_seconds seconds" >> $current_log_file
#echo "Running time : $diff_in_minutes minutes" >> $current_log_file
#echo "----------------------------END---------------------------------" >> $current_log_file

#cat $current_log_file >> $log_file

echo "$start_execution_time ; $end_execution_time ; $diff_in_seconds seconds ; $diff_in_minutes minutes" >> $log_cron

############################################################################################
## DEBUG
############################################################################################
# ps -ef | grep carte

# ls -al /home/pentaho/actions/logs_daily_temp
# cat /home/pentaho/actions/logs_daily_temp/currentlog_DigitalOffice_Helloworld.log
# cat /home/pentaho/actions/logs_daily_temp/DigitalOffice_Helloworld-20220309.log

# ls -al /home/pentaho/actions/logs_alltime
# cat /home/pentaho/actions/logs_alltime/DigitalOffice_Helloworld.cronjob.log

# rm /home/pentaho/actions/logs_daily_temp/DigitalOffice_Helloworld-20220309.log


# Misal nya ini file Cron

# ETL Server A
# 0 0 * * * /path_to_sh/DigitalOffice_Helloworld.kickstart.sh 10.10.10.224 8081 Basic

# ETL Server B
# 0 0 * * * /path_to_sh/MIS_Helloworld.kickstart.sh 10.10.10.222 8080 Basic

# ETL Server C
# 0 0 * * * /path_to_sh/MIS_Helloworld.kickstart.sh 10.10.10.222 8080 Basic
# 0 0 * * * /path_to_sh/MIS_Helloworld.kickstart.sh 10.10.10.222 8080 Basic /home/ubuntu/data-integration


