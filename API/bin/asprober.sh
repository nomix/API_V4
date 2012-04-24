#!/bin/ksh
# asprober.sh : Application Server Supperviser
# Version 1.0 20 november 2007 by S. OUELLET : initial version
# Version 1.1 14 february 2008 by S. OUELLET : bug fix (HTTPRC=302,no args,better help,IHS path)
# Version 1.2 26 february 2008 by S. OUELLET : bug fix (bad logic fixed)
. ~/APIX2P/conf/waslib.conf
. ${STOP}/lib/webadmlib-02.fnc
. ${STOP}/lib/comlib.fnc

#@@@@@@@@@@@@@@@@ Configuration Section @@@@@@@@@@@@@@@@@@@@@@@@@#
CLNAME="CL01"			# Cluster name
FDLY=1				# Delay before retrying when a probe fail 
HCCONTEXT="/hc"			# Health check context plus the called health check page name
IHSPROCESSNAME="httpd"		# IHS process name (in the case of multiple IHS instances)
IPTARGET="127.0.0.1"		# IP on which AS must respond
KILLIHS="Y"			# Allow the script to kill IHS
NFBK=3				# Number of failed before kill
PORTLIST="12006 12026 12046"	# Port list on wich the probe will be done (ports separated by a space)
QUORUM=0			# Threshold of AS alive number before kill
TBASF=2				# Time before AS is considered as failed
TBCF=10				# Time before cluster fails
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

#@@@ Functions Section @@@#
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
#@ trap cleaner functions section @#
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
#_wgetreq <clusterprobeID> <asprobeId> <port>
_wgetreq() {
 #set -x
 mkfifo ${STOP}/tmp/wgetreq.${1}.${2}.${3}
 ${STOP}/bin/wget -O/dev/null --cache=off --connect-timeout=${TBASF} http://${IPTARGET}:${3}${HCCONTEXT} >> ${STOP}/tmp/wgetreq.${1}.${2}.${3} 2>&1 &
}

# _asprobe <clusterprobeID> <port>
# return 0=OK(serverishealty),1=NOK(serverfailed)
asprobe() {
 _RETRY=0
 # Try until the NFBK (number of fails before considering the AS completly out of service)
 while [[ ${_RETRY} -lt ${NFBK} ]];
 do
  _wgetreq ${1} ${$} ${2} &			# start the wget in background
  _WGETREQPID=${!}				# get the wget pid
  sleep ${TBASF}				# time allowed to wget process
  kill -9 ${_WGETREQPID} >>/dev/null 2>&1	# kill the current wget
  # check the result
  WGETRESULT=`egrep "HTTP request sent, awaiting response..." ${STOP}/tmp/wgetreq.${1}.${$}.${2}`
  HTTPRC=`echo ${WGETRESULT} | awk '{ print $6 }'`
  # handle the http request return code 
  #+ still no wget answer
  if [[ -z $HTTPRC  ]]; # answer is null
  then
   rm ${STOP}/tmp/wgetreq.${1}.${$}.${2} 	# Clean up the pipe file	# clean
   let _RETRY=${_RETRY}+1			# increase the retry counter
  fi
  if [[ ${HTTPRC} != "200" && ${HTTPRC} != "302" ]]
  then
   rm ${STOP}/tmp/wgetreq.${1}.${$}.${2} # Clean up the pipe file	# clean
   let _RETRY=${_RETRY}+1			# increase the retry counter
  fi
  #+ Good return code (200)
  if [[ $HTTPRC -eq 200 || ${HTTPRC} -eq 302 ]];
  then
   rm ${STOP}/tmp/wgetreq.${1}.${$}.${2} 	# clean
   echo 0 > ${STOP}/tmp/asprobe.${1}.${2}	# write the rc to communicate it to the clusterprobe
   return 0					# function exit
  fi
 done
 echo 1 > ${STOP}/tmp/asprobe.${1}.${2}		# write the rc to communicate it to the clusterprobe
 return 1					# function exit
}

# _CCIasprobe <clusterprobeID> <port>
# return 0=OK(serverishealty),1=NOK(serverfailed)
CCIasprobe() {
 _RETRY=0
 # Try until the NFBK (number of fails before considering the AS completly out of service)
 while [[ ${_RETRY} -lt ${NFBK} ]];
 do
  _wgetreq ${1} ${$} ${2} &			# start the wget in background
  _WGETREQPID=${!}				# get the wget pid
  sleep ${TBASF}				# time allowed to wget process
  kill -9 ${_WGETREQPID} >>/dev/null 2>&1	# kill the current wget
  # check the result
  WGETRESULT=`egrep "HTTP request sent, awaiting response..." ${STOP}/tmp/wgetreq.${1}.${$}.${2}`
  HTTPRC=`echo ${WGETRESULT} | awk '{ print $6 }'`
  # handle the http request return code 
  #+ still no wget answer
  if [[ -z $HTTPRC  ]]; # answer is null
  then
   rm ${STOP}/tmp/wgetreq.${1}.${$}.${2} 	# Clean up the pipe file	# clean
   let _RETRY=${_RETRY}+1			# increase the retry counter
  fi
  if [[ -z $HTTPRC || ${HTTPRC} == "500" ]]
  then #- Bad return code (null RC or 500) 
   rm ${STOP}/tmp/wgetreq.${1}.${$}.${2} # Clean up the pipe file	# clean
   let _RETRY=${_RETRY}+1			# increase the retry counter
  else #+ Good return code (not null and <> 500)
   rm ${STOP}/tmp/wgetreq.${1}.${$}.${2} 	# clean
   echo 0 > ${STOP}/tmp/asprobe.${1}.${2}	# write the rc to communicate it to the clusterprobe
   return 0					# function exit
  fi
 done
 echo 1 > ${STOP}/tmp/asprobe.${1}.${2}		# write the rc to communicate it to the clusterprobe
 return 1					# function exit
}

