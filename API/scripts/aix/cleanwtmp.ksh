#!/bin/ksh

################################################################
# Name : cleanwtmp.ksh                                         #
# Purpose : Clean the wtmp file and generate logs              # 
# Version : 1.2                                                #
# Syntax : cleanwtmp.ksh                                       #
# Created on : 2010/03/25                                      #
# History :                                                    #
#   2010/03/25 (S.Ballaud) Initial version.                    #
#   2010/03/26 (S.Ballaud) Version 1.1 used api.lib.           #
#   2010/03/26 (S.Ballaud) Version 1.2 used other functions.   # 
# Developpers :                                                #
#   Sylvain Ballaud can be reached at <sylvain.ballaud@x2p.fr> #         
################################################################

# Chargement de librairie
. ${APIHOME}/lib/aixcom.lib
. ${APIHOME}/lib/apicom.lib

# Initialisation des logs
init_api_logs

# Demarrage de l'enregistrement des logs 
print_api_logfile start

# On verifie que l'utilisateur est root
get_aix_curUser root

# Est ce que c'est le cas ?
if [[ ${?} -eq 1 ]]
then
	# Non donc on indique une erreur et on quitte le script
	print_api_stdoutD "1) Execution of the script"
	print_api_logfile err "1) Execution of the script" 1
	print_api_logfile more "You must be root to execute the script !!!" 
	exit
else
	# Oui donc on log
	print_api_stdoutD "1) Execution of the script"
	print_api_logfile log "1) Execution of the script"
	print_api_logfile more "The user is root"
fi

# Est ce que le fichier wtmp n'existe pas ?
if [[ ! -f "/var/adm/wtmp" ]]
then
	# Oui donc on indique une erreur et on quitte du script
	print_api_stdoutD err "2) Localisation of the file" 1
	print_api_logfile err "2) Localisation of the file" 1
	print_api_logfile more "The file wtmp isn't in the directory /var/adm !!!"
	exit
else
	# Non donc on log
	print_api_stdoutD log "2) Localisation of the file"
	print_api_logfile log "2) Localisation of the file"
	print_api_logfile more "The file wtmp is in the directory /var/adm"
fi

# On execute le nettoyage pour garder 1000 lignes dans le fichier wtmp.txt avec redirection stdout et stderr dans le fichier verbeux
clean_aix_wtmp 1000 &>>${VLOGFILE}
 
# On analyse le resultat du nettoyage du fichier wtmp 
case ${?} in

	0) 
		# Le fichier wtmp a ete efface et le fichier wtmp.txt n'a pas ete change
		print_api_stdoutD log "3) File wtmp flushed and file wtmp.txt unchanged"
		print_api_logfile log "3) File wtmp flushed and file wtmp.txt unchanged" ;;
	1) 
		# Le fichier wtmp a ete efface et le fichier wtmp.txt a ete tronquee
		print_api_stdoutD log "3) File wtmp flushed and file wtmp.txt truncated" 
		print_api_logfile log "3) File wtmp flushed and file wtmp.txt truncated" ;;
	2)
		# Le fichier wtmp n'a pas ete efface
		print_api_stdoutD end "Ending with error" 2
		print_api_logfile end "Ending with error" 2
		print_api_logfile more "File wtmp not flushed !!!" 
		exit ;;
esac

# Fin de l'enregistrement des logs
print_api_stdoutD end
print_api_logfile end 
