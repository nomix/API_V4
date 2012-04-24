#!/bin/ksh
# File          : ora_backup.sh
# Created on    : 2010/08/28
# Purpose       : This script will perform a backup of a specified database.
# Syntax        : ora_backup.sh <sid> <state> <type>
#   <sid>       : SID of the database to backup
#   <state>     : hot|cold
#   <type>      : full|inc
# History       :
#  2009/07/17 (B. Garcia) Initial version from fullrmanbackup.sh by Simon
#   Ouellet.
#  2009/07/20 (B. Garcia) Show environnement settings in the pre-backup stage.
#  2009/07/22 (B. Garcia) Change the verbose log file name.
#  2009/08/12 (B. Garcia) Change the logs file name.
#  2009/08/19 (B. Garcia) Add initlogs, in accordance to modification of api.lib p2l
#  2009/09/01 (B. Garcia) Correct typo in verbose log file name.
#  2009/09/02 (B. Garcia) Replace path to AP2 by full path. Allow users to define their logfiles
#   before launching the script.
#  2009/09/03 (B. Garcia) Define logs file name before sourcing api.lib
#  2010/08/25 (B. Garcia) Update of headers.
#  2011/11/21 (J. Alarcon) Update for compatibility with API v4.
#  2011/11/26 (S. Ouellet) bugs fix.
# Developpers   :
#   Simon Ouellet can be reached at <simon.ouellet@x2p.fr>
#   Benoit Garcia can be reached at <benoit.garcia@x2p.fr>

# Keep the parameters
db_sid="${1}"
bck_state="${2}"
bck_type="${3}"

. /usr/local/bin/initapi ora 
. /usr/local/bin/initapi aix

# Logfiles
export AP2_LOGFILE=${db_sid}_oracle_backup.log
export AP2_VLOGFILE=${db_sid}_verbose_oracle_backup.log

print_api_stdoutd "Log : ${AP2_LOGPATH}/${AP2_LOGFILE}\nVerbose log : ${AP2_LOGPATH}/${AP2_VLOGFILE}"

if [[ -f ${AP2_DBADMINPATH}/scripts/${bck_state}_${bck_type}_backup.rman ]]; then
  export BACKUPSCRIPT=${AP2_DBADMINPATH}/scripts/${bck_state}_${bck_type}_backup.rman
else
  export BACKUPSCRIPT=${APIHOME}/scripts/rman/${bck_state}_${bck_type}_backup.rman
fi

#Call this function to clear your script jobs
cleanressources() {
 print_api_logfile end Aborted ${1}
 exit ${1}
}

trap "cleanressources 1" INT TERM  # execute the cleanressources proc when CTRL-C or TERM signal is trap
init_api_logs                                                                			# initialize the log engine
print_api_logfile start

#
# Step 1 : Check if Oracle user is in use
#
print_api_stdoutd "Step 1 : Checking Oracle user"                    		|tee -a ${AP2_VLOGFILE}
get_aix_curuser oracle                                  		>>${AP2_VLOGFILE}
check_api_result $? "1 : Oracle user check"                 		>>${AP2_VLOGFILE}

#
# Step 2 : Initializing Oracle environment
#
print_api_stdoutd "Step 2 : Initializing Oracle ${db_sid} environment" 	|tee -a ${AP2_VLOGFILE} # set environnement for oracle database
set_ora_env ${db_sid}                              			>>${AP2_VLOGFILE}
check_api_result $? "2 : Oracle environnement initialization"     	>>${AP2_LOGFILE}

#
# Step 3 : Logging pre-backup stats
#
print_api_stdoutd "Step 3 : Logging pre-backup system informations"     	|tee -a ${AP2_VLOGFILE} # Get pre-backup system informations
df -k                                               			>>${AP2_VLOGFILE}      	# FS Usage
env                                                 			>>${AP2_VLOGFILE}	# show environnement settings
check_api_result $? "3 : Pre-backup system informations records"   	>>${AP2_LOGFILE}

#
# Step 4 : Checking available space
#
print_api_stdoutd "Step 4 : Checking available space at least 20%"	|tee -a ${AP2_VLOGFILE}	# Check minimum available space in the BACKUP directory 
chk_aix_availablespace "${BACKUP_PATH}" 20%				>>${AP2_VLOGFILE}
check_api_result $? "4 : Available space check"				>>${AP2_LOGFILE} 

#
# Step 5 : Executing backup script
#
print_api_stdoutd "Step 5 : Executing backup script ${BACKUPSCRIPT}" 	|tee -a ${AP2_VLOGFILE} # Run the backup script
run_ora_rmanscript_with_catalog ${BACKUPSCRIPT}         		>>${AP2_VLOGFILE}
check_api_result $? "5 : Backup script execution"		     	>>${AP2_LOGFILE}

#
# Step 6 : Crosscheck
#
print_api_stdoutd "Step 6 : Performing crosscheck"          		|tee -a ${AP2_VLOGFILE} # Performs a crosscheck
crosscheck_rman                                 			>>${AP2_VLOGFILE}
check_api_result $? "6 : Crosscheck operation"     			>>${AP2_LOGFILE}

#
# Step 7 : Delete Expired
#
print_api_stdoutd "Step 7 : Deletion of EXPIRED backups and archivelogs" |tee -a ${AP2_VLOGFILE} # Deletes the EXPIRED 
delete_rman_expired                                 			>>${AP2_VLOGFILE}
check_api_result $? "7 : Deletion of EXPIRED backups and archivelogs"   >>${AP2_LOGFILE}

#
# Step 8 : Delete Obsolete
#
print_api_stdoutd "Step 8 : Deletion of OBSOLETE backups and archivelogs" |tee -a ${AP2_VLOGFILE} # Deletes the OBSOLETE 
delete_rman_obsolete                                                    >>${AP2_VLOGFILE}
check_api_result $? "8 : Deletion of OBSOLETE backups and archivelogs"  >>${AP2_LOGFILE}

#
# Step 9 : Logging post-backup stats
#
print_api_stdoutd "Step 9 : Logging post-backup system informations"    |tee -a ${AP2_VLOGFILE}	# Get post-backup system informations
df -k                                               			>>${AP2_VLOGFILE}	# FS Usage
check_api_result $? "9 : Post-backup system informations records"  	>>${AP2_LOGFILE}

print_api_stdoutd "Script end.\nLog : ${AP2_LOGPATH}/${AP2_LOGFILE}\nVerbose log : ${AP2_LOGPATH}/${AP2_VLOGFILE}"

print_api_logfile end end 0                                            				# shut the log engine
