#!/bin/ksh
# File          : ora_monitoring.sh
# Created on    : 2009/07/22
# Purpose       : This script will check oracle services .
# Syntax        : ora_monitoring.sh <sid>
#   <sid>       : SID of the database to monitor
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
  export AP2_LOGFILE=${1}_monitoring.log
fi
if ! [ $AP2_VLOGFILE ]; then
  export AP2_VLOGFILE=${1}_verbose_monitoring.log
fi

#Call this function to clear your script jobs
cleanressources() {
 p2l end Aborted ${1}
 exit ${1}
}

trap "cleanressources 1" INT TERM  # execute the cleanressources proc when CTRL-C or TERM signal is trap

#initlogs                                                                        # initialize the log engine
export AP2_LOGFILE=${AP2_LOGPATH}/${AP2_LOGFILE}
export AP2_VLOGFILE=${AP2_LOGPATH}/${AP2_VLOGFILE}

p2l start

p2sd "Init Oracle env for ${1}"                                                >>${AP2_VLOGFILE}         # set environnement for oracle database
setoraenv ${1}                                                                 >>${AP2_VLOGFILE}
checkresult $? "Init Oracle environnement"                                     | tee -a ${AP2_LOGFILE}

p2sd "Oracle: Checking listener status"                                        | tee -a ${AP2_LOGFILE}   # Checking listener status
${ORACLE_HOME}/bin/lsnrctl status                                              >>${AP2_VLOGFILE}
if [[ $? -ne 0 ]]; then
	p2sd "Oracle: Warning! Listener down. Will try to start it."                 | tee -a ${AP2_LOGFILE}
  ${ORACLE_HOME}/bin/lsnrctl start                                             >>${AP2_VLOGFILE}
    if [[ $? -ne 0 ]]; then
        p2sd "Oracle: Error! Couldn't start listener. Switching node."         | tee -a ${AP2_LOGFILE}
        return 1
    else
        p2sd "Oracle: Warning! Listener started. Check log."                   | tee -a ${AP2_LOGFILE}
    fi
else
    p2sd "Oracle: Ok! Listener already started."                               | tee -a ${AP2_LOGFILE}
fi

p2sd "Oracle: Checking database ${ORACLE_SID} status"                          | tee -a ${AP2_LOGFILE}   # Checking instance status

# Check if a specific db_query.sql script exists for this DB.
if [[ -f ${AP2_DBADMINPATH}/scripts/query_db.sql ]]; then
  export QUERY_DB_SCRIPT=${AP2_DBADMINPATH}/scripts/query_db.sql
else
  export QUERY_DB_SCRIPT=${AP2}/scripts/query_db.sql
fi

# Check if a specific start_db.sql script exists for this DB.
if [[ -f ${AP2_DBADMINPATH}/scripts/start_db.sql ]]; then
  export START_DB_SCRIPT=${AP2_DBADMINPATH}/scripts/start_db.sql
else
  export START_DB_SCRIPT=${AP2}/scripts/start_db.sql
fi


DB_Known=`$ORACLE_HOME/bin/lsnrctl status | grep $ORACLE_SID | wc -l`          >>${AP2_VLOGFILE}
if [[ ${DB_Known} -lt 1 ]]; then
    p2sd "Oracle: Warning! Listener doesn't know about ${ORACLE_SID}. Will try to reload"          | tee -a ${AP2_LOGFILE}
    ${ORACLE_HOME}/bin/lsnrctl reload                                          >>${AP2_VLOGFILE}
    if [[ $? -ne 0 ]]; then
        p2sd "Oracle: Error! Impossble to reload listener configuration. Switching node."          | tee -a ${AP2_LOGFILE}
        return 2
    else
        p2sd "Oracle: Warning! listener configuration reloaded. Please check logs."                | tee -a ${AP2_LOGFILE}
    fi
else
    p2sd "Oracle: Ok! Listener knows ${ORACLE_SID}."                           | tee -a ${AP2_LOGFILE}
fi

${ORACLE_HOME}/bin/sqlplus /nolog @${QUERY_DB_SCRIPT}                          >>${AP2_VLOGFILE}
if [[ $? -ne 0 ]]; then
    p2sd "Oracle: Warning! Unable to query ${ORACLE_SID}. Switching node."     | tee -a ${AP2_LOGFILE}
#    ${ORACLE_HOME}/bin/sqlplus /nolog @${START_DB_SCRIPT}                      >>${AP2_VLOGFILE}
#    if [[ $? -ne 0 ]]; then
#        p2sd "Oracle: Error! Unable to start ${ORACLE_SID}. Switching node."   | tee -a ${AP2_LOGFILE}
        return 3
#    else
#        p2sd "Oracle: Warning! ${ORACLE_SID} started. Please check logs."      | tee -a ${AP2_LOGFILE}
#    fi
else
    p2sd "Oracle: Ok! ${ORACLE_SID} is available."                             | tee -a ${AP2_LOGFILE}
fi

p2l end end 0                                                                  # shut the log engine