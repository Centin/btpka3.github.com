#!/bin/bash

# chkconfig: 2345 60 60
# description:
#
### BEGIN INIT INFO
# Provides: center
# Required-Start: $network
# Required-Stop: $network
# Should-Start:
# Should-Stop:
# X-Start-Before:
# X-Stop-After:
# X-Interactive: false
# Defalt-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description:
# Description:
### END INIT INFO
#
# NOTICE: This script should be ran with super user

########################### Common Init

## Source function library.
. /etc/rc.d/init.d/functions
DISTRIB_ID=`lsb_release -i -s 2>/dev/null`

# For SELinux we need to use 'runuser' not 'su'
if [ -x "/sbin/runuser" ]; then
  SU="/sbin/runuser -s /bin/sh"
else
  SU="/bin/su -s /bin/sh"
fi


########################### Prepare
NAME="$(basename $0)"
if [ "${NAME:0:1}" = "S" -o "${NAME:0:1}" = "K" ]; then
  NAME="${NAME:3}"
fi

########################### Settings

RUNNING_USER=$USER
CMD_START="/path/to/app start"
CMD_STOP="/path/to/app stop"
LOCK_FILE="/var/lock/subsys/${NAME}"
PID_FILE="/var/run/${NAME}.pid"
LOG_FILE="/var/log/${NAME}.log"
SHUTDOWN_WAIT=3

########################### ENV PASSED
ENV_PASS="export PID_FILE='${PID_FILE}';"

# when using tomcat, uncomment the following command
# export CATALINA_PID=${PID_FILE}
#ENV_PASS="export CATALINA_PID='${PID_FILE}'; ${ENV_PASS}"

########################### Functions

function start() {
  echo -n "Starting ${NAME}: "

# is running ?
  if [ -f "${LOCK_FILE}" ]; then
    if [ -f "${PID_FILE}" ]; then
      read kpid < "${LOCK_FILE}"
      if [ -d "/proc/${kpid}" ]; then
        success; echo
        return
      fi
    fi
  fi

# fix permissions on the log and pid files
  touch "${PID_FILE}" 2>&1
  RETVAL=$?
  if [ "${RETVAL}" -ne "0" ]; then
    echo
    echo -n "Error creating pid file '${PID_FILE}'. ${RETVAL}"
    failure; echo
    return
  fi

  chown ${RUNNING_USER}:${RUNNING_USER} "${PID_FILE}"
  RETVAL=$?
  if [ "${RETVAL}" -ne "0" ]; then
    echo
    echo -n "Error chown pid file '${PID_FILE}' to usr '${RUNNING_USER}'. ${RETVAL}"
    failure; echo
    return
  fi

  touch "${LOG_FILE}" 2>&1
  RETVAL=$?
  if [ "${RETVAL}" -ne "0" ]; then
    echo
    echo -n "Error creating log file '${LOG_FILE}'. ${RETVAL}"
    failure; echo
    return
  fi

  chown ${RUNNING_USER}:${RUNNING_USER} "${LOG_FILE}"
  RETVAL=$?
  if [ "${RETVAL}" -ne "0" ]; then
    echo
    echo -n "Error chown log file '${LOG_FILE}' to usr '${RUNNING_USER}'. ${RETVAL}"
    faiture; echo
    return
  fi

  $SU - ${RUNNING_USER} -c "${ENV_PASS} ${CMD_START} >> ${LOG_FILE} 2>&1"
  #$SU - ${RUNNING_USER} -c "${ENV_PASS} ${CMD_START} "
  RETVAL=$?
  if [ "${RETVAL}" -eq "0" ]; then
    success; echo
    touch "${LOCK_FILE}"
  else
    echo
    echo -n "Error executing command. ${RETVAL}"
    failure; echo
  fi
}

function stop() {
  echo -n "Stopping ${NAME}: "
  if [ -f "${LOCK_FILE}" ]; then

# stop command is empty? Then kill pid, and remove pid file
    if [ -z "${CMD_STOP}" ]; then
      if [ -f "${PID_FILE}" ]; then
        read kpid < "${PID_FILE}"
        if [ -n "${kpid}" ]; then
          if [ -d "/proc/${kpid}" ]; then
            kill ${kpid}
          fi
          success; echo
        else
          #echo
          #echo -n "PID file is empty, remove it [$kpid]"
          success; echo
        fi
        rm -f "${PID_FILE}"
      else
        echo
        echo -n "PID file is not exists"
        success; echo
      fi

    else
      $SU - ${RUNNING_USER} -c "${ENV_PASS} ${CMD_STOP} >> ${LOG_FILE} 2>&1"
      #$SU - ${RUNNING_USER} -c "${ENV_PASS} ${CMD_STOP}"
    fi

# If process is still running, wait some seconds and kill it.
    if [ -f "${PID_FILE}" ]; then
      read kpid < "${PID_FILE}"
      if [ -n "${kpid}" ]; then
        if [ -d "/proc/${kpid}" ]; then
          count=0
          until [ "$(ps --pid $kpid | grep -c $kpid)" -eq "0" ] || \
                [ "$count" -gt "$SHUTDOWN_WAIT" ]; do
            sleep 1
            let count="${count}+1"
          done

          if [ "$count" -gt "$SHUTDOWN_WAIT" ]; then
            echo
            echo -n "killing processes which did not stop \
after ${SHUTDOWN_WAIT} seconds"
            warning; echo
          fi

          kill -9 $kpid
        fi

        success; echo

      else
        #echo
        #echo -n "PID file is empty, remove it"
        success; echo
      fi
      rm -f "${PID_FILE}" "${LOCK_FILE}"
    else
      success; echo
    fi
  else
    success; echo
  fi

}

function status() {
  if [ -f "${PID_FILE}" ]; then
    read kpid < "${PID_FILE}"
    if [ -n "${kpid}" ]; then
      if [ -d "/proc/${kpid}" ]; then
        echo -n "${NAME} (pid ${kpid}) is running..."
        success; echo
      else
        echo -n "PID file exists, but process is not running"
        failure; echo
      fi
    else
      echo -n "PID file exists, but could not read pid"
      failure; echo
    fi
  else
    echo -n "${NAME} is stopped"
    success; echo
  fi
}

function usage() {
  echo "Usage: $0 {start|stop|restart|status}"
}


########################### Executing


case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  restart)
    stop
    start
    ;;
  status)
    status
    ;;
  *)
    usage
    ;;
esac
