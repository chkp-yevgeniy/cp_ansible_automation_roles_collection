#!/usr/bin/python

# Script for port scanning
#
# (c) 2019 Check Point Software Technologies
#
## VER   DATE            WHO                     WHAT
#------------------------------------------------------------------------------
# v1.1  -               Yevgeniy Yeryomin        Initial version
#           


# A package for reading passwords without displaying them on the console.
from __future__ import print_function

import getpass
import sys, os
import json
import argparse
import csv
import os.path as path
import subprocess
import paramiko
import pickle
import re
import socket






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


def myPing(_ip, _devnull):
  result="ok"
  try:
    subprocess.check_call(['ping', '-c', '2', '-w', '2', str(_ip)], stdout=_devnull, stderr=_devnull)  
  except subprocess.CalledProcessError:
    result="failed"
  
  return result


def performReachChecks(_ip, _devnull):
  result=""

  ssh_res=myScan(_ip, 22)
  print("ssh_res: "+ssh_res)
  
  https_res=myScan(_ip, 443)
  print("https_res: "+https_res)

  icmp_res=myPing(_ip, _devnull)
  print("icmp_res: "+icmp_res)

  result=ssh_res+";"+https_res+";"+icmp_res 

  return result


### ### ### ### ### ### ### ### ### ### ###
### MAIN

def main():

  GWS_INVENTORY_FILE="../../conf/gwsListShort.csv"
  REPORT_FILE="../../output/reachabilityReport"
  resultsList=[]

  curDateTimeYMD_HMS=os.popen('date +%Y%m%d_%H%M%S').read().strip()
  REPORT_FILE=REPORT_FILE+curDateTimeYMD_HMS+".csv"

  devnull=open(os.devnull, 'w')
  
  print("Start reachability check here.")
      
  #1. Read csv
  fieldnames=("gw_name","gw_ipaddr","gw_mgmt","gw_domain","gw_type","gw_appl_type","gw_sw_ver","gw_sw_build","gw_vs_cl_mem","gw_vs_netobj","gw_vsx","gw_vs","gw_hosting_vsx_gw","gw_cl_obj","gw_conn_state","gw_tags","gw_activeBlades")
  with open(GWS_INVENTORY_FILE, 'r') as csvfile:
    csvreader = csv.DictReader(csvfile, fieldnames, delimiter=';')
    next(csvreader)
    for row in csvreader:
      #print(', '.join(row))
      print(str(row))  
      print(str(row['gw_name']))  
      print(str(row['gw_ipaddr']))  
      ip=row['gw_ipaddr'].strip()

      reachTestRes=performReachChecks(ip, devnull)

      resultStr=str(row['gw_name']).strip()+";"+ip+";"+str(row['gw_domain']).strip()+";"+reachTestRes
      print("reachTestRes: "+resultStr)

      resultsList.append(resultStr)


  # 2. Save resutlt into the report file
  writeToFile(REPORT_FILE, resultsList)

  exit()

  

  print("Port Scanning complete")
  
  
  exit()
  
  
  
  
  


if __name__ == "__main__":
    main()
