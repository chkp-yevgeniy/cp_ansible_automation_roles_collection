#!/usr/bin/python

# Script for port scanning and ping
# Multithreaded
#
# (c) 2020 Check Point Software Technologies
#
## VER   DATE            WHO                     WHAT
#------------------------------------------------------------------------------
# v1.1  9.04.2020               Yevgeniy Yeryomin        Initial version
#           

import sys, os
import csv
import subprocess
import socket
import multiprocessing
from joblib import Parallel, delayed

resultsList=[]

def writeToFile(_fileName, _contentList):
  f = open(_fileName, "w")
  for line in _contentList:
      f.write(line+"\n")
  f.close()


def myScan(_t_ip, _t_port):
  result="ok"
  try:
    sock = socket.socket()      
    res = sock.connect((_t_ip, _t_port))        
    sock.close()  
  except:    
    result="failed"

  return result


def myPing(_ip):
  result="ok"
  DEVNULL=open(os.devnull, 'w')
  try:
    subprocess.check_call(['ping', '-c', '2', '-w', '2', str(_ip)], stdout=DEVNULL, stderr=DEVNULL)  
    #subprocess.check_call(['ping', '-c', '2', '-w', '2', str(_ip)])  
  except subprocess.CalledProcessError:
    result="failed"
 
  return result

def performReachChecks(_gw_ip, _gw_name):
  result=""
  https_res=""
  icmp_res=""
  
  icmp_res=myPing(_gw_ip)
  ssh_res=myScan(_gw_ip, 22)
  https_res=myScan(_gw_ip, 443)

  # print("------------")  
  # print("Reachability results for gw:"+ _gw_name)
  # print("icmp_res: "+icmp_res)
  # print("ssh_res: "+ssh_res)
  # print("https_res: "+https_res)
  
  result=icmp_res+";"+ssh_res+";"+https_res

  return result


#def my_function(_i, _myList):  
def main_function(_gwDict):  
  localResultsList=[]  
  gw_ip=_gwDict['gw_ipaddr'].strip()  
  gw_name=_gwDict['gw_name'].strip()  
  reachTestRes=performReachChecks(gw_ip, gw_name)
  resultStr=str(_gwDict['gw_name']).strip()+";"+gw_ip+";"+str(_gwDict['gw_domain']).strip()+";"+reachTestRes
  print("reachTestRes: "+resultStr)
  # Write into result list
  localResultsList.append(resultStr)  

  return localResultsList

def printUserMessageAndStop():
  print("Please provide the gateways list in following way:")
  print("-f <gatewayListFileName>")
  exit()
  
### ### ### ### ### ### ### ### ### ### ###
### MAIN

def main():

  # Process on arguments 
  print(str(len(sys.argv)))        
  if len(sys.argv)<3:
    printUserMessageAndStop()          
  if sys.argv[1]!="-f": 
    printUserMessageAndStop()  
  GWS_INVENTORY_FILE=sys.argv[2]

  ### Variables section 
  #GWS_INVENTORY_FILE="../../conf/gwsListShort.csv"
  #GWS_INVENTORY_FILE="../../vars/gatewaysList_20200331_nonVS.csv"
  
  REPORT_FILE="../../output/reachabilityReport"
  NUMBER_OF_THREADS=10
  ### 
    
  print("Start reachability check here.")
  print("Number of threads will be used:"+str(NUMBER_OF_THREADS))

  curDateTimeYMD_HMS=os.popen('date +%Y%m%d_%H%M%S').read().strip()
  REPORT_FILE=REPORT_FILE+curDateTimeYMD_HMS+".csv"

  # num_cores = multiprocessing.cpu_count()  
  # print("num_cores: "+str(num_cores))

  # Write header
  resultsList.append("#gw_name;gw_ipaddr;gw_domain;icmp_check;ssh_check;https_check")

  #1. Read csv into dict
  fieldnames=("gw_name","gw_ipaddr","gw_mgmt","gw_domain","gw_type","gw_appl_type","gw_sw_ver","gw_sw_build","gw_vs_cl_mem","gw_vs_netobj","gw_vsx","gw_vs","gw_hosting_vsx_gw","gw_cl_obj","gw_conn_state","gw_tags","gw_activeBlades")
  csvreaderDict=[]
  with open(GWS_INVENTORY_FILE, 'r') as csvfile:
    csvreaderDict = csv.DictReader(csvfile, fieldnames, delimiter=';')
    next(csvreaderDict)
    
  # 2. Call reachTestFunction in parallel way
    results = Parallel(n_jobs=NUMBER_OF_THREADS)(delayed(main_function)(i) for i in csvreaderDict)     
    # Results are dict of dict
    
  # 3. Save results into the resultsList    
    for itemFirstLevel in results:
      for itemSecondLevel in itemFirstLevel:
        #print("itemSecondLevel: "+itemSecondLevel)
        resultsList.append(itemSecondLevel)

    # print("Result list")
    # for gwReachCheckRes in resultsList:
    #   print("gwReachCheckRes: "+gwReachCheckRes)

    writeToFile(REPORT_FILE, resultsList)

  print("Reachability test finished successfully")
  print("Report stored in: "+REPORT_FILE)

if __name__ == "__main__":
    main()
