#!/usr/bin/env bash

# Constantes globales
export SERVIDORES=(ftp-servidor-principal ftp-servidor-espejo)
export CONFIRMACIONES="si no"
export OPCIONES_CREACION_SERVIDORES="1 2"
export FTP_USER="testuser"
export FTP_USER_PASSWORD="123"
export UBUNTU_IMAGE="bionic"

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

# Variables globales
export lista_servidores_para_ser_creados=()
export los_servidores_necesitan_ser_creados="false"

function mostrarLogo(){
    echo
    echo "┌─┐┌─┐┬─┐┬  ┬┬┌┬┐┌─┐┬─┐┌─┐┌─┐  ┌─┐┌┬┐┌─┐ "
    echo "└─┐├┤ ├┬┘└┐┌┘│ │││ │├┬┘├┤ └─┐  ├┤  │ ├─┘ "
    echo "└─┘└─┘┴└─ └┘ ┴─┴┘└─┘┴└─└─┘└─┘  └   ┴ ┴   "
    echo
}

function mostrarMensaje(){
    local nivelDelMensaje=$1
    local mensaje=$2
    local nivelesMensajeValidos=(info warn error custom)

    case ${nivelDelMensaje} in
        "info")
            echo -e "${BLUE}(info)${RESET} ${mensaje}"
            ;;
        "warn")
            echo -e "${YELLOW}(warn)${RESET} ${mensaje}"
            ;;
        "error")
            echo -e "${RED}(error)${RESET} ${mensaje}"
            ;;
        *)
            echo -e "nivel del mensaje no valido, los niveles validos son: '${nivelesMensajeValidos[@]}'"
    esac

}

function _esValidaLaConfirmacion(){
    local lista=$1
    local confirmacion=$2

    [[ ${lista} =~ (^|[[:space:]])${confirmacion}($|[[:space:]]) ]] && echo 'valida' || echo 'invalida'
}

function _obtenerConfirmacion(){

        local confirmacion="invalida"
        local entradaUsuario=""


        while [[ ${confirmacion} = "invalida" ]]
            do
                read -p "(eleccion) si | no: " input
                confirmacion=$(_esValidaLaConfirmacion "${CONFIRMACIONES}" "${input,,}")
                entradaUsuario=${input}
        done

        echo ${entradaUsuario}
}

function verificarExistenciaServidores(){
    # Verificando que los servidores no existan, de caso contrario se le pregunta al usuario si desea borrarlos

    purge=false

    for servidor in "${SERVIDORES[@]}"; do
        multipass ls | grep "${servidor}" > /dev/null 2>&1

        if [[ $? -eq 0 ]]; then
            mostrarMensaje "warn" "el servidor '${BOLD}${servidor}${RESET}' ya existe, desea elmininarlo?"
            local confirmacion=$(_obtenerConfirmacion)

            if [[ ${confirmacion} = "si" ]]; then
                echo -ne "${BLUE}(info)${RESET} eliminando el servidor: '${servidor}' ... "
                multipass delete ${servidor} && echo "${GREEN}DONE${RESET}"
                purge=true
                lista_servidores_para_ser_creados+=("${servidor}")
            fi

        else
            # el servidor no existe y necesita ser creado
            lista_servidores_para_ser_creados+=("${servidor}")
        fi
    done

    [[ ${purge} = "true" ]] && multipass purge
}

