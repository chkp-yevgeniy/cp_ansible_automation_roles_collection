#!/bin/bash
source /etc/profile.d/CP.sh
# Iventory Script to collect gateways data from MDS via cmpiquerybin.
# Script performs following:
#   - Collection of gateways info per CMA
#   - Collected data put into csv 
#   
#  Following data are collected:
# name 
# ip
# mgmtServerName
# domainName
# type
# appliance_type
# svn_version_name
# svn_build_num	
# vs_cluster_member
# #      vs_netobj\
# vsx
# vs
# hosting_vsx_gateway
# cluster_object
# connection_state
# comments
# sic_name)


# (c) 2020 Check Point Software Technologies
#
# VER   DATE            WHO                     WHAT
#------------------------------------------------------------------------------
# v.0.1    11.2019  Yevgeniy Yeryomin      Inital steps
# v.0.2 09.01.2020  Yevgeniy Yeryomin      Report format added
# v.0.3 24.01.2020  Yevgeniy Yeryomin      Associative array deleted, since it is supported only from shell v.4. OLd MGMT might have shell v. 3
# v.0.4 21.02.2020  Yevgeniy Yeryomin      SMS and MDM data collection via API implemented
# v.0.5 04.03.2020  Yevgeniy Yeryomin      Performance improved. 3 API calls combined to 1

# !!! Note
# 1. The activated blades are collected only via API

# 2. Data collection on MDM via cpmiQueryBin is much faster than via API (tested in large customer environment).


# !!! ToDo
# export MGMT_CLI_PORT=$(grep httpd:ssl_port /config/active|cut -f 2 -d" ")

# Combine 3 mgmt_cli calls to just one
#./gwInventoryFromMGMTGenerator.sh invOutput/ inventory_logs.txt inventory_ordered_2.csv





# Here is the script with arguments
# How to run the script:
# ./gwInventoryFromMGMTGenerator.sh <logs file> <report folder> <inventory report file> <inventory ordered report file>
# E.g.:
#./gwInventoryFromMGMTGenerator.sh invOutput/ inventory_logs.txt inventory_ordered.csv



# Setting terminal
export TERM=xterm

#curTime=`date +%F`
# Unixtime
curTime=`date +%s`
#echo "unix time: $curTime"

curDate=`date +%Y%m%d_%H%M%S`

# Get the data above from arguments
if [ -z $1 ] || [ -z $2 ] || [ -z $3 ]; then
        echo "Provide OutputFolder, LogFile, InventoryReportFile as arguments"
        exit 0
fi

PEPGatewaysListFile="PEPGatewaysListFile.csv"
#PDPsConnectPEPsReportFile="PDPsConnectPEPsReportFile.csv"

conPDPtoPEPsOutput="conPDPtoPEPsOutput.txt"

#PDPsAccessCoreReportFile="PDPsAccessCoreReportFile.csv"

OutputFolder=$1
LogFile=$2
InventoryOrderedReportFile=$3
#InventoryReportFile=$4
#PDPsAccessCoreReportFile=$5
#LicensesReportFile=$6
#Verbosity=$4


TMP_FOLDER=$OutputFolder"tmp"
mkdir -p $TMP_FOLDER

#useCPMIQueryBin="false"
useCPMIQueryBin="true"

GATEWAYS_DATA_CPMI_TMP=$TMP_FOLDER"/all_gateways_data_from_cpmi.csv"
CMA_GATEWAYS_DATA_CPMI_TMP=$TMP_FOLDER"/cma_gateways_data_from_cpmi.csv"
CLUSTER_MEMBERS_CPMI=$TMP_FOLDER"/cluster_members_from_cpmi.csv"
VS_GWs_FROM_VS_SLOTS_CPMI=$TMP_FOLDER"/vs_gws_from_vs_slots_cpmi.csv"
CLUSTER_OBJ_DETAILS_CPMI=$TMP_FOLDER"/cluster_obj_details_cpmi.csv"

# For SMS actions via API
GATEWAYS_DATA_API_TMP=$TMP_FOLDER"/all_gateways_data_from_api.csv"
CLUSTER_OBJ_DETAILS_API=$TMP_FOLDER"/cluster_obj_details_api.csv"
GATEWAYS_ACTIVE_BLADES_API=$TMP_FOLDER"/all_gateways_active_blades_api.csv"

# OutputFolder="/var/log/data/Inventory/inventory_reports_$curTime"
# LogFile="$OutputFolder/inventory_logs.txt"
# InventoryReportFile="$OutputFolder/summary-inventory.csv"


LogFile="$OutputFolder$LogFile"
InventoryOrderedReportFile="$OutputFolder$InventoryOrderedReportFile"
#InventoryReportFile="$OutputFolder$InventoryReportFile"
#PDPsConnectPEPsReportFile="$OutputFolder$PDPsConnectPEPsReportFile"
#PDPsAccessCoreReportFile="$OutputFolder$PDPsAccessCoreReportFile"
#LicensesReportFile="$OutputFolder$LicensesReportFile"        

