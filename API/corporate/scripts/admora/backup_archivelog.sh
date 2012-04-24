#!/bin/ksh
# backup_archivelog.sh
# Purpose : Do an incremental rman backup of archivelogs of oracle databases on server.
# call scripts developped by X2P Oracle DBA
# Version 0.1 15 Nov 2011 By J. Alarcon <julien.alarcon@x2p.fr>:
#  * Initial version
# Version 0.2 26 Nov 2011 By S. Ouellet <simon@x2p.fr>:
#  * API integration

## SETUP
BCKSID="TEST01"
# Paths
export ARCHIVELOG_PATH="/data/oracle/${BCKSID}/arch"
export BACKUP_PATH="/data/oracle/backup/${BCKSID}"

# DO NOT MODIFY OVER THIS LINE
clear

. /usr/local/bin/initapi ora

print_api_stdoutd "starting ${0}"

${APIHOME}/bin/archivelog_backup.sh ${BCKSID}

if [[ $? -eq 0 ]];
then
 print_api_stdoutd "Backup ended successfully."
else
 print_api_stdoutd "Backup in error!"
fi
