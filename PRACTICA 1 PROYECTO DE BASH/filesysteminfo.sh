#!/bin/bash


##################################################################################################
##                                                                                              ##
##   AUTOR: CARLOS VARGAS                                                                       ##
##   EMANIL: alu0101604077@ull.edu.es                                                           ##
##   FECHA NOVIEMBRE 2022                                                                       ##
##   NOMBRE: filesysteminfo.sh                                                                  ##
##                                                                                              ##
##   Practica evaluada para la asignatura de Sistemas Operativos                                ##
##   Proyecto de Bash                                                                           ##
##################################################################################################


### CONSTANTES

TITLE="============================================
Información del sistema para $HOSTNAME
============================================
"

RIGHT_NOW=$(date +"%x %r%Z")
TIME_STAMP="Actualizada el $RIGHT_NOW por $USER"

###  ESTILOS

TERM_COLS="$(tput cols)"
TEXT_BOLD=$(tput bold)

TEXT_UNLINE=$(tput sgr 0 1)
TEXT_GREEN=$(tput setaf 2)
TEXT_RESET=$(tput sgr0)
TEXT_BLUE=$(tput setaf 4)
TEXT_BLACK=$(tput setaf 1)
TEXTBG_RED=$(tput setab 0)

### VARIABLES
USUARIOS=$(ps -A --no-headers -ouser | sort | uniq)


##FUNCION PARA MOSTRAR EN PANTALLA EL MANUAL DEL SCRIPT

manual()
{
cat << _EOF_

    SCRIPT DISEÑADO PARA LA PRACTICA EN BASH DE SISTEMAS OPERATIVOS

    ESTE SCRIPT PERMITE RECIBIR DISTINTOS PARAMETROS EN LA LINEA DE COMANDO PARA SU EJECUCIÒN. ENTRE ELLOS:

    1- SIN PARAMETROS          --------  MUESTRA LA TABLA DE LOS SISTEMAS DE ARCHIVOS.                          ---  (./filesysteminfo2.sh )                       

    2- [-h] ó [--help]         --------  MUESTRA POR PANTALLA EL MANUAL DE USO DEL SCRIPT.                      ---  (./filesysteminfo2.sh  -h)

    3- [-inv] ó [--inversa]    --------  MUESTRA LA TABLA DE LOS SISTEMAS DE ARCHIVOS DE MANERA INVERSA.        ---  (./filesysteminfo2.sh  -inv)

    4- [-dv] ó [-devicefiles]  --------  REPRESENTA LA TABLA CONSIDERANDO SOLO LOS DISPOSITIVOS
                                         REPRESENTADOS EN EL SISTEMA OPERATIVO COMO ARCHIVOS (DEVICES FILES)    ---  (./filesysteminfo2.sh  -dv)

    5- [-u] ó [--usuario]      --------  ADMITE UNA LISTA DE USUARIOS.                              ---  (./filesysteminfo2.sh  -u jmtorres jttoledo dabreu)
_EOF_
    }



## FUNCION PARA MOSTRAR LA TABLA DE DISPOSITIVO


Lista_De_Dispositivos()
{
    
    for div in $Dispositivos; do 

        Sistema_De_Archivo=$(df -a -t $div | tail -n +2 | tr -s ' ' | sort -n -k 3 | tail -1 | cut -d ' ' -f 1) 
        Punto_De_Montaje=$(df -a -t $div | tail -n +2 | tr -s ' ' | sort -n -k 3 | tail -1 | cut -d ' ' -f 6) 
        Almacenamiento_Ocupado=$(df -a -t $div | tail -n +2 | tr -s ' ' | sort -n -k 3 | tail -1 | cut -d ' ' -f 3)
        mayor_menor=$(stat -c '%t,%T' $Sistema_De_Archivo 2> /dev/null || echo 'opps')
        openfiles=$(lsof | grep ${mayor_menor} | wc -l)
        

        printf "%-22s %-27s %26d %30s %30s\n" "$Sistema_De_Archivo" "$Punto_De_Montaje" "$Almacenamiento_Ocupado" "$mayor_menor" "$openfiles"
        
    done  

}

Device_files()
{
    
    for div in $Dispositivos; do

        Sistema_De_Archivo=$(df -a -t $div | tail -n +2 | tr -s ' ' | sort -n -k 3 | tail -1 | cut -d ' ' -f 1) 
        Punto_De_Montaje=$(df -a -t $div | tail -n +2 | tr -s ' ' | sort -n -k 3 | tail -1 | cut -d ' ' -f 6) 
        Almacenamiento_Ocupado=$(df -a -t $div | tail -n +2 | tr -s ' ' | sort -n -k 3 | tail -1 | cut -d ' ' -f 3)
        mayor_menor=$(stat -c '%t,%T' $Sistema_De_Archivo 2> /dev/null || echo 'opps')  ##SE HA COLOCADO OPPS EN VEZ DE UN * YA QUE LO TOMABA SOMO SIMBOLO RESTRINGIDO
        openfiles=$(lsof | grep ${mayor_menor} | wc -l)
        
        
        
        if [ "$mayor_menor" != "opps" ] ; then
        
            printf "%-22s %-27s %26d %30s %30s\n" "$Sistema_De_Archivo" "$Punto_De_Montaje" "$Almacenamiento_Ocupado" "$mayor_menor" "$openfiles"

        fi
        
    done 

   



}