#PEPGatewaysListFile="$OutputFolder$PEPGatewaysListFile"
#conPDPtoPEPsOutput="$OutputFolder$conPDPtoPEPsOutput"


Domain_Names_File="$OutputFolder/domains_names.txt"
Domain_Names_Existing_File="$OutputFolder/domains_names_existing.txt"
CMA_Names_File="$OutputFolder/cma_names.txt"

vsxHostingPDPsFile="vars/vsx-list_hosting_pdps.txt"

mkdir -p $OutputFolder

logger(){
        #local curTimeH=`date +%F_%T`        
        local curTimeH=`date +%F_%T | sed 's/-//g'`                
        local logEntry=$1
        #Verbosity="-v"
        if [ "$Verbosity" == "-v" ];then
                echo $curTimeH $mdsHostname $logEntry
        fi
        echo $curTimeH $mdsHostname $logEntry >> $LogFile
}


writeReport() {
        reportStr=""
        logger "Create log line below:"
               
        # reportOrderedStr="$gw_name \
        #         ;$gw_ipaddr \
        #         ;$gw_mgmt \
        #         ;$gw_domain \
        #         ;$gw_type \
        #         ;$gw_appl_type \
        #         ;$gw_sw_ver \
        #         ;$gw_sw_build \
        #         ;$gw_vs_cl_mem\
        #         ;$gw_vs_netobj \
        #         ;$gw_vsx \
        #         ;$gw_vs \
        #         ;$gw_hosting_vsx_gw \
        #         ;$gw_cl_obj \
        #         ;$gw_conn_state \
        #         ;$gw_tags"

		reportOrderedStr=""

	for attrName in "${gwAttrList[@]}";do
                #logger "attrName --$attrName--"            		
                #logger "value --$value--"            		            
                #echo "reportOrderedStr --$reportOrderedStr--"            
	        value=$(eval "echo \${$attrName}")			
	        reportOrderedStr=$reportOrderedStr$value" ;"	                      		
        done

        logger "reportOrderedStr: $reportOrderedStr"        
	logger "String for report: --- $reportOrderedStr ---"        
	#echo $reportOrderedStr >> $InventoryOrderedReportFile
        printf "$strFormatForReport" $(echo "$reportOrderedStr") >> $InventoryOrderedReportFile

}




writeSummaryReportHeader() {
        # Prepare summary report header        
        summaryReportHeader="#"
        for attrName in "${gwAttrCPMIList[@]}";do
                summaryReportHeader=$summaryReportHeader$attrName";"
        done
        
        logger "summaryReportHeader: "$summaryReportHeader
        echo $summaryReportHeader >> $InventoryReportFile
}


printVarsFromGatewaysList(){
        logger "--- --- Gateway: $gw_name"

        for attrName in "${gwAttrList[@]}";do			
			value=$(eval "echo \${$attrName}")
			logger "$attrName: ---$value---"             
        done
        
}


cleanupVarsFromGatewaysList(){
        
        for K in "${!GWMAP[@]}"; do 
                if [ "$K" == "mdsHostname" ] || [ "$K" == "domainName" ]; then
                        continue
                fi
                GWMAP[$K]=""
        done
}
  

getAttrCsvStrForCpmi(){
        i=0        
        attrCsvStrForCpmi=""
        for attr in "${gwAttrCPMIList[@]}"; do
                # We get cluster_object from dbedit, so skip it here
                if [ "$attr" == "cluster_object" ] || [ "$attr" == "hosting_vsx_gateway" ]; then 
                        continue
                fi        
                i=$(( $i + 1 ))                
                if [ $i -lt 3 ]; then
                        continue
                fi
                attrCsvStrForCpmi=$attrCsvStrForCpmi$attr","                
        done

        # replace "name" with "__name__" , required for cpmiquerybin
        attrCsvStrForCpmi=$(echo $attrCsvStrForCpmi | sed 's/name,/__name__,/' | sed 's/,$//')
        
}


getDataFromClusterObj(){
        local clusterObjLine=""
        # appliance_type; svn_version_name; svn_build_num
        clusterObjLine=$(cat $CLUSTER_OBJ_DETAILS_CPMI | grep ^$gw_cl_obj)       
        #echo "clusterObjLine: "$clusterObjLine
        if [ ! -z "$clusterObjLine" ]; then
                gw_appl_type=$(echo $clusterObjLine | awk -F___ '{print $3}')
                gw_sw_ver=$(echo $clusterObjLine | awk -F___ '{print $4}')
                gw_sw_build=$(echo $clusterObjLine | awk -F___ '{print $5}')
        fi
}

