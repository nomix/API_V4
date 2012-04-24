#!/bin/ksh
# backup_oradb.sh
# Purpose : Do an incremental rman backup of all oracle databases on server.
# call scripts developped by X2P Oracle DBA
# Version 0.1 15 Nov 2011 By J. Alarcon <julien.alarcon@x2p.fr>:
#  * Initial version
# Version 0.2 26 Nov 2011 By S. Ouellet <simon@x2p.fr>:
#  * Change the printed message and use print_api_stdoutd function instead of "echo"
#  * Handling the return code

. /usr/local/bin/initapi ora

# Paths
export BACKUP_PATH="/data/oracle/backup"
export BCKSID="TEST01"

# DO NOT MODIFY UNDER THIS LINE
clear
if [ `date +%u` == "7" ] ; then
	print_api_stdoutd "Start a full backup\nBackup destination : ${BACKUP_PATH}/${BCKSID}"
	${APIHOME}/bin/ora_backup.sh ${BCKSID} "hot" "full"
	_RC=$?
else
	print_api_stdoutd "Start an incremental backup\nBackup destination : ${BACKUP_PATH}/${BCKSID}"
	${APIHOME}/bin/ora_backup.sh ${BCKSID} "hot" "inc" 
	_RC=$?
fi

if [[ ${_RC} -eq 0 ]];
then
 print_api_stdoutd "Backup ended successfully."
 exit 0
else
 print_api_stdoutd "Backup in error!"
 exit ${_RC}
fi
