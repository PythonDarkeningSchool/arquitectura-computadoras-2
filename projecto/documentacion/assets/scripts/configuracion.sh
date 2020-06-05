#!/usr/bin/env bash

# Constantes globales
export SERVIDORES=(ftp-servidor-principal ftp-servidor-espejo)
export CONFIRMACIONES="si no"
export OPCIONES_CREACION_SERVIDORES="1 2"

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
            echo "${GREEN}DONE${RESET}" && let "actual_servidor++"
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
        multipass launch --name ${servidor}

        if [[ $? -eq 0 ]]; then
            let "actual_servidor++"
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

verificarExistenciaServidores
crearServidores