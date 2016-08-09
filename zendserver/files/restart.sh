#!/bin/bash

#Takes in a string that will be printed before the error exit
error_exit () {
        echo "$1" 1>&2
        exit 1
}

restartZend () {
  local __inputKeyName=$1
  local __inputKeySecret=$2
  local result="$( /usr/local/zend/bin/zs-manage restart -N $__inputKeyName -K $__inputKeySecret 2>&1 )"
  echo $result
}


if [[ $# == 2 ]]; then
  API_KEY_NAME=$1
  API_KEY_SECRET=$2
  ZEND_RESTART_ATTEMPTS=10

  FAILED_ZEND_RESTART=0
  for (( i=1; i <= $ZEND_RESTART_ATTEMPTS; i++ ))
    do
      RESTART_RESULTS=$( restartZend $API_KEY_NAME $API_KEY_SECRET )
	  if [[ $RESTART_RESULTS == *"OK"* ]]; then
        FAILED_ZEND_RESTART=0
        sleep 5
        break
      else
	    FAILED_ZEND_RESTART=1
	    sleep 5
      fi
    done
  if [[ $FAILED_ZEND_RESTART == 1 ]]; then
	   error_exit "Zend server failed restart failed after $i attempts.
	 Restart Results
	 $RESTART_RESULTS"
  else
       echo "{ \"changed\" : \"true\" , \"comment\" : \"The zend host was successfuly restarted.\" }"   
  fi
else
   error_exit "Missing command line arguments:
        restart.sh [zend_api_key_name] [zend_api_key_secret]"
fi