getDataFromClusterObj_forAPIMode(){
        local clusterObjLine=""
		#echo "gw_name: $gw_name"		
        # appliance_type; svn_version_name; svn_build_num
        #clusterObjLine=$(cat $CLUSTER_OBJ_DETAILS_API | grep "$gw_name,\|$gw_name$" | head -n 1)       
		clusterObjLine=$(cat $GATEWAYS_DATA_API_TMP | grep ";$gw_name,\|,$gw_name;" | head -n 1)       		
        #echo "clusterObjLine: "$clusterObjLine
        if [ ! -z "$clusterObjLine" ]; then
                gw_cl_obj=$(echo $clusterObjLine | awk -F\; '{print $1}')
				gw_sw_ver=$(echo $clusterObjLine | awk -F\; '{print $5}')
				gw_appl_type=$(echo $clusterObjLine | awk -F\; '{print $4}')
        fi

}

getVsClusterMembers_forAPIMode(){
        local vsClusterMembers=""
        # appliance_type; svn_version_name; svn_build_num
        #vsClusterMembers=$(cat $CLUSTER_OBJ_DETAILS_API | grep "^$gw_name;.*$" | head -n 1 | awk -F\; '{ print $5 }')       
		vsClusterMembers=$(cat $GATEWAYS_DATA_API_TMP | grep "^$gw_name;.*$" | head -n 1 | awk -F\; '{ print $9 }')       
        logger "vsClusterMembers: "$vsClusterMembers
		
		# echo "gw_name: $gw_name"		
		# echo "vsClusterMembers: "$vsClusterMembers
		
		vsClMemArr=""

		oldIFS=$IFS		
		IFS=',' read -r -a vsClMemArr <<< "$vsClusterMembers"
		IFS=$oldIFS
		#echo "IFS=$IFS"
}




preprocessingForEachCMA(){

        cmaCount=$[ $cmaCount +1 ]
        # if [ $cmaCount -eq 10 ]; then
        #          break
        # fi

        logger ""
        logger "--- --- ---"        
        logger "Domain: $mydomain"   
        logger "CMA count: $cmaCount"                    
        
        # Switch to the relevant CMA context       
        mdsenv $mydomain        
        gw_domain=$mydomain
        
        # Check if CMA is active
        # Leave the CMA if standby        
        # if [[ $(cpprod_util FwIsActiveManagement) -eq 0 ]]; then
        #         logger "CMA status: standby"         
        #         continue
        # else    
        #         logger "CMA status: active"
        # fi

}


exportGatewaysFromDomianViaCPMI() {

        CPMIExportSucceeded="true"

        local searchRslt=""
        # Export data from CPMI into a tempfile 
        #echo "attrCsvStrForCpmi: $attrCsvStrForCpmi"       
        # cpmiquerybin attr "" network_objects "firewall='installed'&type='gateway'|type='cluster_member'" -a $attrCsvStrForCpmi |\
        #         awk -F\\t '{print $1";"$2";"$3";"$4";"$5";"$6";"$7";"$8";"$9}' | sed 's/MISSING_ATTR//g' | sed "s/^/$mydomain;/g" > $CMA_GATEWAYS_DATA_CPMI_TMP
        
        cpmiquerybin attr "" network_objects "firewall='installed'&type='gateway'|type='cluster_member'" -a $attrCsvStrForCpmi |\
                awk -F\\t '{print $1";"$2";"$3";"$4";"$5";"$6";"$7";"$8";"$9";"$10";"$11";"$12";"$13}' |\
                awk -F\; '{ if ($10!="") print $0 }' | sed 's/MISSING_ATTR//g' |\
                sed "s/^/$mydomain;/g" > $CMA_GATEWAYS_DATA_CPMI_TMP

        #cpmiquerybin attr "" network_objects "firewall='installed'&type='gateway'|type='cluster_member'" -a __name__,type,connection_state,vs_cluster_member,vs_netobj,ipaddr,appliance_type,svn_version_name,svn_build_num |\
        #        awk -F\\t '{print $1";"$2";"$3";"$4";"$5";"$6";"$7";"$8";"$9}' | sed 's/MISSING_ATTR//g' | sed "s/^/$mydomain;/g"

        cat $CMA_GATEWAYS_DATA_CPMI_TMP >> $LogFile

        # Check if export was successfull
        #echo "cat $CMA_GATEWAYS_DATA_CPMI_TMP | grep \"^$mydomain;Error:.*\""
        searchRslt=$(cat $CMA_GATEWAYS_DATA_CPMI_TMP | grep "^$mydomain;Error:.*")
        logger "searchRslt: ---$searchRslt---"
        
        # If export successfull, write to .csv file        
        if [ -z "$searchRslt" ]; then  
                cat $CMA_GATEWAYS_DATA_CPMI_TMP >> $GATEWAYS_DATA_CPMI_TMP
                logger "Gateways data exported successully"
                
        else 
                logger "Gateways data export failed"
                CPMIExportSucceeded="false"
        fi

        rm $CMA_GATEWAYS_DATA_CPMI_TMP 2>/dev/null
}

