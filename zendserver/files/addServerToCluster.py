#!/usr/bin/env python

import argparse
import MySQLdb
import re
import subprocess

__author__ = "Michael A Martin"
__version__ = "1.0"
__email__ = "mikemartin221@gmail.com"




class MySqlConectionException(Exception):
    def __init__(self, message):
        self.message = message

class AddZendClusterNodeException(Exception):
    def __init__(self, message):
        self.message = message




def addServer( zsservername, zsserverip, clusterdbhostip, clusterdbusername, clusterdbpassword, clusterschemaname, zskey, zssecret ):
    arg= "/usr/local/zend/bin/zs-manage server-add-to-cluster --name="+zsservername+" --nodeIP="+zsserverip+" --dbHost="+clusterdbhostip+" --dbUsername="+clusterdbusername+" --dbPassword="+clusterdbpassword+" --dbName="+clusterschemaname+" --key-name="+zskey+" --secret-key="+zssecret
    #output = subprocess.check_output(['ls'])
    output = subprocess.check_output(arg, shell=True)
    results=re.split('\n', output)
    return results
def isAddServerSuccess(addServerResults):
    result=False
    if len(addServerResults)== 4:
        if ("NODE_ID" in addServerResults[0]) and ("WEB_API_KEY" in addServerResults[1]) and ("WEB_API_KEY_HASH" in addServerResults[2]):
            result=True
    return result

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('zsservername', metavar='zsservername', help='the name of zendsever that will be the main node')
    parser.add_argument('zsserverip', metavar='zsserverip', help='the ip of zendsever that will be the main node')
    parser.add_argument('clusterdbhostip', metavar='clusterdbhostip', help='the database ip that holds the zend cluster blueprint')
    parser.add_argument('clusterdbusername', metavar='clusterdbusername', help='mysql user')
    parser.add_argument('clusterdbpassword', metavar='clusterdbpassword', help='mysql user password')
    parser.add_argument('clusterschemaname', metavar='clusterschemaname', help='zend cluster blueprint schema name')
    parser.add_argument('zskey', metavar='zskey', help='zend server key value')
    parser.add_argument('zssecret', metavar='zssecret', help='zend secret value')	

    args = parser.parse_args()

    badSchema=re.search("[^0-9,^a-z,^A-Z^$^_]", args.clusterschemaname)
    if badSchema:
        raise AddZendClusterNodeException("The database has an invalid name, the name needs to be of [0-9,a-z,A-Z$_] ASCII")
    
    result=False
    try:
        db = MySQLdb.connect(host=args.clusterdbhostip,user=args.clusterdbusername,passwd=args.clusterdbpassword,db="mysql",use_unicode=True, charset='utf8')
        cursor = db.cursor()
        cursor.execute("SELECT VERSION()")
        results = cursor.fetchone()
        # Check if anything at all is returned
        if results:
            result=True
        else:
            result=False
    except MySQLdb.Error:
        raise

    if result == False:
            raise MySqlConectionException('MySql Server connection failed.')
    else:
        try:
            addServerResults=addServer(args.zsservername, args.zsserverip, args.clusterdbhostip, args.clusterdbusername, args.clusterdbpassword, args.clusterschemaname, args.zskey, args.zssecret )
        except subprocess.CalledProcessError:
            raise
        #for addServerResult in addServerResults:
        #    print addServerResult
        if isAddServerSuccess( addServerResults ):
            print  "{ \"changed\" : \"true\" , \"comment\" : \"The server was added or exists in the cluster\" }"
        else:
            raise AddZendClusterNodeException("Adding the server to the cluser failed\n"+''.join(addServerResults))
	
	
if __name__ == "__main__":
    main()
