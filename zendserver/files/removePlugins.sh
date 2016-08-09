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
#Method gets a list of all plugins installed on zend and then returns the id for the plugin with the name that you  are looking for.
getPluginId () {
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
  for (( i=0; i <= $tLen; i++ ))
  do
    if [[ ${array[i]} == *"[id]"* ]]; then
      id=$( stripPluginId ${array[i]} )
      name=$( stripPluginName ${array[((i+1))]} )
      if [[ $name == $nameLookup ]]; then
        #echo $name
        #echo $id
        break
      else
        id=-1
      fi
    fi
  done
  echo $id
}
#Method takes in the hashkey and the pluginid and removes package from zend
removePlugin () {
 local __inputZSHashKey=$1
 local __inputPluginId=$2
 local OUTPUT="$( /usr/local/zend/bin/zs-client.sh pluginRemove --pluginId=$__inputPluginId --zsurl=http://localhost:10081 --zskey=admin --zssecret=$__inputZSHashKey --output-format=kv)"
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
getRemovePluginStatus () {
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
  zssecret=$1
  pluginName=$2
  pluginListResult=$( getPluginList $zssecret )
  #echo $pluginListResult
  pluginIdLookup=$( getPluginId "$pluginListResult" $pluginName )
  #echo $pluginIdLookup
  if [[ $pluginIdLookup > -1 ]]; then
      #echo $pluginIdLookup
      removedResults=$( removePlugin  $zssecret  $pluginIdLookup )
      removedStatus=$( getRemovePluginStatus "$removedResults" )
      if [[ $removedStatus == "STAGED"  ]]; then
        echo  "{ \"changed\" : \"true\" , \"comment\" : \"The \\\"$pluginName\\\" plugin was removed.\" }"
      else
        error_exit "Plugin removal failed
        $removedResults"
      fi
  else
      echo "{ \"changed\" : \"false\" , \"comment\" : \"Cannot find the plugin with name \\\"$pluginName\\\".\" }"
  fi
else
   error_exit "Missing command line arguments:
        removePlugins.sh [zssecret] [pluginName]"
fi


