#!/bin/ksh
# File          : ora_start.sh
# Created on    : 2009/07/22
# Purpose       : This script will start oracle services. Listener is supposed
#   to be already running.
# Syntax        : ora_start.sh <sid>
#   <sid>       : SID of the database to stop
# History       :
#  2009/07/12 (B. Garcia) Initial version.
#  2009/07/13 (B. Garcia) remove su command.
#  2009/08/19 (B. Garcia) Tee the "standart" log to logfile + STDOUT for HACMP logs. Remove initlogs
#   Added the modification of $AP2_LOGFILE & $AP2_VLOGFILE.
#  2009/09/02 (B. Garcia) Use argument for SID for simplifying reuse of the script. Allow users
#   to define their logfiles before launching the script.
# Developpers   :
#   Benoit Garcia can be reached at <benoit.garcia@x2p.fr>

export AP2=/home/oracle/AP2

. ${AP2}/lib/api.lib
. ${AP2}/lib/oracle.lib

if ! [ $AP2_LOGFILE ]; then
  export AP2_LOGFILE=${1}_starting.log
fi
if ! [ $AP2_VLOGFILE ]; then
  export AP2_VLOGFILE=${1}_verbose_starting.log
fi

#Call this function to clear your script jobs
cleanressources() {
 p2l end Aborted ${1}
 exit ${1}
}

trap "cleanressources 1" INT TERM  # execute the cleanressources proc when CTRL-C or TERM signal is trap

initlogs                                                                        # initialize the log engine
p2l start

p2sd "Init Oracle env for ${1}"                                                >>${AP2_VLOGFILE}         # set environnement for oracle database
setoraenv ${1}                                                                 >>${AP2_VLOGFILE}
checkresult $? "Init Oracle environnement"                                     | tee -a ${AP2_LOGFILE}

p2sd "Oracle: Starting database ${ORACLE_SID}"                                 | tee -a ${AP2_LOGFILE}

# Check if a specific start_db.sql script exists for this DB.
if [[ -f ${AP2_DBADMINPATH}/scripts/start_db.sql ]]; then
  export START_DB_SCRIPT=${AP2_DBADMINPATH}/scripts/start_db.sql
else
  export START_DB_SCRIPT=${AP2}/scripts/start_db.sql
fi

${ORACLE_HOME}/bin/sqlplus /nolog @${START_DB_SCRIPT}                          >>${AP2_VLOGFILE}
if [[ $? -ne 0 ]]; then
    p2sd "Oracle: Error! Couldn't start database ${ORACLE_SID}."               | tee -a ${AP2_LOGFILE}
    return 2
else
    p2sd "Oracle: Ok! Database ${ORACLE_SID} started."                         | tee -a ${AP2_LOGFILE}
fi

p2l end end 0                                                                  # shut the log engine