clusterprobe() {
 #set -x
 _ASPROBEPIDLIST=""
 _CLTIMECOUNT=0
 _CLUSTERSTATUS=0
 _ASCHECKED=0
 for port in ${PORTLIST};			# loop on the port list
 do
  CCIasprobe ${$} ${port} &			# for each port lauch an AS probe in background
  _ASPROBEPIDLIST="${_ASPROBEPIDLIST} ${port}"
  let _ASCHECKED=${_ASCHECKED}+1
 done
 while [[ ${_CLTIMECOUNT} -lt ${TBCF} && ${_ASCHECKED} -ne 0 ]]; 
 do
  for asport in ${_ASPROBEPIDLIST};
  do
   if [[ -f ${STOP}/tmp/asprobe.${$}.${asport} ]];
   then
    if [[ `cat ${STOP}/tmp/asprobe.${$}.${asport}` -eq 0 ]];
    then
     let _CLUSTERSTATUS=${_CLUSTERSTATUS}+1
    fi   
    let _ASCHECKED=${_ASCHECKED}-1
    rm ${STOP}/tmp/asprobe.${$}.${asport}
   fi
  done
  sleep 1
  let _CLTIMECOUNT=${_CLTIMECOUNT}+1 
 done
 return ${_CLUSTERSTATUS}
}

#F01.13.01
#Function : killer, kill a process that still running after an allowed time when it supposed to be stopped
#Syntaxe  : killer <process> <timeout>
#Return   : 0=OK clear,1=Process is still running,2=error
killer() {
 while [[ ${WAITCOUNT} -lt ${2} ]];     #While the timeout have not been reach
 do
  ps $1 $1 2>&1 >> /dev/null            #check if the process is still there
  if [[ $? -eq 1 ]];
  then
   return 0                             #If if the case, don't waste your time and return
  fi
  let WAITCOUNT=${WAITCOUNT}+1          #Increase the time counter
  sleep 1                               #Wait a second
 done
 kill $1 $1 2>&1 >>/dev/null            #Timeout is reach and the process is still there, normal kill on the process
 sleep 5                                #wait 5 second to give a chance to finish normally
 kill -9 $1 2>&1 >>/dev/null            #kill -9 on the process
 ps $1 >> /dev/null                     #check if the process is still there
 if [[ $? -eq 1 ]];
 then
  return 0                              #ok the process is gone
 else
  return 1                              #the process is still there
 fi
return 2
}

getihspid() {
 #set -x
 unset IHSPIDLIST
 # If it's a multiple IHS instance mode
 if [[ -n ${1} ]];
 then # do as a multiple IHS instance
  export IHSPIDLIST=`ps auxwww | egrep "httpd${1}.conf" | grep -v [gG]rep | awk '{ print $2 }'`
 else # do as a simple IHS instance
  export IHSPIDLIST=`ps auxwww | egrep "${IHS_PATH}/bin/httpd" | grep -v [gG]rep | awk '{ print $2 }'`
 fi
}

stopihs4ali() {
 if [[ -z $1 ]];
 then
  p2s "Stopping IHS process.."
 else
  p2s "Stopping IHS process, instance #${IHSINSTANCE}."
 fi
 #set -x
 getihspid ${IHSINSTANCE}
 if [[ -n $IHSPIDLIST ]];
 then
  ${IHS_PATH}/bin/apachectl${IHSINSTANCE} stop &
  for pid in $IHSPIDLIST;
  do
   killer $pid 5 &
  done
 fi
}

printhelp() {
 p2s "Syntaxe : $0\n -a<ihsprocessname>\n -b<timebeforeclusterfailed>\n -t<timebeforeASfailed>\n -n<numoffailbeforekill>\n -d<retrydelay>\n -q<quorum>\n -p<portlist>\n -c<healthcheckcontext>\n -i<iptarget>\n -l<clustername>\n -k(dontkillihs)\n -h(thishelp)"
}

#@@@ Checks Section @@@#

#@@@ Main Section @@@#
# Handle switch options #
if [[ $# -eq 0 ]];
then
 printhelp
 exit 1
fi

while getopts ":a:t:n:d:q:p:c:i:lkh" opt;
do
 case $opt in
  a) IHSPROCESSNAME=${OPTARG};;
  b) TBCF=${OPTARG};;
  t) TBASF=${OPTARG};;
  n) NFBK=${OPTARG};;
  d) FDLY=${OPTARG};;
  q) QUORUM=${OPTARG};;
  p) PORTLIST=${OPTARG};;
  c) HCCONTEXT=${OPTARG};;
  i) IPTARGET=${OPTARG};;
  l) CLNAME=${OPTARG};;
  k) KILLIHS="N";;
  h) printhelp 
     return 0;;
  *) printhelp
     return 1;;
 esac
done

clusterprobe
ASOK=$?
echo Number of operational application server : $ASOK

if [[ ${ASOK} -le ${QUORUM} && ${KILLIHS} == "Y" ]];			# Check if IHS need to be kill
then
 if [[ ${IHSPROCESSNAME} == "httpd" ]];					# Check if is a multiple IHS environment
 then
  echo "IHS will die in single!"
  stopihs4ali								# stop IHS
 else
  IHSID=`echo ${IHSPROCESSNAME} | sed 's/httpd//g'`			# get the IHS id
  echo "IHS instance #${IHSID} will die!"
  stopihs4ali ${IHSID}							# stop the specific IHS
 fi
else
 echo "IHS will live!"
fi

return $ASOK