checkIfVSX(){
        local searchRst=""
        searchRst=$(cat $VS_GWs_FROM_VS_SLOTS_CPMI | grep "^$gw_name[[:space:]]" | awk '{ if ($1==$2) print $1,$2}')
        if [ -z "$searchRst" ];then
                gw_vsx="false"
        else 
                gw_vsx="true"
        fi

}

checkIfVS(){
	local searchRst=""
        searchRst=$(cat $VS_GWs_FROM_VS_SLOTS_CPMI | grep "^$gw_name[[:space:]]" | awk '{ if ($1!=$2) print $1,$2}')
        if [ -z "$searchRst" ];then
                gw_vs="false"
        else 
                gw_vs="true"
        fi

}

# # Chek if we are on MDM or on SMS
getMgmtType(){
	#mdsenvOut=$(mdsstat 2>/dev/null)
	#echo "mdsenvOut: $mdsenvOut"
	#if [ -z "$mdsenvOut" ]; then
	if [ -z "${MDS_SYSTEM}" ]; then
		mgmtType="SMS"	
	else
		mgmtType="MDM"	
	fi
}


fillGwAttrListForCPMI(){
        # Define here the list of parameters after "domainName" for MDS or SMS database table "network_objects" 
        gwAttrCPMIList=(mdsHostname\
                domainName\
                name\
                type\
                connection_state\
                vs_cluster_member\
                vs_netobj\
                ipaddr\
                appliance_type\
                svn_version_name\
                svn_build_num\
                sic_name\
                # attributes don't exist in the database
                # we will derive them by analysing a set of attributes
                vsx\
                vs\
                hosting_vsx_gateway\
                cluster_object\
                comments)
       
                # ToDo: read gateways' comments and use them as tags

        logger "gwAttributesCPMI:"; 
        # for attr in "${gwAttrCPMIList[@]}"; do
        #         logger "gwAttr for CPMI query: --$attr--"; 
        # done
        #__name__,type,connection_state,vs_cluster_member,vs_netobj,ipaddr,appliance_type,snv_version_name,svn_bild_num
}


# Gw attributes: we will use them for report header

fillGwAttrList(){
 	gwAttrList=(gw_name\
	gw_ipaddr\
        gw_mgmt\
        gw_domain\
        gw_type\
        gw_appl_type\
        gw_sw_ver\
        gw_sw_build\
        gw_vs_cl_mem\
	gw_vs_netobj\
        gw_vsx\
        gw_vs\
        gw_hosting_vsx_gw\
        gw_cl_obj\
        gw_conn_state\
	gw_tags\
	gw_activeBlades)

		# logger "gwAttributes:"; 
        # for attr in "${gwAttrList[@]}"; do
        #         logger "gwAttr: --$attr--"; 
        # done

}

writeOrderedInvReportHeaderOld_Depricated(){
    # The header has to correlate with the data order in writeReport
    #17

	orderedInvHeader="#gw_name\
	    ;gw_ipaddr\
            ;gw_mgmt\
            ;gw_domain\
            ;gw_type\
            ;gw_appl_type\
            ;gw_sw_ver\
            ;gw_sw_build\
            ;gw_vs_cl_mem\
	    ;gw_vs_netobj\
            ;gw_vsx\
            ;gw_vs\
            ;gw_hosting_vsx_gw\
            ;gw_cl_obj\
            ;gw_conn_state\
	    ;gw_tags\
	    ;gw_activeBlades"
    logger "orderedInvHeader: ---"$orderedInvHeader"---"
    #echo $orderedInvHeader >> $InventoryOrderedReportFile
    #printf "$strFormatForReport" $orderedInvHeader
    printf "$strFormatForReport" $orderedInvHeader >> $InventoryOrderedReportFile
}

writeOrderedInvReportHeader(){
	orderedInvHeader="#"
	logger "gwAttributes:"; 
    for attr in "${gwAttrList[@]}"; do
        orderedInvHeader=$orderedInvHeader$attr" ;"
		#logger "gwAttr: --$attr--"; 
    done
	logger "strFormatForReport: ---"$strFormatForReport"---"
	logger "orderedInvHeaderrr: ---"$orderedInvHeader"---"
	#echo "strFormatForReport: ---"$strFormatForReport"---"
	#echo "orderedInvHeaderrr: ---"$orderedInvHeader"---"
	#printf "$strFormatForReport" $orderedInvHeader >> $InventoryOrderedReportFile
	printf "$strFormatForReport" $(echo "$orderedInvHeader") >> $InventoryOrderedReportFile
	#printf "$strFormatForReport" $(echo "$orderedInvHeader")	
}

