#!/bin/ksh
# genwastab.ksh
# Generate automaticaly the wastab file
# Version 3.1r12

#################
#Step 0 : Preset
#################
. /usr/bin/initapi was
# Variables initialisation
CELLNAME=none
NODENAME=none
OBJNAME=none
PROFILENAME=none
PROFILEPATH=none

# Functions
buildnprint() {
 if [[ -n ${1} ]]
 then
  echo "#${1}"
 fi
 echo "${CELLNAME}:${NODENAME}:${OBJNAME}:Y:${PROFILENAME}:${PROFILEPATH}"
}

#################
#Step config : Dynamic configuration
#################
WEBSPHEREVERSION=`$AS_PATH/bin/versionInfo.sh | grep Version | egrep -v "VersionInfo|Directory" | awk '{ print $2 }' | head -1 | cut -b -3`

#################
#Step 1 : Check a DMGR profile is declared locally on this node, and if it's the case, build and print the wastab entry
#################
if [[ ${WEBSPHEREVERSION} = "6.0" ]]
then
 if [[ `cat $AS_PATH/properties/profileRegistry.xml | egrep "profileTemplates\/dmgr\"\/\>" | wc -l` -ne 0 ]];
 then
  echo DMGR found
  PROFILEPATH=`cat $AS_PATH/properties/profileRegistry.xml | egrep "profileTemplates\/dmgr\"\/\>" | awk '{ print $4 }'|awk -F"=" '{ print $2 }' | tr -d "\""`
  PROFILENAME=`cat $AS_PATH/properties/profileRegistry.xml | egrep "profileTemplates\/dmgr\"\/\>" | awk '{ print $3 }'|awk -F"=" '{ print $2 }' | tr -d "\""`
  NODENAME=`grep WAS_NODE ${PROFILEPATH}/bin/setupCmdLine.sh | awk -F"=" '{ print $2 }'`
  CELLNAME=`grep WAS_CELL ${PROFILEPATH}/bin/setupCmdLine.sh | awk -F"=" '{ print $2 }'`
  OBJNAME="dmgr"
  buildnprint "# DMGR ENTRY"
 fi
fi
if [[ ${WEBSPHEREVERSION} = "6.1" ]]
then
 if [[ `cat $AS_PATH/properties/profileRegistry.xml | egrep "profileTemplates\/dmgr\"\/\>" | wc -l` -ne 0 ]];
 then
  echo DMGR found
  PROFILEPATH=`cat $AS_PATH/properties/profileRegistry.xml | egrep "profileTemplates\/dmgr\"\/\>" | awk '{ print $5 }'|awk -F"=" '{ print $2 }' | tr -d "\""`
  PROFILENAME=`cat $AS_PATH/properties/profileRegistry.xml | egrep "profileTemplates\/dmgr\"\/\>" | awk '{ print $4 }'|awk -F"=" '{ print $2 }' | tr -d "\""`
  NODENAME=`grep WAS_NODE ${PROFILEPATH}/bin/setupCmdLine.sh | awk -F"=" '{ print $2 }'`
  CELLNAME=`grep WAS_CELL ${PROFILEPATH}/bin/setupCmdLine.sh | awk -F"=" '{ print $2 }'`
  OBJNAME="dmgr"
  buildnprint "# DMGR ENTRY"
 fi
fi

#################
#Step 2 : For every profile declared as managed type in the profileRegistry.xml file build and print the wastab entry 
#################
while read -r profileentry
do
 if [[ `echo $profileentry | egrep "profileTemplates\/managed\"\/\>" | wc -l` -eq 1 ]] # if the entry is a managed one
 then

 if [[ ${WEBSPHEREVERSION} = "6.0" ]]
 then
  export PROFILENAME=`echo ${profileentry} | awk '{ print $3 }'|awk -F"=" '{ print $2 }' | tr -d "\""`
  export PROFILEPATH=`echo ${profileentry} | awk '{ print $4 }'|awk -F"=" '{ print $2 }' | tr -d "\""`
 fi
 if [[ ${WEBSPHEREVERSION} = "6.1" ]]
 then
  export PROFILENAME=`echo ${profileentry} | awk '{ print $4 }'|awk -F"=" '{ print $2 }' | tr -d "\""`
  export PROFILEPATH=`echo ${profileentry} | awk '{ print $5 }'|awk -F"=" '{ print $2 }' | tr -d "\""`
 fi

  if [[ `echo ${PROFILENAME} ${PROFILEPATH} | grep -i dmgr | wc -l` -ne 0 ]];
  then # It's a backup dmgr profile

#################
##Step 2.a : Backup DMGR profile
#################
   NODENAME=`grep WAS_NODE ${PROFILEPATH}/bin/setupCmdLine.sh | awk -F"=" '{ print $2 }'`
   CELLNAME=`grep WAS_CELL ${PROFILEPATH}/bin/setupCmdLine.sh | awk -F"=" '{ print $2 }'`
   OBJNAME="nodeagent"
   buildnprint "# BACKUP DMGR ENTRY"
  else # It's a standard profile

#################
##Step 2.b : Standard profile
#################
   NODENAME=`grep WAS_NODE ${PROFILEPATH}/bin/setupCmdLine.sh | awk -F"=" '{ print $2 }'`
   CELLNAME=`grep WAS_CELL ${PROFILEPATH}/bin/setupCmdLine.sh | awk -F"=" '{ print $2 }'`
   OBJNAME="nodeagent"
   buildnprint "# NODE AGENT ${NODENAME}"
   for server in `find ${PROFILEPATH}/config/cells/${CELLNAME}/nodes/${NODENAME}/servers/ -type d | egrep -v "nodeagent|servers\/$"`
   do # 
    _splitconfig=`echo $server | sed 's/\(.*\)config\(.*\)/\2/g'`
    OBJNAME=`echo $_splitconfig | awk -F"/" '{ print $7 }'`
    buildnprint
   done
  fi # BckDMGR/Standard profile check
 fi # Managed entry only
done < $AS_PATH/properties/profileRegistry.xml # End profileentry
