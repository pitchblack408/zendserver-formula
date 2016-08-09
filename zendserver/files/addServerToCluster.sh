#!/bin/bash

#set -x



#Takes in a string that will be printed before the error exit
error_exit () {
        echo "$1" 1>&2
        exit 1
}
#This will take in a string and replace all characters with the replacement as defined in the input regex
escapeSingleQuotes () {
  local __inputString=$1
  echo $__inputString | sed -r "s/'/\\\'/g"
}

escapeDoubleQuotes () {
  local __inputString=$1
  echo $__inputString | sed -r "s/\"/\\\"/g"
}

#Takes in the string such as NODE_ID = 1 and will return 1
stripNodeId () {
  local __inputStr=$1
  local strresult=-1
  if [[ $__inputStr  =~ NODE_ID\[[:space:]\]=\[[:space:]\](.*) ]]; then
    strresult=${BASH_REMATCH[1]}
  fi
  echo $strresult

}
#Takes in the string such as WEB_API_KEY = admin and will return admin
stripWebApiKey () {
  local __inputStr=$1
  local strresult=-1
  if [[ $__inputStr  =~ WEB_API_KEY\[[:space:]\]=\[[:space:]\](.*) ]]; then
    strresult=${BASH_REMATCH[1]}
  fi
  echo $strresult

}
#Takes in the string such as WEB_API_KEY_HASH = 159c9a16ba907d80d1a7d338526e13e09495d5b8da17e0557026a2afc04949b1 and will return 159c9a16ba907d80d1a7d338526e13e09495d5b8da17e0557026a2afc04949b1 
stripWebApiKeyHash () {
  local __inputStr=$1
  local strresult=-1
  if [[ $__inputStr  =~ WEB_API_KEY_HASH\[[:space:]\]=\[[:space:]\](.*) ]]; then
    strresult=${BASH_REMATCH[1]}
  fi
  echo $strresult

}


#Waiting on support to identify if there is a CLI method to get me this information
#getCluserLust () {
#  local __inputZSHashKey=$1
#  echo "$( /usr/local/zend/bin/zs-client.sh pluginGetList --zsurl=http://localhost:10081 --zskey=admin --zssecret=$__inputZSHashKey --output-format=kv)"
#}

#Method that adds server the zend cluster
addServer () {
  local __inputZSServername=$1
  local __inputZSServerip=$2
  local __inputClusterdbhostip=$3
  local __inputClusterdbusername=$4
  local __inputClusterdbpassword=$5
  local __inputClusterschemaname=$6
  local __inputZSname=$7
  local __inputZSsecret=$8
  local OUTPUT="$( /usr/local/zend/bin/zs-manage server-add-to-cluster --name=$__inputZSServername --nodeIP=$__inputZSServerip --dbHost=$__inputClusterdbhostip --dbUsername=$__inputClusterdbusername --dbPassword=$__inputClusterdbpassword --dbName=$__inputClusterschemaname --key-name=$__inputZSname --secret-key=$__inputZSsecret )"
  IFS='
'
 local array=( $OUTPUT )

 IFS=$originalIFS

 # get length of an array
 tLen=${#array[@]}
 for (( i=0; i <= $tLen; i++ ))
 do
   echo ${array[i]}
 done

}
#Method will take the results add determine if the results return the NODE_ID, WEB_API_KEY, and WEB_API_KEY_HASH fields in the results
isAddServerSuccess () {
  local __inputResults=$1
  local originalIFS=$IFS
  #echo  $__inputResults
  IFS='
'
  local array=( $__inputResults )
  IFS=$originalIFS
  ## get length of an array
  tLen=${#array[@]}
  local finalResult=0
  local result1=0
  local result2=0
  local result3=0
  if [[ $tLen -ge 3  ]]; then
     if [[ ${array[0]} == "NODE_ID = "* ]]; then
       result1=1
     else
       result1=0
     fi
     if [[ ${array[1]} == "WEB_API_KEY = "* ]]; then
       result2=1
     else
       result2=0
     fi
     if [[ ${array[2]} == "WEB_API_KEY_HASH = "* ]]; then
       result3=1
     else
       result3=0
     fi
     finalResult=$(($result1&$result2&$result3))
  else
    finalResult=0
  fi
  echo $finalResult
}




#MAIN STARTS HERE###################################################################################################
if [[ $# == 8 ]]; then
  zsservername=$1
  zsserverip=$2
  clusterdbhostip=$3
  clusterdbusername=$4
  clusterdbpassword=$5
  clusterschemaname=$6
  zsname=$7
  zssecret=$8

  addServerResults=$( addServer  $zsservername $zsserverip $clusterdbhostip $clusterdbusername $clusterdbpassword $clusterschemaname $zsname $zssecret )
  addServerSuccess=$( isAddServerSuccess "$addServerResults" )
  if [[ $addServerSuccess == 1  ]]; then
        echo  "{ \"changed\" : \"true\" , \"comment\" : \"The server was added or exists in the cluster\" }"
  else
        error_exit "Adding the server to the cluser failed
        $addServerResults"
  fi
else
   error_exit "Missing command line arguments:
        addServerToCluster.sh [zsservername][zsserverip][clusterdbhostip][clusterdbusername][clusterdbpassword][clusterschemaname][zsname][zssecret]"
fi