getGwVarsFromGwCsvLine(){        
        logger "Gateway cmpiquerybin string: "$gwCsvLine
        gw_domain=$(echo "$gwCsvLine" | awk -F\; {'print $1'})		
        gw_name=$(echo "$gwCsvLine" | awk -F\; {'print $2'})		
        gw_type=$(echo "$gwCsvLine" | awk -F\; {'print $3'})
        gw_conn_state=$(echo "$gwCsvLine" | awk -F\; {'print $4'})        
        gw_vs_cl_mem=$(echo "$gwCsvLine" | awk -F\; {'print $5'})
        gw_vs_netobj=$(echo "$gwCsvLine" | awk -F\; {'print $6'})
        gw_ipaddr=$(echo "$gwCsvLine" | awk -F\; {'print $7'})
        gw_appl_type=$(echo "$gwCsvLine" | awk -F\; {'print $8'})
        gw_sw_ver=$(echo "$gwCsvLine" | awk -F\; {'print $9'})
        gw_sw_build=$(echo "$gwCsvLine" | awk -F\; {'print $10'})
        #gw_tags=$(echo "$gwCsvLine" | awk -F\; {'print $14'})            
        gw_tags=$(echo "$gwCsvLine" | awk -F\; {'print $14'} | sed 's/[[:space:]]/_/g' )            
        #tr -dc '[:alnum:][:space:]' |

        if [ ! "$gw_vs_cl_mem" == "true" ]; then 
                gw_vs_cl_mem="false"
        fi
        
        if [ "$gw_vs_netobj" != "true" ]; then 
                gw_vs_netobj="false"
        fi
}


### For MDM
# Get cluster and vs objects	
getGwDataFromAllCMAs(){

	logger "Iterate over all CMAs to get objects cluster and vs objects"
	cmaCount=0
	while read -r mydomain;
	do
        # Set test flags, Check if CMA is active
        #preprocessingForEachCMA

        cmaCount=$[ $cmaCount +1 ]
        # if [ $cmaCount -eq 10 ]; then
        #          break
        # fi

        logger ""
        logger "--- --- ---"        
        logger "Domain: $mydomain"   
        logger "CMA count: $cmaCount"                    
        
        # Switch to the relevant CMA context       
        mdsenv $mydomain        
        gw_domain=$mydomain

        # Get gateway list via cpmi
        exportGatewaysFromDomianViaCPMI

        
        if [ "$CPMIExportSucceeded" == "true" ]; then

            # Geta data we will use in the postprocessing steps

            # Get all cluster_member objects via cpmi                                
            cpmiquerybin attr "" network_objects "type='cluster_member'" -a __name__,cluster_object  | sed 's/Name://g' | \
                sed 's/(Table:.*$//g' >> $CLUSTER_MEMBERS_CPMI

            # Get cluster object details via cpmi
            # cpmiquerybin attr "" network_objects "vsx_cluster_netobj='true'|vs_cluster_netobj='true'|type='gateway_cluster'"\
            #     -a __name__,",",ipaddr,appliance_type,svn_version_name,svn_build_num |\
            #     sed 's/\t/___/g' | sed 's/\s/-/g' | sed 's/___/ /g' >> $CLUSTER_OBJ_DETAILS_CPMI
            cpmiquerybin attr "" network_objects "vsx_cluster_netobj='true'|vs_cluster_netobj='true'|type='gateway_cluster'"\
                -a __name__,",",ipaddr,appliance_type,svn_version_name,svn_build_num |\
                sed 's/\t/___/g' | sed 's/\s/-/g' >> $CLUSTER_OBJ_DETAILS_CPMI

            # Get all vs objects via cpmi
            cpmiquerybin attr "" vs_slot_objects "type='vs_slot_base'|type='vs_slot_obj'" -a __name__,vsx_gateway,comments | sed 's/Name://g' |\
                sed 's/(Table:.*)//g' >> $VS_GWs_FROM_VS_SLOTS_CPMI                
            # Get info including vsid
            # cpmiquerybin attr "" vs_slot_objects "type='vs_slot_base'|type='vs_slot_obj'" -a __name__,vsx_gateway,comments,vsid

        fi
          
	done < $Domain_Names_File
}

