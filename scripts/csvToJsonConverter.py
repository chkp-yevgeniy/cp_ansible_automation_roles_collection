#!/usr/bin/python

import sys
import csv
import json

print("Convert csv to json")

print("Argument List:"+str(sys.argv))
csvFile=sys.argv[1]
jsonFile=sys.argv[2]

print("csvFile:"+csvFile)
print("jsonFile:"+jsonFile)

csvfile = open(csvFile, 'r')
jsonfile = open(jsonFile, 'w')

# Write following header into target file
jsonfile.write('---\n')
jsonfile.write('#Vars file\n')
jsonfile.write('#List of Check Point gateways\n')
jsonfile.write('gateways:\n')

#fieldnames = ("mdsHostname","CMA","hostName","ip","sicConnectionState","vsClusterMember","vsNetobj","OSVersionFromGaia","enabledBlades")
fieldnames = ("gw_name", "gw_ipaddr", "gw_mgmt", "gw_domain", "gw_type", "gw_appl_type", "gw_sw_ver", "gw_sw_build", "gw_vs_cl_mem", "gw_vs_netobj", "gw_vsx", "gw_vs", "gw_hosting_vsx_gw", "gw_cl_obj", "gw_conn_state", "gw_tags", "gw_activeBlades")
reader = csv.DictReader(csvfile, fieldnames, delimiter=';')
next(reader)
for row in reader:
    #print("Line:---"+str(row)+"---")
    # if row['sicConnectionState']!="communicating":
    #     continue          
    if row['gw_vs'].strip().lower()=="true":            
        continue  
    #json.dump(row, jsonfile)
    jsonfile.write("- "+str(row))
    jsonfile.write('\n')    

jsonfile.close()

