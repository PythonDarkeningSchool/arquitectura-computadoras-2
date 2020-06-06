#!/usr/bin/env bash

# Colors
export BLACK=$(tput setaf 0)
export RED=$(tput setaf 1)
export GREEN=$(tput setaf 2)
export YELLOW=$(tput setaf 3)
export BLUE=$(tput setaf 4)
export MAGENTA=$(tput setaf 5)
export CYAN=$(tput setaf 6)
export WHITE=$(tput setaf 7)
export RESET=$(tput sgr0)
export BOLD=$(tput bold)

#function run(){
#    local servidor=$1
#    local comando=$2
#    echo "comando: ${comando}"
#    multipass exec ${servidor} -- ${comando} &> log.txt
#    output=$?
#    echo "output: ${output}"
#}

#run "ftp-servidor-principal" "sudo sed -i s|#write_enable=YES|write_enable=YES|g /etc/vsftpd.conf"
#run  "sudo sed -i s|BEBE|SERA|g /home/ubuntu/FILE"


servidor="ftp-servidor-principal"

function _ejecutarComandoServidor(){
    # Restrincciones: no se pueden ejecutar comandos con '&&', tienen que ser comandos individuales
    local servidor=$1
    local comando=$2
    local imprimirResultado=$3

    echo "servidor: ${servidor}"
    echo "comando: ${comando}"
    echo "imprimirResultado: ${imprimirResultado}"

    multipass exec ${servidor} -- ${comando} &> log.txt
    #varA="bebe"
    #varB="malo really"
    #multipass exec ${servidor} -- sudo sed -i "s|${varA}|${varB}|g" /home/ubuntu/file &> log.txt
    output=$?
    echo "output: ${output}"

    if [[ ${output} -eq 0 ]]; then
        if [[ "${imprimirResultado}" = "imprimirResultado" ]]; then
            echo "${GREEN}DONE${RESET}"
         fi
    else
        if [[ "${imprimirResultado}" = "imprimirResultado" ]]; then
            echo "${RED}FAIL${RESET}"
            exit 1
        fi
    fi

}