function _eliminarServidores(){
    local lista_servidores_para_ser_borrados=( $@ )

    local total_servidores=${#lista_servidores_para_ser_borrados[@]}
    local servidor_actual=1

    for servidor in "${lista_servidores_para_ser_borrados[@]}"; do
        echo -ne "${BLUE}(info)${RESET} eliminado el servidor '${BOLD}${servidor}${RESET}' (${servidor_actual}/${total_servidores}) ... "
        multipass delete ${servidor}

        if [[ $? -eq 0 ]]; then
            echo "${GREEN}DONE${RESET}" && let "servidor_actual++"
        else
            echo "${RED}FAIL${RESET}"
            mostrarMensaje "err" "el servidor '${servidor}' no pudo ser eliminado"
            exit 1
        fi
    done

    multipass purge

}

function _crearServidores(){
    local lista_servidores_para_ser_creados=($@)

    local total_servidores=${#lista_servidores_para_ser_creados[@]}
    local servidor_actual=1

    for servidor in "${lista_servidores_para_ser_creados[@]}"; do
        mostrarMensaje "info" "creando el servidor '${BOLD}${servidor}${RESET}' (${servidor_actual}/${total_servidores}) ..."
        multipass launch ${UBUNTU_IMAGE} --name ${servidor}

        if [[ $? -eq 0 ]]; then
            let "servidor_actual++"
        else
            mostrarMensaje "error" "el servidor '${servidor}' no pudo ser creado" && exit 1
        fi
    done
}

function crearServidores(){

    if [[ ${#lista_servidores_para_ser_creados[@]} -ne 0 ]]; then
        # Por lo menos un servidor no existe en el sistema
        _crearServidores "${lista_servidores_para_ser_creados[@]}"

    elif [[ ${#lista_servidores_para_ser_creados[@]} -eq 0 ]]; then
        # Ambos servidores existen en el sistema y el usuario respondio que no se borren ambos servidores anteriormente
        mostrarMensaje "warn" "si no se crean servidores frescos pueden presentarse errores de configuracion"
        mostrarMensaje "info" "que desea hacer? \n 1. Crear servidores nuevos \n 2. Continuar con los servidores actuales"

        local confirmacion="invalida"
        local entradaUsuario=""

        while [[ ${confirmacion} = "invalida" ]]
            do
                read -p "(eleccion): " input
                confirmacion=$(_esValidaLaConfirmacion "${OPCIONES_CREACION_SERVIDORES}" "${input,,}")
                entradaUsuario=${input}
        done

        if [[ ${entradaUsuario} -eq 1 ]]; then
            _eliminarServidores "${SERVIDORES[@]}"
            _crearServidores "${SERVIDORES[@]}"
        fi
    fi
}

function _ejecutarSedComandoServidor(){
    local servidor=$1
    local stringBuscar=$2
    local stringRemplazar=$3
    local archivoDestino=$4
    local imprimirResultado=$5

    multipass exec ${servidor} -- sudo sed -i "s|${stringBuscar}|${stringRemplazar}|g" ${archivoDestino}

    if [[ $? -eq 0 ]]; then
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

function _ejecutarComandoServidor(){
    # Restrincciones: no se pueden ejecutar comandos con '&&', tienen que ser comandos individuales
    local servidor=$1
    local comando=$2
    local imprimirResultado=$3

    multipass exec ${servidor} -- ${comando} &> log.txt

    if [[ $? -eq 0 ]]; then
        if [[ "${imprimirResultado}" = "imprimirResultado" ]]; then
            echo "${GREEN}DONE${RESET}"
        fi
    else
        if [[ "${imprimirResultado}" = "imprimirResultado" ]]; then
            echo "${RED}FAIL${RESET}"
        fi
        exit 1
    fi

}

function instalarPaquetesServidores(){

    local total_servidores=${#SERVIDORES[@]}
    local servidor_actual=1
    local instruccion_actual=1
    local total_instrucciones=8

    for servidor in "${SERVIDORES[@]}"; do
        echo -ne "${BLUE}(info)${RESET} actualizando paquetes en el servidor '${servidor}' (servidor ${servidor_actual}/${total_servidores}) (instruccion ${instruccion_actual}/${total_instrucciones}) ... "
        _ejecutarComandoServidor "${servidor}" "sudo apt update -y" "imprimirResultado"
        let "instruccion_actual++"

        echo -ne "${BLUE}(info)${RESET} upgradeando paquetes en el servidor '${servidor}' (servidor ${servidor_actual}/${total_servidores}) (instruccion ${instruccion_actual}/${total_instrucciones}) ... "
        _ejecutarComandoServidor "${servidor}" "sudo apt upgrade -y" "imprimirResultado"
        let "instruccion_actual++"

        echo -ne "${BLUE}(info)${RESET} instalando paquetes para le servicio FTP en el servidor '${servidor}' (servidor ${servidor_actual}/${total_servidores}) (instruccion ${instruccion_actual}/${total_instrucciones}) ... "
        _ejecutarComandoServidor "${servidor}" "sudo apt install vsftpd -y" "imprimirResultado"
        let "instruccion_actual++"

        echo -ne "${BLUE}(info)${RESET} habilitando el servicio de FTP en el servidor '${servidor}' (servidor ${servidor_actual}/${total_servidores}) (instruccion ${instruccion_actual}/${total_instrucciones}) ... "
        _ejecutarComandoServidor "${servidor}" "sudo systemctl start vsftpd"
        _ejecutarComandoServidor "${servidor}" "sudo systemctl enable vsftpd" "imprimirResultado"
        let "instruccion_actual++"

        echo -ne "${BLUE}(info)${RESET} creando el usuario para el servicio de FTP en el servidor '${servidor}' (servidor ${servidor_actual}/${total_servidores}) (instruccion ${instruccion_actual}/${total_instrucciones}) ... "
        _ejecutarComandoServidor "${servidor}" "sudo useradd -d /home/${FTP_USER} -m ${FTP_USER} -p $(openssl passwd -1 ${FTP_USER_PASSWORD}) -s /bin/bash" "imprimirResultado"
        let "instruccion_actual++"

        echo -ne "${BLUE}(info)${RESET} configurando el firewall para aceptar trafico de FTP en el servidor '${servidor}' (servidor ${servidor_actual}/${total_servidores}) (instruccion ${instruccion_actual}/${total_instrucciones}) ... "
        _ejecutarComandoServidor "${servidor}" "sudo ufw allow 20/tcp"
        _ejecutarComandoServidor "${servidor}" "sudo ufw allow 21/tcp" "imprimirResultado"
        let "instruccion_actual++"

        echo -ne "${BLUE}(info)${RESET} habilitando la transferencia de archivos mediante FileZilla en el servidor '${servidor}' (servidor ${servidor_actual}/${total_servidores}) (instruccion ${instruccion_actual}/${total_instrucciones}) ... "
        _ejecutarSedComandoServidor "${servidor}" "#write_enable=YES" "write_enable=YES"  "/etc/vsftpd.conf"
        _ejecutarComandoServidor "${servidor}" "sudo systemctl restart vsftpd.service" "imprimirResultado"
        let "instruccion_actual++"

        echo -ne "${BLUE}(info)${RESET} habilitando la transferencia de archivos mediante SSH en el servidor '${servidor}' (servidor ${servidor_actual}/${total_servidores}) (instruccion ${instruccion_actual}/${total_instrucciones}) ... "
        _ejecutarSedComandoServidor "${servidor}" "#PermitRootLogin prohibit-password" "PermitRootLogin yes" "/etc/ssh/sshd_config"
        _ejecutarSedComandoServidor "${servidor}" "PasswordAuthentication no" "PasswordAuthentication yes" "/etc/ssh/sshd_config"
        _ejecutarComandoServidor "${servidor}" "sudo service ssh restart" "imprimirResultado"
        let "instruccion_actual++"

        let "servidor_actual++"
        instruccion_actual=1
    done
}


function habilitarConexionEntreServidores(){

    local instruccion_actual=1
    local total_instrucciones=4

    echo -ne "${BLUE}(info)${RESET} creando el directorio SSH en el servidor 'ftp-servidor-principal' (instruccion ${instruccion_actual}/${total_instrucciones}) ... "
    _ejecutarComandoServidor "ftp-servidor-principal" "sudo mkdir -p /home/${FTP_USER}/.ssh" "imprimirResultado"
    let "instruccion_actual++"

    # standalone command
    multipass exec ftp-servidor-principal -- sudo ssh-keygen -b 2048 -t rsa -f /home/${FTP_USER}/.ssh/id_rsa -q -N "" &> log.txt
    if [[  $? -ne 0  ]]; then
        mostrarMensaje "error" "no se pudo crear la llave SSH para el usuario '${FTP_USER}'"
        exit 1
    fi

    echo -ne "${BLUE}(info)${RESET} cambiando los permisos de la carpeta SSH para el usuario '${FTP_USER}' en el servidor 'ftp-servidor-principal' (instruccion ${instruccion_actual}/${total_instrucciones}) ... "
    _ejecutarComandoServidor "ftp-servidor-principal" "sudo chown -R ${FTP_USER}.${FTP_USER} /home/${FTP_USER}/.ssh" "imprimirResultado"
    let "instruccion_actual++"

    echo -ne "${BLUE}(info)${RESET} creando el directorio SSH en el servidor 'ftp-servidor-espejo' (instruccion ${instruccion_actual}/${total_instrucciones}) ... "
    _ejecutarComandoServidor "ftp-servidor-espejo" "sudo mkdir -p /home/${FTP_USER}/.ssh" "imprimirResultado"
    let "instruccion_actual++"

    # standalone command
    ssh_key=$(multipass exec ftp-servidor-principal -- sudo cat /home/${FTP_USER}/.ssh/id_rsa.pub)
    multipass exec ftp-servidor-espejo -- sudo sh -c "echo ${ssh_key} >> /home/${FTP_USER}/.ssh/authorized_keys"
    if [[  $? -ne 0  ]]; then
        mostrarMensaje "error" "no se pudo crear el archivo 'authorized_keys' para el usuario '${FTP_USER}' en el servidor 'ftp-servidor-espejo'"
        exit 1
    fi

    echo -ne "${BLUE}(info)${RESET} cambiando los permisos de la carpeta SSH para el usuario '${FTP_USER}' en el servidor 'ftp-servidor-espejo' (instruccion ${instruccion_actual}/${total_instrucciones}) ... "
    _ejecutarComandoServidor "ftp-servidor-espejo" "sudo chown -R ${FTP_USER}.${FTP_USER} /home/${FTP_USER}/.ssh" "imprimirResultado"
    let "instruccion_actual++"

}

function probarConexionSSHEntreServidores(){
    ip_servidor_espejo=$(multipass ls | grep "ftp-servidor-espejo" | awk '{print $3}')
    multipass exec ftp-servidor-principal -- sudo runuser -l  ${FTP_USER} -c "ssh -o StrictHostKeyChecking=no ${FTP_USER}@${ip_servidor_espejo} exit" &> log.txt

    if [[  $? -ne 0  ]]; then
        mostrarMensaje "error" "no se pudo establecer la conexion con el servidor 'ftp-servidor-espejo'"
        exit 1
    else
        mostrarMensaje "info" "la conexion entre ambos servidores fue establecida exitosamente"
    fi
}

function insertarBackupScriptEnElServidorPrincipal(){

    ip_servidor_espejo=$(multipass ls | grep "ftp-servidor-espejo" | awk '{print $3}')
    local backupScript="/home/${FTP_USER}/.backup"

    echo -ne "${BLUE}(info)${RESET} insertando el script para hacer backups automaticos en el servidor 'ftp-servidor-principal' ... "
    # standalone commands
    multipass exec -- "ftp-servidor-principal" sudo -H -u ${FTP_USER} bash -c "touch ${backupScript}"
    multipass exec -- "ftp-servidor-principal" sudo -H -u ${FTP_USER} bash -c "chmod +x ${backupScript}"

    multipass exec -- "ftp-servidor-principal" sudo -H -u ${FTP_USER} bash -c "echo '#!/bin/bash' >> ${backupScript}"
    multipass exec -- "ftp-servidor-principal" sudo -H -u ${FTP_USER} bash -c "echo 'while true; do' >> ${backupScript}"
    multipass exec -- "ftp-servidor-principal" sudo -H -u ${FTP_USER} bash -c "echo 'rsync -zaP /home/${FTP_USER}/ ${FTP_USER}@${ip_servidor_espejo}:/home/${FTP_USER}' >> ${backupScript}"
    multipass exec -- "ftp-servidor-principal" sudo -H -u ${FTP_USER} bash -c "echo 'sleep 1' >> ${backupScript}"
    multipass exec -- "ftp-servidor-principal" sudo -H -u ${FTP_USER} bash -c "echo 'done' >> ${backupScript}"
    multipass exec -- "ftp-servidor-principal" sudo -H -u ${FTP_USER} bash -c "(crontab -l &> /dev/null; echo '@reboot sleep 5; /bin/bash ${backupScript} &> /tmp/backup.log') | crontab -;"

    if [[  $? -ne 0  ]]; then
        echo "${RED}FAIL${RESET}"
        mostrarMensaje "error" "no se pudo insertar el script para hacer backups automaticos en el servidor 'ftp-servidor-espejo'"
        exit 1
    else
        echo "${GREEN}DONE${RESET}"
    fi
}

function _iniciar_servidor(){
    local servidor=$1
    multipass start ${servidor} &> log.txt

    if [[  $? -ne 0  ]]; then
        echo "${RED}FAIL${RESET}"
        mostrarMensaje "error" "no se pudo iniciar el servidor '${servidor}'"
        exit 1
    fi
}

function reiniciarServidores(){

    for servidor in "${SERVIDORES[@]}"; do
        # standalone command
        echo -ne "${BLUE}(info)${RESET} reiniciando servidor '${servidor}' ... "
        multipass exec ${servidor} -- sudo reboot

        if [[  $? -ne 255  ]]; then
            echo "${RED}FAIL${RESET}"
            mostrarMensaje "error" "no se pudo reiniciar el servidor '${servidor}'"
            exit 1
        else
            echo "${GREEN}DONE${RESET}"
        fi

        echo -ne "${BLUE}(info)${RESET} iniciando servidor '${servidor}' ... "
        _iniciar_servidor ${servidor} && sleep 2

        # verficando el estado del servidor
        local estadoServidor=$(multipass ls | grep "${servidor}" | awk '{print $2}')

        while [[ ${estadoServidor} = "Starting" ]]
            do
            _iniciar_servidor ${servidor} && sleep 2
            estadoServidor=$(multipass ls | grep "${servidor}" | awk '{print $2}')
        done

        echo "${GREEN}DONE${RESET}"
    done
}

function mostrarMensajeConexion(){

    local ip_servidor_principal=$(multipass ls | grep "ftp-servidor-principal" | awk '{print $3}')
    local ip_servidor_espejo=$(multipass ls | grep "ftp-servidor-espejo" | awk '{print $3}')

    echo
    echo "┌─┐┌─┐┬─┐┬  ┬┬┌┬┐┌─┐┬─┐┌─┐┌─┐  ┌─┐┬─┐┌─┐┌─┐┌┬┐┌─┐┌─┐  ┌─┐┌─┐┌┐┌  ┌─┐─┐ ┬┬┌┬┐┌─┐"
    echo "└─┐├┤ ├┬┘└┐┌┘│ │││ │├┬┘├┤ └─┐  │  ├┬┘├┤ ├─┤ │││ │└─┐  │  │ ││││  ├┤ ┌┴┬┘│ │ │ │"
    echo "└─┘└─┘┴└─ └┘ ┴─┴┘└─┘┴└─└─┘└─┘  └─┘┴└─└─┘┴ ┴─┴┘└─┘└─┘  └─┘└─┘┘└┘  └─┘┴ └─┴ ┴ └─┘"
    echo
    echo -e "Puedes abrir dos pestañas de Google Chrome y acceder a las siguientes direcciones: \n"
    echo "> ftp://${ip_servidor_principal} (servidor principal)"
    echo "> ftp://${ip_servidor_espejo} (servidor espejo)"
    echo
    echo -e "las credenciales son: \n"
    echo " - usuario   : testuser "
    echo " - password  : 123 "
    echo
}

mostrarLogo # paso 1
verificarExistenciaServidores # paso 2
crearServidores # paso 3
instalarPaquetesServidores # paso 4
habilitarConexionEntreServidores # paso 5
probarConexionSSHEntreServidores # paso 6
insertarBackupScriptEnElServidorPrincipal # paso 7
reiniciarServidores # paso 8
mostrarMensajeConexion # paso 9