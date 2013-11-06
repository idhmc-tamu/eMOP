#!/bin/bash

export PATH=$PATH:/usr/local/bin

# this script lives in the root directory of the emop controller
# be sure to cd to this directory no matter how the script was 
# launched 
cd $(dirname $0)
EMOP_HOME=$(pwd)
HEAP_SIZE="256M"
APP_NAME="emop_controller"

Q_LIMIT=130
Q_TOTAL=`qselect -N ${APP_NAME} | wc -l`
Q_PENDING=`qselect -N ${APP_NAME} -s HQ | wc -l`

JOB_CNT=0

# Deletes jobs from queue that have not started
empty_queue() {
  echo "Killing ${Q_PENDING} jobs that are still queued"
  qselect -N ${APP_NAME} -s HQ | xargs qdel
}

# ensure that there is work to do before scheduling
check_job_cnt() {
  JOB_CNT=$(env EMOP_HOME=$EMOP_HOME java -Xms128M -Xmx128M -jar emop-controller.jar -check)
  CODE=$?
  if [ $CODE -ne 0 ];then
    # do not submit a new controller if there were  errors checking count
    echo "Unable to determine job count. Not launching eMOP controller"
    exit 1
  fi

  if [ $JOB_CNT -eq 0 ]; then
    echo "No work to be done"
    [ $Q_PENDING -gt 0 ] && empty_queue
    exit 0
  fi
}

# only allow 130 emop_controller jobs to be schedulated at a time
check_queue_limit() {
  if [ $Q_TOTAL -ge $Q_LIMIT ];then
    echo "${Q_LIMIT} instances of ${APP_NAME} is already running."
    exit 1
  fi
}

# there is work in the emop job_queue. Schedule the controller to process these jobs
qsub_job() {
  cmd="qsub -N ${APP_NAME} -v EMOP_HOME='$EMOP_HOME',HEAP_SIZE='$HEAP_SIZE' -e $EMOP_HOME/logs -o $EMOP_HOME/logs emop.pbs"
  echo "Executing: ${cmd}"
  eval ${cmd}
}

check_queue_limit
check_job_cnt
qsub_job

exit 0