### For MDM
# Generate gw reports accross all CMAs
generateGwReportAcrossAllCMAs(){

	logger "Iterate over all CMAs to get all gateway objects"
	gwCount=0
	while read -r gwCsvLine;
	do
                gwCount=$[ $gwCount +1 ]
                # !!! Just for tests
                # if [ $gwCount -eq 3 ];then
                #         break
                # fi

                # echo "gwCsvLine: $gwCsvLine"
                # Put csv line into list
                getGwVarsFromGwCsvLine


                # Skip vswitches and vrouters by name (ToDo: implement determination of types: gw, vswitch, vrouter)
                if [[ "$gw_name" =~ .*_VSW.* ]] || \
                [[ "$gw_name" =~ .*_vsw.* ]] || \
                [[ "$gw_name" =~ .*_vswitch.* ]] || \
                [[ "$gw_name" =~ .*_router.* ]]; then 
                continue
                fi
                
                # Just print the gateway's attributes
                printVarsFromGatewaysList

                # Get cluster obj
                gw_cl_obj=""
                if [ "$gw_type" == "cluster_member" ];then
                #echo "cat $CLUSTER_MEMBERS_CPMI | grep ^$gw_name[[:space:]] | awk '{print \$2}'"
                gw_cl_obj=$(cat $CLUSTER_MEMBERS_CPMI | grep ^$gw_name[[:space:]] | awk '{print $2}' | head -n 1)                        
                fi        

                # Check if it is about vsx
                checkIfVSX

                # Check if it is about vsx
                checkIfVS

                # # Get vsx obj
                # Do it only for VS!
                gw_hosting_vsx_gw=""
                if [ "$gw_vs" == "true" ] ;then  
                #if [ "$gw_vs_cl_mem" == "true" ] || [ "$gw_vs_netobj" == "true" ];then
                #    if [ "$gw_sw_ver" != "R76" ] && [ "$gw_sw_ver" != "R80.20SP" ]; then   
                        #echo "cat $VS_GWs_FROM_VS_SLOTS_CPMI | grep ^$gw_name[[:space:]] | awk '{print \$2}'"
                        vsx_gateway=$(cat $VS_GWs_FROM_VS_SLOTS_CPMI | grep ^$gw_name[[:space:]] | awk '{print $2}')
                        if [ "$gw_name" != "$vsx_gateway" ]; then
                                gw_hosting_vsx_gw=$vsx_gateway
                                # Get vsx_gateway IP
                                #echo "cat $GATEWAYS_DATA_CPMI_TMP | grep ";$vsx_gateway;" | awk -F\; '{ print \$7}'"
                                gw_ipaddr=$(cat $GATEWAYS_DATA_CPMI_TMP | grep ";$vsx_gateway;" | awk -F\; '{ print $7}')
                                #logger "GWMAP ip $gw_ipaddr"    
                        fi
                #    fi
                #fi
                fi

                # Get appliance type, sw version, build version for cluster_members
                if [ "$gw_type" == "cluster_member" ]; then
                getDataFromClusterObj
                fi

                        
                # # Check if it is about vsx
                # checkIfVSX

                # # Check if it is about vsx
                # checkIfVS

                
                # Get comment for VS       
                if [ "$gw_vs" == "true" ]; then
                #echo "vs with cluster obj found" 
                gw_tags=$(cat $VS_GWs_FROM_VS_SLOTS_CPMI | grep ^$gw_cl_obj[[:space:]] | awk '{print $3}')        
                logger "gw_tags for VS: "$gw_tags
                fi
                
                printVarsFromGatewaysList

                writeReport

	done < $GATEWAYS_DATA_CPMI_TMP


}


