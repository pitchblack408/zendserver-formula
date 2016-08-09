#!/bin/bash

#Takes in a string that will be printed before the error exit
error_exit () {
        echo "$1" 1>&2
        exit 1
}
bootstrappedZend () {
  local __inputZendAdminPass=$1
  local __inputZendLicenseOrder=$2
  local __inputZendLicenseSerial=$3
  echo "$( /usr/local/zend/bin/zs-manage bootstrap-single-server -p $__inputZendAdminPass -o $__inputZendLicenseOrder -l $__inputZendLicenseSerial -a true -r false 2>&1)"
}
createGrains () {
  local  __api_key=$1
  echo -e "grains:\n  zendserver:\n    mode: production\n    api:\n      enabled: True\n      key: $__api_key" > /etc/salt/minion.d/zendserver.conf  
}
restartZend () {
  local  __inputKey=$1
  local result="$( /usr/local/zend/bin/zs-manage restart -N admin -K $__inputKey 2>&1 )"
  echo $result
}

alreadyBootstrapped () {
  local __inputResults=$1
  local originalIFS=$IFS
  IFS='
'
  local array=( $__inputResults )
  IFS=$originalIFS
  ## get length of an array
  tLen=${#array[@]}
  local statusResult=0
  for (( i=0; i <= $tLen; i++ ))
  do
     if [[ ${array[i]} == *"alreadyBootstrapped"* ]]; then
      statusResult=1
      break
     else
       statusResult=0
     fi
  done
  echo $statusResult
}

completedBootstrap () {
  local __inputResults=$1
  local originalIFS=$IFS
  IFS='
'
  local array=( $__inputResults )
  IFS=$originalIFS
  ## get length of an array
  tLen=${#array[@]}
  local statusResult=0
  for (( i=0; i <= $tLen; i++ ))
  do
     if [[ ${array[i]} == *"You should restart zend server after this operation. Can be done with zs-manage restart action."* ]]; then
      statusResult=1
      break
     else
       statusResult=0
     fi
  done
  echo $statusResult
}

stripApiKey () {
  local __inputStr=$1
  local strresult=-1
  if [[ $__inputStr  =~ admin[[:space:]]([a-z|0-9]+) ]]; then
    strresult=${BASH_REMATCH[1]}
  fi
  echo $strresult
}

getAPIKey () {
  local __inputBootstrapResults=$1
  local originalIFS=$IFS
  IFS='
'
  local array=( $__inputBootstrapResults )
  local apiKey=-1
  IFS=$originalIFS
  # get length of an array
  tLen=${#array[@]}
  if [[ $tLen == 2 ]]; then
    apiKey=$( stripApiKey "${array[0]}" )
  elif [[ $tLen == 3 ]]; then
	apiKey=$( stripApiKey "${array[1]}" )
  else
    apiKey=-1
  fi
  echo $apiKey
}


if [[ $# == 3 ]]; then
ZEND_ADMIN_PASS=$1
ZEND_LICENSE_ORDER=$2
ZEND_LICENSE_SERIAL=$3
ZEND_RESTART_ATTEMPS=10

BOOTSTRAPPED_RESULTS=$( bootstrappedZend $ZEND_ADMIN_PASS $ZEND_LICENSE_ORDER $ZEND_LICENSE_SERIAL )
ALREADY_BOOTSTRAPPED_RESULT=$( alreadyBootstrapped "$BOOTSTRAPPED_RESULTS" )
COMPLETED_BOOTSTRAPPED_RESULT=$( completedBootstrap "$BOOTSTRAPPED_RESULTS" )
FAILED_ZEND_RESTART=0

  if [[ $ALREADY_BOOTSTRAPPED_RESULT == 1 ]]; then
    echo "{ \"changed\" : \"false\" , \"comment\" : \"The host is already boostrapped.\" }"
  elif [[ $COMPLETED_BOOTSTRAPPED_RESULT == 1 ]]; then
    API_KEY=$( getAPIKey "$BOOTSTRAPPED_RESULTS" )
	#echo "$API_KEY"
	if [[ $API_KEY != -1 ]]; then
	  echo -e "grains:\n  zendserver:\n    mode: production\n    api:\n      enabled: True\n      key: $API_KEY" > /etc/salt/minion.d/zendserver.conf
	  for (( i=0; i <= $ZEND_RESTART_ATTEMPS; i++ ))
      do
        RESTART_RESULTS=$( restartZend $API_KEY )
		if [[ $RESTART_RESULTS == *"OK"* ]]; then
          FAILED_ZEND_RESTART=0
          break
        else
		  FAILED_ZEND_RESTART=1
		  sleep 5
       fi
     done
	 if [[ $FAILED_ZEND_RESTART == 1 ]]; then
	   error_exit "Bootstrap succeeded, but zend server failed restart failed after $i attempts.
     Bootstrap Results:
	 $BOOTSTRAPPED_RESULTS
	 
	 Restart Results
	 $RESTART_RESULTS"
	 else
       echo "{ \"changed\" : \"true\" , \"comment\" : \"The host was successfuly bootstrapped.    admin $API_KEY\" }"   
	 fi
    
	else
	  error_exit "Bootstrap succeded, but apiKey was not parsed properly.  Bootstrap results:
     $BOOTSTRAPPED_RESULTS"
	fi
  else
    error_exit "Bootstrap failed for unknown reason.  Bootstrap results:
     $BOOTSTRAPPED_RESULTS"
  fi

else
   error_exit "Missing command line arguments:
        bootstrap-zs.sh [zend_admin_pass] [zend_license_order] [zend_license_serial]"
fi


