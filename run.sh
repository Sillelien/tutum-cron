#!/usr/bin/env bash

while [ ! -f /run/fcron.pid ]
do
    echo "Waiting for fcron"
    sleep 1
done

while true
do
    env_vars=$(env | grep ".*_DOCKERCLOUD_SERVICE_API_URL=" | cut -d= -f1 | tr '\n' ' ')

    [ ! -f /tmp/cron.tmp ] || rm /tmp/cron.tmp

    for env_var in $env_vars
    do
      # Set on the remote service
      schedule_env_var=${env_var%_ENV_DOCKERCLOUD_SERVICE_API_URL}_ENV_CRON_SCHEDULE
      #  Set on the cron service
      schedule_var=${env_var%_ENV_DOCKERCLOUD_SERVICE_API_URL}_CRON_SCHEDULE

      if [[ -n $schedule_var ]]
      then
        schedule="${!schedule_var}"
      else
        schedule="${!schedule_env_var}"
      fi
      service_url=${!env_var}

      if [[ -n $schedule ]]
      then
cat <<EOF >> /tmp/cron.tmp
${schedule} curl -X POST -H "Authorization: $DOCKERCLOUD_AUTH" -H "Accept: application/json" ${service_url}start/
EOF
      fi
    done

    echo "Installing new crontab"
    cat /tmp/cron.tmp

    fcrontab /tmp/cron.tmp
    sleep 86400
done