# FUNCION DISEÑADA PARA CENTRAR TEXTO


msg()
    {
        [[ $# == 0 ]] && return 1

        declare -i TERM_COLS="$(tput cols)"
        declare -i str_len="${#1}"
        [[ $str_len -ge $TERM_COLS ]] && {
            echo "$1";
            return 0;
        }

        declare -i filler_len="$(( (TERM_COLS - str_len) / 2 ))"
        [[ $# -ge 2 ]] && ch="${2:0:1}" || ch=" "
        filler=""
        for (( i = 0; i < filler_len; i++ )); do
            filler="${filler}${ch}"
        done

        printf "%s%s%s" "$filler" "$1" "$filler"
        [[ $(( (TERM_COLS - str_len) % 2 )) -ne 0 ]] && printf "%s" "${ch}"
        printf "\n"

        return 0
    }


Comprobacion_Comandos()
{
    test -x "$(which ps)" || Error_Exit "El comando <ps> no se puede ejcutar"
    test -x "$(which who)" || Error_Exit "El comando <who> no se puede ejcutar"
    test -x "$(which awk)" || Error_Exit "El comando <awk> no se puede ejcutar"
    test -x "$(which sed)" || Error_Exit "El comando <sed> no se puede ejcutar"
    test -x "$(which printf)" || Error_Exit "El comando <printf> no se puede ejcutar"
    test -x "$(which uniq)" || Error_Exit "El comando <uniq> no se puede ejcutar"
    test -x "$(which lsof)" || Error_Exit "El comando <lsof> no se puede ejcutar"
    test -x "$(which id)" || Error_Exit "El comando <id> no se puede ejcutar"
    test -x "$(which head)" || Error_Exit "El comando <head> no se puede ejcutar"
    test -x "$(which tail)" || Error_Exit "El comando <tail> no se puede ejcutar"
    test -x "$(which wc)" || Error_Exit "El comando <wc> no se puede ejcutar"
}



Error_Exit()
{
    echo "$1" 1>&2
    exit 1
}


                ##PROGRAMA PRINCIPAL##

Comprobacion_Comandos
if ["$1" == ""]; then
    echo ${TEXT_BOLD}${TEXTBG_RED}${TEXT_BLACK}$TITLE$TEXT_RESET
    printf "%-12s %-12s %-12s %-12s \n""${TEXT_BOLD}${TEXT_BLUE}SISTEMA DE ARCHIVO\t\tPUNTO DE MONTAJE\t\t\tALMACENAMIENTO OCUPADO\t    NUMERO MAYOR Y MENOR\t\tNUMERO TOTAL DE ARCHIVOS MONTADOS PARA EL SISTEMA\n$TEXT_RESET"

    Dispositivos=$( cat /proc/mounts | cut -d ' ' -f 3 | sort | uniq)
    Lista_De_Dispositivos
fi

while [ "$1" != "" ]; do
    case $1 in

        -h | --help )
            msg "-" "-"
            msg "${TEXT_BOLD}${TEXT_BLUE}MANUAL DE USO PARA EL SCRIPT$TEXT_RESET"
            msg "-" "-"
            manual
            ;;

        -inv | --inversa )

            echo ${TEXT_BOLD}${TEXTBG_RED}${TEXT_BLACK}$TITLE$TEXT_RESET
            printf "%-12s %-12s %-12s %-12s \n""${TEXT_BOLD}${TEXT_BLUE}SISTEMA DE ARCHIVO\t\tPUNTO DE MONTAJE\t\t\tALMACENAMIENTO OCUPADO\t    NUMERO MAYOR Y MENOR\t\tNUMERO TOTAL DE ARCHIVOS MONTADOS PARA EL SISTEMA\n$TEXT_RESET"

            Dispositivos=$( cat /proc/mounts | cut -d ' ' -f 3 | sort | uniq | sort -r)
            Lista_De_Dispositivos 
            ;;

        -dv | --devicefiles    )

            echo ${TEXT_BOLD}${TEXTBG_RED}${TEXT_BLACK}$TITLE$TEXT_RESET
            printf "%-12s %-12s %-12s %-12s \n""${TEXT_BOLD}${TEXT_BLUE}SISTEMA DE ARCHIVO\t\tPUNTO DE MONTAJE\t\t\tALMACENAMIENTO OCUPADO\t    NUMERO MAYOR Y MENOR\t\tNUMERO TOTAL DE ARCHIVOS MONTADOS PARA EL SISTEMA\n$TEXT_RESET"

            Dispositivos=$( cat /proc/mounts | cut -d ' ' -f 3 | sort | uniq)
            Device_files
            ;;
  
        * )
            msg "-" "-" 
            msg "${TEXT_BOLD}${TEXT_BLUE}               OOPS AL PARECER HAZ INTRODUCIDO UNA OPCIÓN QUE NO SOPORTO.$TEXT_RESET"  
            msg "PARA CONTINUAR POR FAVOR REVISA EL MANUAL DE USO QUE TE DEJO ACONTINUACIÓN" 
            msg "-" "-" 
            manual
            ;;  
    esac
 

    shift
done        
