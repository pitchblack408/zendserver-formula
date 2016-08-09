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


#Takes in the string such as pluginInfo[id]=10 and will return the id as 10
stripPluginId () {
  local __inputStr=$1
  local strresult=-1
  if [[ $__inputStr  =~ plugins\[[0-9]+\]\[id\]=(.*) ]]; then
    strresult=${BASH_REMATCH[1]}
  fi
  echo $strresult

}
#Takes in the string such as pluginInfo[name]=mongoDB and will return the name as mongoDB
stripPluginName () {
  local __inputStr=$1
  local strresult=-1
  if [[ $__inputStr  =~ plugins\[[0-9]+\]\[name\]=(.*) ]]; then
    strresult=${BASH_REMATCH[1]}
  fi
  echo $strresult

}
#Takes in the string such as pluginInfo[status]=STAGED and will return the status as STAGED
stripPluginStatus () {
  local __inputStr=$1
  local strresult=-1
  if [[ $__inputStr  =~ pluginInfo\[status\]=(.*) ]]; then
    strresult=${BASH_REMATCH[1]}
  fi
  echo $strresult

}
getPluginList () {
  local __inputZSHashKey=$1
  echo "$( /usr/local/zend/bin/zs-client.sh pluginGetList --zsurl=http://localhost:10081 --zskey=admin --zssecret=$__inputZSHashKey --output-format=kv)"
}
#Checks if the plugin exists
pluginExists () {
  local __inputPluginListString=$1
  local __inputPluginName=$2
  local originalIFS=$IFS
  IFS='
'
  local array=( $__inputPluginListString )

  IFS=$originalIFS
  # get length of an array
  tLen=${#array[@]}
  #nameLookup="mongoDB"
  local nameLookup=$__inputPluginName
  local found=0
  for (( i=0; i <= $tLen; i++ ))
  do
    if [[ ${array[i]} == *"[id]"* ]]; then
      name=$( stripPluginName ${array[((i+1))]} )
      if [[ $name == $nameLookup ]]; then
        found=1
        #echo $name
        break
      else
        id=0
      fi
    fi
  done
  echo $found
}
#Method takes in the hashkey, plugin name and adds package to zend
addPlugin () {
 local __inputZSHashKey=$1
 local __inputPluginName=$2

local OUTPUT="$( /usr/local/zend/bin/zs-client.sh pluginDeploy --pluginPackage=/etc/zendserver/plugins/$__inputPluginName.zip --zsurl=http://localhost:10081 --zskey=admin --zssecret=$__inputZSHashKey  --output-format=kv )"
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
getAddPluginStatus () {
  local __inputResults=$1
  local originalIFS=$IFS
  #echo  $__inputResults 
  IFS='
'
  local array=( $__inputResults )
  IFS=$originalIFS
  ## get length of an array
  tLen=${#array[@]}
  local statusResult=-1
  for (( i=0; i <= $tLen; i++ ))
  do
     if [[ ${array[i]} == *"[status]"* ]]; then
      statusResult=$( stripPluginStatus ${array[i]} )
      break
     else
       statusResult=-1
     fi 
  done
  echo $statusResult
}


#MAIN STARTS HERE###################################################################################################
if [[ $# == 2 ]]; then
  #zssecret="9075360a8e6204f6872366890c84b47119b1913ddb477f80bc5ce734619287ad"
  #pluginName="mongoDB"
  ZS_SECRET=$1
  PLUGIN_NAME=$2
  PLUGIN_LIST_RESULTS=$( getPluginList $ZS_SECRET )
  PLUGIN_FOUND=$( pluginExists "$PLUGIN_LIST_RESULTS" $PLUGIN_NAME )

  if [[ $PLUGIN_FOUND == 0 ]]; then

      ADD_PLUGIN_RESULTS=$( addPlugin $ZS_SECRET $PLUGIN_NAME )
      ADD_PLUGIN_STATUS=$( getAddPluginStatus "$ADD_PLUGIN_RESULTS" )
      if [[ $ADD_PLUGIN_STATUS == "WAITING_FOR_DEPLOY"  ]]; then
        echo  "{ \"changed\" : \"true\" , \"comment\" : \"The \\\"$PLUGIN_NAME\\\" plugin was added.\" }"
      else
        error_exit "Plugin failed to be added
        $ADD_PLUGIN_RESULTS"
      fi
  else
      echo "{ \"changed\" : \"false\" , \"comment\" : \"Plugin with that name \\\"$PLUGIN_NAME\\\" exists.\" }"
  fi

else
   error_exit "Missing command line arguments:
        deployPlugins.sh [zssecret] [pluginName]"
fi