getGwDataViaAPI(){
	logger ""


	# 1. Get all needed data via API
	logger "Export all gateways via API"
	#mgmt_cli -r true show gateways-and-servers limit 500 details-level "full" --format json | jq -r '.objects[] | select (.type | contains("simple-gateway") or contains("CpmiClusterMember") or contains("CpmiVsxClusterMember") or contains("CpmiVsClusterNetobj")) | [.name, ."ipv4-address", ."type", ."hardware", ."version", ."sic-status", ."comments"] | join (";")' > $GATEWAYS_DATA_API_TMP
	
	cmd="mgmt_cli -r true show gateways-and-servers limit 500 details-level \"full\" --format json \
		| jq -r '.objects[] | \
		select (.type | \
		contains(\"simple-gateway\") or contains(\"CpmiClusterMember\") or contains(\"CpmiVsxClusterMember\") or contains(\"CpmiVsClusterNetobj\") \
		or contains(\"CpmiGatewayCluster\") or contains(\"CpmiVsxClusterNetobj\")) | \
		[.name, .\"ipv4-address\", .\"type\", .\"hardware\", .\"version\", .\"sic-status\", \
		.\"comments\", \
		(.\"domain\" | join(\",\")), \
		(.\"cluster-member-names\" | join(\",\")), \
		(.\"network-security-blades\" |  keys[] as \$k | \"\(\$k), \(.[\$k])\") ]\
		| join (\";\")' \
		2>/dev/null > $GATEWAYS_DATA_API_TMP"
		
	eval $cmd
		
	# # 2. Get cluster objects
	# logger "Export all clusters via API"
	# mgmt_cli -r true show gateways-and-servers limit 500 details-level "full" --format json|jq -r '.objects[] | select (.type | contains("CpmiGatewayCluster") or contains("CpmiVsxClusterNetobj") or contains("CpmiVsClusterNetobj")) | [.name, ."ipv4-address", ."version", ."hardware", (."cluster-member-names" | join(","))] | join (";")' 2>/dev/null > $CLUSTER_OBJ_DETAILS_API

	# # 3. Get activated blades 
	# logger "Export for all gateways activated blades info via API"
	# mgmt_cli -r true show gateways-and-servers limit 500 details-level "full" --format json|jq -r '.objects[] | select (.type | contains("simple-gateway") or contains("CpmiGatewayCluster") or contains("CpmiVsClusterNetobj") or contains("CpmiVsxClusterNetobj")) | [.name, ."ipv4-address", (."network-security-blades" | keys[] as $k | "\($k), \(.[$k])")] | join(";")' 2>/dev/null > $GATEWAYS_ACTIVE_BLADES_API
	
	
	# 3. Get gateway vars
	while read -r gwCsvLine;
	do
		gw_cl_obj=""

		logger "gwCsvLine: $gwCsvLine"		
        gw_name=$(echo "$gwCsvLine" | awk -F\; {'print $1'})		
        gw_ipaddr=$(echo "$gwCsvLine" | awk -F\; {'print $2'})
		gw_type=$(echo "$gwCsvLine" | awk -F\; {'print $3'})
		gw_appl_type=$(echo "$gwCsvLine" | awk -F\; {'print $4'})
		gw_sw_ver=$(echo "$gwCsvLine" | awk -F\; {'print $5'})		
		gw_conn_state=$(echo "$gwCsvLine" | awk -F\; {'print $6'})        		
		gw_tags=$(echo "$gwCsvLine" | awk -F\; {'print $7'})    
		gw_domain=$(echo "$gwCsvLine" | awk -F\; {'print $8'} | awk -F\, {'print $2'})       

		if [ "$gw_type" == "CpmiGatewayCluster" ] || [ "$gw_type" == "CpmiVsxClusterNetobj" ]; then
			continue
		fi 

		# Check if vsx		
		if [ "$gw_type" == "CpmiVsxClusterMember" ]; then
			gw_vsx="TRUE"
		else 
			gw_vsx="FALSE"
		fi

		# Check if vs
		if [ "$gw_type" == "CpmiVsClusterNetobj" ]; then
			gw_vs="TRUE"
		else 
			gw_vs="FALSE"
		fi
		
		# If cluster member, find the cluster object
		if [ "$gw_type" == "CpmiClusterMember" ] || [ "$gw_type" == "CpmiVsxClusterMember" ] ; then
			gw_vs_cl_mem="TRUE"
		else 
			gw_vs_cl_mem="FALSE"
		fi

		#Get data for cluster members
		if [ "$gw_vs_cl_mem" == "TRUE" ]; then
			getDataFromClusterObj_forAPIMode
			# gw_cl_obj
			#gw_appl_type=$(echo $clusterObjLine | awk '{print $3}')
            #gw_sw_ver=$(echo $clusterObjLine | awk '{print $4}')
		fi

		# Get the gateways activated blades
		gw_activeBlades=""
		#getActivatedBladesAPI
		if [ "$gw_type" == "simple-gateway" ] || [ "$gw_type" == "CpmiVsClusterNetobj" ];  then
			#gw_activeBlades=$(cat $GATEWAYS_DATA_API_TMP | grep -e "^$gw_name;" | sed 's/^[^.*;]*;//' | sed 's/^[^*;]*;//' | sed 's/true//g' | sed 's/,//g' | sed 's/[[:space:]]//g' | sed 's/;/,/g')	
			gw_activeBlades=$(cat $GATEWAYS_DATA_API_TMP | grep -e "^$gw_name;" | awk -F\; '{print $10 $11 $12 $13 $14 $15 $16 $17}')
			gw_activeBlades=$(echo $gw_activeBlades | sed 's/true//g' | sed 's/[[:space:]]//g')
			#echo "gw_activeBlades=$gw_activeBlades---"
			#exit 0
		else 
			#gw_activeBlades=$(cat $GATEWAYS_DATA_API_TMP | grep -e "^$gw_cl_obj;" | sed 's/^[^.*;]*;//' | sed 's/^[^*;]*;//' | sed 's/true//g' | sed 's/,//g' | sed 's/[[:space:]]//g' | sed 's/;/,/g')	
			gw_activeBlades=$(cat $GATEWAYS_DATA_API_TMP | grep -e "^$gw_cl_obj;" | awk -F\; '{print $10 $11 $12 $13 $14 $15 $16 $17}')			
		fi
		gw_activeBlades=$(echo $gw_activeBlades | sed 's/true//g' | sed 's/[[:space:]]//g')

		# Process on vs gateways
		if [ "$gw_type" == "CpmiVsClusterNetobj" ]; then
			# Get the cluster members 			
			getVsClusterMembers_forAPIMode
			gw_cl_obj=$gw_name
			for element in "${vsClMemArr[@]}"; do
				#echo "arr element: $element"				
				gw_name=$element
				writeReport
			done
		else
			writeReport		
		fi
		
		logger " ---- "       
                logger "gw_name="$gw_name"---"
		logger "gw_ipaddr="$gw_ipaddr"---"
		logger "gw_type="$gw_type"---"
		logger "gw_appl_type="$gw_appl_type"---"
		logger "gw_sw_ver="$gw_sw_ver"---"
		logger "gw_conn_state="$gw_conn_state"---"
		logger "gw_tags="$gw_tags"---"
		logger "gw_vsx="$gw_vsx"---"
		logger "gw_vs="$gw_vs"---"
		logger "gw_cl_obj=$gw_cl_obj---"
		logger "gw_activeBlades=$gw_activeBlades---"


	done < $GATEWAYS_DATA_API_TMP



}

