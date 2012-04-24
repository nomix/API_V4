#!/bin/ksh
echo $#
if [[ $# -eq 3 && -f ./rmt_chg_api_pwd.exp ]]
then
 ssh root@${1} "mkgroup -'A' id='210' api;mkuser id=210 pgrp=api admgroups=api home=/home/api shell=/usr/bin/ksh gecos='APIX2P user' loginretries=20 data=-1 stack=-1 core=200 rss=-1 nofiles=-1 fsize_hard=-1 data_hard=-1 stack_hard=-1 core_hard=200 rss_hard=-1 nofiles_hard=-1 api"
 ./rmt_chg_api_pwd.exp ${1} ${2} ${3}
 ./rmt_api_keyexchg.exp ${1} ${3}
else
 echo "Syntaxe : ./rmt_cr_api_user.ksh <server> <rootpwd> <apipwd>"
 echo "Verify that the script rmt_chg_api_pwd.ex is in the current path."
fi
