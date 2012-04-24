#!/bin/ksh
# File          : archivelog_backup.sh
# Created on    : 2011/11/21
# Purpose       : This script will perform a backup of archivelog of a specified database if the free space is inferior to 25%.
# Syntax        : archivelog_backup.sh <sid>
#   <sid>       : SID of the database to backup
# History       :
#  2011/11/21 (J. Alarcon) Initial version.

db_sid=${1}

. ${AP2}/bin/initapi ora 
. ${AP2}/bin/initapi aix
. ${AP2}/bin/initapi api

export AP2_LOGFILE=${db_sid}_archivelog_backup.log
export AP2_VLOGFILE=${db_sid}_verbose_archivelog_backup.log

print_api_stdoutd "Log : ${AP2_LOGPATH}/${AP2_LOGFILE}\nVerbose Log : ${AP2_LOGPATH}/${AP2_VLOGFILE}"

if [[ -f ${AP2_DBADMINPATH}/scripts/archivelog_backup.rman ]]; then
  export BACKUPSCRIPT=${AP2_DBADMINPATH}/scripts/archivelog_backup.rman
else
  export BACKUPSCRIPT=${APIHOME}/scripts/rman/archivelog_backup.rman
fi

#Call this function to clear your script jobs
cleanressources() {
 print_api_logfile end Aborted ${1}
 exit 1
}

trap "cleanressources 1" INT TERM  # execute the cleanressources proc when CTRL-C or TERM signal is trap

init_api_logs                                                                	# initialize the log engine
print_api_logfile start

#
# Step 1 : Check if Oracle user is in use
#
print_api_stdoutd "Step 1 : Checking Oracle user"			|tee -a ${AP2_VLOGFILE}
get_aix_curuser oracle							>>${AP2_VLOGFILE}
check_api_result $? "1 : Oracle user check" 				>>${AP2_VLOGFILE}

#
# Step 2 : Check if available space in the archivelog directory is inferior to xx%
#
print_api_stdoutd "Step 2 : Checking minimum available space in ${ARCHIVELOG_PATH}" |tee -a ${AP2_VLOGFILE}
chk_aix_availablespace "${ARCHIVELOG_PATH}" 25%  			>>${AP2_VLOGFILE}
check_api_result $? "2 : Available space check"             		>>${AP2_LOGFILE}

#
# Step 3 : Initializin Oracle environment
#
print_api_stdoutd "Step 3 : Initializing Oracle ${db_sid} environment"	|tee -a ${AP2_VLOGFILE}		# set environnement for oracle database
set_ora_env ${db_sid}                          				>>${AP2_VLOGFILE}
check_api_result $? "3 : Oracle environment initialization"      	>>${AP2_LOGFILE}

#
# Step 4 : Logging pre-backup stats 
#
print_api_stdoutd "Step 4 : Logging pre-backup system informations"    	|tee -a ${AP2_VLOGFILE}     	# Get pre-backup system informations
df -k                                               			>>${AP2_VLOGFILE}   		# FS Usage
env                                                 			>>${AP2_VLOGFILE}       	# show environnement settings
check_api_result $? "4 : Pre-backup system informations records"   	>>${AP2_LOGFILE}

#
# Step 5 : Check minimum available space
#
print_api_stdoutd "Step 5 : Checking minimum available space"		|tee -a ${AP2_VLOGFILE}		# Check available space in the BACKUP
chk_aix_availablespace "${BACKUP_PATH}" 20%				>>${AP2_VLOGFILE}
check_api_result $? "5 : Available space check"				>>${AP2_LOGFILE} 

#
# Step 6 : Executing backup
#
print_api_stdoutd "Step 6 : Executing backup script ${BACKUPSCRIPT}"   	|tee -a ${AP2_VLOGFILE}         # Run the backup script
run_ora_rmanscript_with_catalog ${BACKUPSCRIPT}    			>>${AP2_VLOGFILE}
check_api_result $? "6 : Backup script execution"     			>>${AP2_LOGFILE}

#
# Step 7 : Logging post-backup stats
#
print_api_stdoutd "Step 7 : Logging post-backup system informations"    |tee -a ${AP2_VLOGFILE}     	# Get post-backup system informations
df -k                                               			>>${AP2_VLOGFILE}           	# FS Usage
check_api_result $? "7 : Post-backup system informations records"  	>>${AP2_LOGFILE}

print_api_stdoutd "Log : ${AP2_LOGFILE}\nVerbose Log : ${AP2_VLOGFILE}"

print_api_logfile end end 0                                            			             	# shut the log engine
