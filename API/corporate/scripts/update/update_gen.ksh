#!/bin/ksh

# Verification des arguments
if [[ ${#} -ne 3 ]]
then
	# On quitte le script
	echo "Syntaxe : ./update_gen.ksh <path_api> <server> <rootpwd>"
	exit 1
fi

# Declaration de variables
path_api=${1}
server=${2}
rootpwd=${3}
api_targz=$(basename ${path_api})
api_tar=$(echo ${api_targz} | awk -F '.' '{print $1"."$2"."$3}')
api_name=$(echo ${api_tar} | awk -F '.' '{print $1"."$2}')

# Verification de la presence d'une API sur le serveur distant
ssh api@${server} "if [[ -d /home/api/versions ]]; then return 1; else return 0; fi;" 

# Y'a t-il deja une version de l'API ?
if [[ ${?} -ne 1 ]]
then
	# Non donc on quitte le script
  	echo "No API is installed."
	exit 1
fi 

# Transfert de l'API
scp ${path_api} api@${server}:/home/api 

# Affectation de la valeur retour
result=${?}

# La commande a t-elle reussi
if [[ ${result} -ne 0 ]]
then
	# Non donc on quitte le script
	echo "ERROR during transfert."
	exit ${result}
fi

# Creation du repertoire contenant l'API
ssh api@${server} "mkdir /home/api/versions/${api_name}"

# Affectation de la valeur retour
result=${?}

# La commande a t-elle reussi
if [[ ${result} -ne 0 ]]
then
        # Non donc on quitte le script
	echo "ERROR during directory creation"
        exit ${result}
fi
 
# Deplacement de l'API et detarrage 
ssh api@${server} "mv /home/api/${api_targz} /home/api/versions/${api_name}; cd /home/api/versions/${api_name}; gunzip ${api_targz}; tar xvf ${api_tar}"

# Affectation de la valeur retour
result=${?}

# La commande a t-elle reussi
if [[ ${result} -ne 0 ]]
then
        # Non donc on quitte le script
	echo "ERROR during move and extract of the API package."
        exit ${result}
fi

# Creation du lien symbolique pour les versions 
ssh api@${server} "ln -sf /home/api/versions/${api_name} /home/api/APIX2P"

# Affectation de la valeur retour
result=${?}

# La commande a t-elle reussi
if [[ ${result} -ne 0 ]]
then
        # Non donc on quitte le script
	echo "ERROR during creation of the API link."
        exit ${result}
fi

# Creation du lien symbolique pour initapi 
./create_sym_initapi.exp ${server} ${rootpwd} 

# Affectation de la valeur retour
result=${?}

# La commande a t-elle reussi
if [[ ${result} -ne 0 ]]
then
        # Non donc on quitte le script
	echo "ERROR during creation of the /usr/bin/initapi link."
        exit ${result}
fi

# Fin du script
exit 0