removeAllTempFiles(){
        # Remove all temp files
        rm $GATEWAYS_DATA_CPMI_TMP 2>/dev/null
        rm $CMA_GATEWAYS_DATA_CPMI_TMP 2>/dev/null
        rm $CLUSTER_MEMBERS_CPMI 2>/dev/null
        rm $VS_GWs_FROM_VS_SLOTS_CPMI 2>/dev/null
        rm $CLUSTER_OBJ_DETAILS_CPMI 2>/dev/null
}



# MAIN

logger "--------- Inventory tool start ---------"
echo "--------- Inventory tool start ---------"
logger "All logs and reports have been written in $OutputFolder"
echo "Log and report files will be written in $OutputFolder"

curTimeH=`date +%F_%T`
logger "Log file and reports will be written in folder $OutputFolder"
logger "LogFile: $LogFile"
logger "InventoryReportFile: $InventoryReportFile"

# Export Check Point environment variables
# needed for mdsenv command
if [ -r /opt/CPshared/5.0/tmp/.CPprofile.sh ]; then
    . /opt/CPshared/5.0/tmp/.CPprofile.sh
else
    logger "Cannot set CP environment!"
    exit 1
fi

# Unfortunately, we should not use associative arrays sinse they are supported only from bash v.4
#declare -A GWMAP

gw_mgmt=$(hostname)
declare -a gwAttrList
declare -a gwAttrCPMIList

# Put all gw attributes in a list
fillGwAttrList

# Put all gw attributes for CPMI query in a list (for database table "network_objects")
fillGwAttrListForCPMI

# Get attributes csv string for cpmiquerybin
getAttrCsvStrForCpmi
logger "attrCsvStrForCpmi: $attrCsvStrForCpmi"  

getMgmtType
logger "mgmtType: $mgmtType"

# Write header
rm $InventoryOrderedReportFile 2>/dev/null
summaryReportHeader=""
#writeSummaryReportHeader
#strFormatForReport="%-24s %-16s %-15s %-14s %-15s %-7s %-10s %-6s %-6s %-6s %-6s %-6s %-12s %-15s %-15s %-15s\n"
strFormatForReport="%-24s %-16s %-15s %-14s %-15s %-7s %-10s %-6s %-6s %-6s %-6s %-6s %-12s %-15s %-15s %-15s %-15s %-15s\n"
#strFormatForReport="%-24s %-16s %-15s %-14s %-15s %-7s %-10s %-6s %-6s %-6s %-6s %-6s %-12s %-15s %-15s %-15s %s %s\n"
writeOrderedInvReportHeader


# Loop through domains. Get the list of vs from all domains.
logger "Collect vs data via cpmi from vs_slot_base"

# !!!
removeAllTempFiles


### For MDM via CPMIqueryBin
# The MDM part is implemented based on cpmiquerybin (cause this is much!!! more faster than API in large customer environments)
logger "we are on a $mgmtType"
if [ "$mgmtType" == "MDM" ] && [ "$useCPMIQueryBin" == "true" ];then
	# Get the CMAs list
	echo "We are going to use cpmiQueryBin to collect the data"
	$MDSVERUTIL AllCMAs > $Domain_Names_File
	#cat $Domain_Names_File
	total_cmas_number=$(cat $Domain_Names_File | wc -l)
	#logger "Total Domains: $(tput setaf 1)$total_cmas_number$(tput sgr0)"
	logger "Total Domains: $total_cmas_number"

	getGwDataFromAllCMAs

	generateGwReportAcrossAllCMAs

else
### For MDM and SMS via API
	echo "We are going to use MGMT API to collect the data"

	getGwDataViaAPI
	
fi

# Cleanup all used variables
# -----------------
unset mdsHostname
cleanupVarsFromGatewaysList
removeAllTempFiles

logger "Inventory data successfully collected."
logger "All logs and reports have been written in $OutputFolder"
echo "Inventory data successfully collected."


