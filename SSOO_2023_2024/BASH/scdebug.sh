#!./ptbash

##################################################################################################
##                                                                                              ##
##   AUTOR:  CARLOS VARGAS                                                                      ##
##   EMAIL: alu0101604077@ull.edu.es                                                            ##
##   FECHA   OCTUBRE 2023                                                                       ##
##   NOMBRE: scdebug.sh                                                                         ##
##   ASIGNATURA: SISTEMAS OPERATIVOS                                                            ##
##                                                                                              ##
##                                                                                              ##
##                                                                                              ##
##################################################################################################

## ======================================================================================================================##
##                                                     CONSTANTES                                                        ##
## ======================================================================================================================##


# Título del script y detalles del autor

TITLE="\\n==================PRÁCTICA DE BASH\\n=================="


RIGHT_NOW=$(date +"%x %r%Z")
TIME_STAMP="ACTUALIZADO El $RIGHT_NOW POR $USER"

## Estilos de texto

TEXT_UNLINE=$(tput sgr 0 1)
TEXT_GREEN=$(tput setaf 2)
TEXT_RESET=$(tput sgr0)
TEXT_BLUE=$(tput setaf 4)
TEXT_BLACK=$(tput setaf 1)
TEXTBG_RED=$(tput setab 0)

## VARIABLES ##

OUTPUT_DIR="$HOME/.scdebug"            ## DIRECTORIO PARA ALMACENAR LOS ARCHIVOS DE SALIDA
FROM_FILE=""
pids_to_attach=()


## ======================================================================================================================##
##                                                      FUNCIONES                                                        ##
## ======================================================================================================================##

## FUNCION AUXILIAR PARA ALINEAR EL TEXRO A MOSTRAR EN LA TERMINAL

center_text() {
  local text="$1"
  local width=80  # Ancho deseado, puede ser ajustado según sea necesario
  local padding="$(((width - ${#text}) / 2))"
  printf "%*s%s%*s\n" $padding "" "$text" $padding ""
}


## ======================================================================================================================##
##                                                     APARTADO 4.1                                                      ##
## ======================================================================================================================##

##FUNCION PARA GENERAR UN UUID A UN ARCHIVO

GET_UUID()                            
{
    uuidgen
}

## FUNCION PARA MOSTRAR MENSAJE DE AYUDA/FUNCIONMIENTO DEL SCRIPT

HELP_MSG()
{
echo "$center_text MANUAL DE AYUDA PARA LA UTILIZACIÓN DEL SCRIPT SCDEBUG"
cat << _EOF_



${center_text}OPCIONES SOPORTADAS POR EL SCRIPT:

-h                          MOSTRAR AYUDA
- sto <arg>                 ESTABLECER UN ARGUMENTO PARA STRACE
-v                          MUESTRA LA SALIDA DE STRACE
-vall           
-nattch <progtoattach>      ADJUNTA STRACE A UN PROCESO EN EJECUCION

ARGUMENTOS POSIBLES:

[PROG]                      PROGRAMA A EJECUTAR Y MONITOREAR CON STRACE
[ARG1 ....]                 ARGUMENTOS OPCIONES PARA EL PROGRAMA


_EOF_
}

# Ejecuta el comando strace con las opciones proporcionadas

STRACE_CMD() {
  # Verificar si se proporcionó un nombre de programa o PID
  if [ -z "$PID_TO_ATTACH" ] && [ -z "$PROGRAM" ]; then
    echo -e "${TEXTBG_RED}${TEXT_BLACK}ERROR:${TEXT_RESET} Debe especificar un PID válido con la opción -nattach o un programa a ejecutar." >&2
    exit 1
  fi

  # Verificar y crear el directorio de salida
  if [ -n "$PROGRAM_NAME" ]; then
    PROG_DIR="$OUTPUT_DIR/$PROGRAM_NAME"
  else
    PROG_DIR="$OUTPUT_DIR/$PROGRAM"
  fi

  if [ ! -d "$PROG_DIR" ]; then
    mkdir -p "$PROG_DIR" || {
      echo -e "${TEXTBG_RED}${TEXT_BLACK}ERROR:${TEXT_RESET} No se pudo crear el directorio de salida: $PROG_DIR" >&2
      exit 1
    }
  fi

  UUID=$(GET_UUID)
  TRACE_FILE="$PROG_DIR/trace_$UUID.txt"

  # Construir el comando strace
  STRACE_COMMAND="strace $VERBOSE"
  for arg in "${STRACE_OPTS[@]}"; do
    STRACE_COMMAND="$STRACE_COMMAND $arg"
  done
  STRACE_COMMAND="$STRACE_COMMAND -o $TRACE_FILE"

  if [ -n "$PID_TO_ATTACH" ]; then
    # Adjuntar a un proceso existente
    STRACE_COMMAND="$STRACE_COMMAND -p $PID_TO_ATTACH"
  elif [ -n "$PROGRAM" ]; then
    # Ejecutar un nuevo programa
    STRACE_COMMAND="$STRACE_COMMAND $PROGRAM ${PROGRAM_ARGS[@]}" 
  fi

  # Ejecutar el comando strace
  if ! eval "$STRACE_COMMAND"; then
    echo -e "${TEXTBG_RED}${TEXT_BLACK}ERROR:${TEXT_RESET} Ha ocurrido un error al ejecutar el comando strace" >&2
    exit 1
  fi

  sleep 1
  clear
  echo -e "\n${TEXT_GREEN}¡Trazado completado con éxito!${TEXT_RESET}"
  echo -e "${TEXT_GREEN}La salida de strace se encuentra en:${TEXT_RESET} $TRACE_FILE\n"
  echo -e "${TEXT_GREEN}Resumen de la ejecución:${TEXT_RESET}\n"
  echo -e "${TEXT_GREEN}Comando ejecutado:${TEXT_RESET}\n$STRACE_COMMAND\n"
  echo -e "${TEXT_GREEN}Archivo de traza:${TEXT_RESET} $TRACE_FILE\n"
  echo -e "\n"
}

## FUNCIONES PARA CONSULTAR LA ULTIMA TRAZA DE UN PROGRAMA ESPECIFICO

LASTEST_TRACES() {
  local PROGRAM_NAME="$1"
  local TRACES_DIR="$OUTPUT_DIR/$PROGRAM_NAME"

  if [ ! -d "$TRACES_DIR" ]; then
    echo "${TEXTBG_RED}${TEXT_GREEN}ERROR_NON_FOUND${TEXT_RESET}: NO SE HA ENCONTRADO NINGUN ARCHIVO QUE HAGA REFERENCIA A LA TRAZA DE: $PROGRAM_NAME"
    echo -e "\n"
    exit 1
  fi

  if [ "$2" == "unic" ]; then
    LATEST_TRACE_FILE=$(ls -t "$TRACES_DIR" | head -n 1)
    if [ -n "$LATEST_TRACE_FILE" ]; then
      echo "$(center_text "========== COMMAND: ${TEXT_GREEN}$PROGRAM_NAME${TEXT_RESET} ==========")"
      echo "$(center_text "========== TRACE FILE: $LATEST_TRACE_FILE ==========")"
      echo "$(center_text "========== TIME: $TEXT_BLUE$(stat -c %y "$TRACES_DIR/$LATEST_TRACE_FILE")$TEXT_RESET "==========)"
      echo -e "\n"
      # Muestra el contenido del archivo de traza
      cat "$TRACES_DIR/$LATEST_TRACE_FILE"
      echo -e "\n"
    else
      echo "${TEXTBG_RED}${TEXT_GREEN}ERROR_NON_FOUND${TEXT_RESET}: NO SE HA ENCONTRADO NINGUN ARCHIVO QUE HAGA REFERENCIA A LA TRAZA DE: $PROGRAM_NAME"
      echo -e "\n"
    fi
  elif [ "$2" == "all" ]; then
    TRACE_FILES=$(ls -t "$TRACES_DIR")
    if [ -n "$TRACE_FILES" ]; then
      for TRACE_FILE in $TRACE_FILES; do
        echo "$(center_text "==========COMMAND: ${TEXT_GREEN}$PROGRAM_NAME"${TEXT_RESET}==========)"
        echo "$(center_text "==========TRACE FILE: $TRACE_FILE"==========)"
        echo "$(center_text "==========TIME: ${TEXT_BLUE}$(stat -c %y "$TRACES_DIR/$TRACE_FILE")${TEXT_RESET}"==========)"

        # Muestra el contenido de cada archivo de traza
        cat "$TRACES_DIR/$TRACE_FILE"
        echo -e "\n"
      done
    else
      echo "${TEXTBG_RED}${TEXT_GREEN}ERROR_NON_FOUND${TEXT_RESET}: NO SE HA ENCONTRADO NINGUN ARCHIVO QUE HAGA REFERENCIA A LA TRAZA DE ALGUN PROGRAMA."
      echo "COMPRUEBA QUE HAYA ALGUN ARCHIVO DENTRO DEL DIRECTORIO .SCDEBUG"
      echo -e "\n"
    fi
  fi
}

## FUNCION DEDICADA A MOSTRAR INFORMACION DE LOS PROCESOS TRAZADOS

TRACED_PROCESSES() {
  # LONGITUD TOTAL DE COLUMNAS
  total_length=10+20+15+20

  # CALCULA EL LARGO DEL TITULO
  #title="${TEXT_GREEN}TABLA DE LOS PROCESOS DE ${TEXT_RESET}${USER^^} ${TEXT_GREEN}MAS RECIENTES${TEXT_RESET}"
  #title_length=${#title}

  # VARIABLE SPACES PARA CENTRAR EL TITULO DE LA TABLA
  spaces=$(( (total_length - title_length) / 2 ))

  # IMPRIME ESPACIO Y EL TITULO DE LA TABLA
  echo "            ${TEXT_GREEN}TABLA DE LOS PROCESOS DE ${TEXT_RESET}${USER^^} ${TEXT_GREEN}MAS RECIENTES${TEXT_RESET}"
  echo -e "\n"
  echo "-----------------------------------------------------------------------|"
  printf "%-13s %-20s %-15s %-20s\n" "PID" "Nombre" "PID Trazador" "Nombre del Trazador"
  echo "-----------------------------------------------------------------------|"


  # SE UTILIZA PGREP PARA OBTENER TODOS LOS PROCESOS DEL USUARIO
  if ! pgrep -u $USER > /dev/null; then
    echo "${TEXTBG_RED}${TEXT_GREEN}ERROR:${TEXT_RESET} No se encontraron procesos para el usuario $USER." >&2
    exit 1
  fi

  pgrep -u $USER | while read -r pid; do
    if [ -n "$pid" ]; then
      comm=$(ps -p $pid -o comm=)
      tracer_pid=$(awk '/TracerPid/ {print $2}' "/proc/$pid/status" 2>/dev/null)
      tracer_comm=""

      if [[ $tracer_pid != "0" ]]; then
        tracer_comm=$(ps -p "$tracer_pid" -o comm= | tail -n 1)
      fi

      printf "%-13s %-20s %-15s %-20s\n" "$pid" "$comm" "$tracer_pid" "$tracer_comm"
    fi
  done | sort -k4,4r
  echo "-----------------------------------------------------------------------|"

}

## ======================================================================================================================##
##                                                     APARTADO 4.2                                                      ##
## ======================================================================================================================##

# FUNCION ENCARGADA DE MATAR LOS PROCESOS QUE SE ENCUENTREN BAJO STRACE

KILL_PROCESS() {
  user_pids=($(ps -o pid= -U $USER))

  if [ ${#user_pids[@]} -eq 0 ]; then
    echo "No se encontraron procesos pertenecientes al usuario $USER."
    return
  fi

  killed=0

  for pid in "${user_pids[@]}"; do
    process_name=$(ps -p $pid -o comm=)

    if [ "$process_name" == "strace" ]; then
      # MATA AL PROCESO TRAZADOR Y SU PROCESO TRAZADO
      echo "Terminando proceso trazador (strace) y proceso trazado (sleep) con PID $pid"
      echo -e "\n"
      if kill $pid; then
        echo "Proceso con PID $pid ha sido terminado."
        killed=$((killed + 1))
      else
        echo "No se pudo terminar el proceso con PID $pid."
      fi
    fi
  done

  if [ $killed -eq 0 ]; then
    echo "No se encontraron procesos trazadores (strace) para terminar."
  fi
}

# FUNCION PARA MANEJAR ERRORES EN GENERAL

handle_error() {
  local error_message="$1"
  echo -e "${TEXTBG_RED}${TEXT_BLACK}ERROR: $error_message${TEXT_RESET}" 1>&2  # Mostrar en salida de error
  exit 1
}

# FUNCION PROPPUESTA COMO MODIFICACION 2/11/2023

# La función 'print_traces()' se encarga de listar los directorios dentro de la
# carpeta de trazas '$HOME/.scdebug', mostrando información sobre los archivos
# de traza almacenados en cada uno de ellos de manera organizada.

print_traces() {
  local trace_dir="$HOME/.scdebug"  # Almacena la ruta de la carpeta de trazas.
  
  # Imprime una cabecera informativa.
  
  echo -e "\n"
  echo -e "                         ${TEXT_GREEN}TABLA DE SUBDIRECTORIOS DE LAS TRAZAS EN EL DIRECTORIO SCDEBUG${TEXT_RESET}"
  echo -e "\n"
  echo "|--------------------------------------------------------------------------------------------------------------|"
  echo -e "| DIRECTORIO           |NUM. DE ARCHIVOS | ÚLTIMA MODIFICACIÓN|           FICHERO MÁS RECIENTE                 |"
  echo "|--------------------------------------------------------------------------------------------------------------|"

  # Recorre los subdirectorios de .scdebug
  for dir in "$trace_dir"/*; do
    if [ -d "$dir" ]; then
      num_files=$(find "$dir" -type f | wc -l)
      latest_trace=$(ls -t "$dir" | head -n 1)
      latest_trace_date=$(date -r "$dir/$latest_trace" "+%b %d %H:%M")
      dir_name=$(basename "$dir")
      
      # Imprime información sobre cada subdirectorio en una fila de la tabla.
      printf "| %-20s | %-15s | %-18s | %-20s |\n" "$dir_name" "$num_files" "$latest_trace_date" "$latest_trace"
    fi
  done

  # Imprime un borde inferior para la tabla.
  echo "|--------------------------------------------------------------------------------------------------------------|"
}


## ======================================================================================================================##
##                                                     APARTADO 4.3                                                      ##
## ======================================================================================================================##

# FUNCION AUXILIAR PARA MOSTRAR MENSAJE DE AYUDA PARA LA MONITORIZACION DE PROCESOS

MONITOR_HELP_MSG() {
  cat << _EOF_ 

  AYUDA PARA LA MONITORIZACION DE PROCESOS
  USO DE LA LINEA DE COMANDOS: ${TEXT_GREEN}./scdebug.sh -S PROG [ARG..]{TEXT_RESET} | ${TEXT_GREEN}./scdebug.sh -g | -gc | -ge [-inv]${TEXT_RESET}

  -S          :       EJECUTARA EL SCRIPT CON LA OPCION -S QUE SE ENCARGA DE DETENER EL PROGRAMA QUE SE ESPECIFIQUE Y LO MANTENDRA EN STAND_BY EN LA MEMORIA
  -g          :       MONITORIZARA PROCESOS DETENIDOS CON SALIDA DE STRACE EN ARCHIVOS INDIVIDUALES
  -gc         :       MONITORIZARA PROCESOS DETENIDOS CON SALIDA DE STRACE EN FORMATO TABLA EN ORDEN ASCENDENTE
  -ge         :       MONITORIZARA PROCESOS DETENIDOS CON SALIDA DE STRACE EN FORMATO TABLA EN ORDEN DESCENDENTE
  -inv        :       INVERTIRA EL ORDEN DE LA TABLA DE DATOS (SOLO COMPATIBLE CON ${TEXT_GREEN}-gc${TEXT_RESET} o ${TEXT_GREEN}-ge${TEXT_RESET})
  -h          :       MUESTRA MENSAJE DE AYUDA
  -k          :       MATARA PROCESOS TRAZADORES [STRACE]

_EOF_
}

# FUNCION PARA LA ACCION STOP

stop() {
  # Obtener el comando y sus argumentos
  echo -e "SE HA LLAMADO AL SCRIPT CON LA OPCIÓN -S\n"
  command="$1"
  shift

  echo  -e "SE HA DETENIDO EL COMANDO: ${TEXT_GREEN}$command ${TEXT_RESET}\n"

  # Forzar el nombre de comando
  echo -n "traced_$command" > /proc/$$/comm
  # Detener el script
  kill -SIGSTOP $$

  # Continuar la ejecución con el programa y sus argumentos
  echo -e "\n"
  echo -e "${TEXT_GREEN}Ejecutando el programa:${TEXT_RESET} $command $@\n"
  exec "$command" "$@"
}

# FUNCION PARA LAS OPCIONES -G|-GC|-GE

resume_strace_ge_gc() {
  # SE LOS DATOS REQUERIDOS DE LA SALIDA DE STRACE 
  TABLE_INFO=$(strace -p $1 -c -U name,max-time,total-time,calls,errors 2>&1 & sleep 1 && kill -SIGCONT $1)
  # ALMACENAMOS EN VARIABLES DICHA INFORMACION
  max_time_proccess="$(echo -n "$TABLE_INFO" | awk '{print $2,$1}' | sort -nr |  grep "0,0" | grep -v total | head -n 1 | awk '{print $2}')"
  max_time="$(echo -n "$TABLE_INFO" | awk '{print $2,$1}' | sort -nr |  grep "0,0" | head -n 2 | tail -n 1 | awk '{print $1}')"
  total_time="$(echo -n "$TABLE_INFO" | grep "total" | awk '{print $3}')"
  calls="$(echo -n "$TABLE_INFO" | grep "total" | awk '{print $4}')"
  errors="$(echo -n "$TABLE_INFO" | grep "total" | awk '{print $5}')"
  #CONSTRUIMOS LA TABLA CON LA INFORMACION REQUERIDA
  TABLE_LINE="$max_time_proccess $max_time $total_time $calls $errors
"
}

monitorizar_intento() {
  local option="$1"  # Almacena la opción proporcionada (puede ser '-gc', '-ge', o '-g')
  shift
  # Verificar la opción proporcionada y realizar acciones específicas en función de ella.
  if [ "$option" == "-gc" ]; then
  # Obtener los PIDs de procesos monitoreados con el prefijo 'traced_'.
    RESUME_PIDS=$(ps | grep traced_ | tr -s " " | cut -d " " -f 2) 

  # Comprobar si se encontraron procesos monitoreados.   
    if [ -z "$RESUME_PIDS" ]; then
      echo "No hay ningún proceso monitorizado"
      exit 2
    fi
    for pid in $RESUME_PIDS; do
      resume_strace_ge_gc "$pid"  
      TABLE+="$TABLE_LINE" # Agregar datos de procesos a la tabla.
      sleep 0.1
    done
    sleep 1
    echo -e "\n"
    echo -e "\n"
    echo "========================================================="
    if [ -n "$INV" ]; then
      echo "$TABLE" | sort -k4 -n | column -t --table-columns Max_Time_Proccess,Max_Time,Total_Time,Calls,Errors
    else 
      echo "$TABLE" | sort -k4 -nr | column -t --table-columns Max_Time_Proccess,Max_Time,Total_Time,Calls,Errors
    fi
    echo
    exit $?
  elif [ "$option" == "-ge" ]; then
    # El flujo es similar al caso anterior ('-gc') con diferencias en la ordenacion de la tabla.
    RESUME_PIDS=$(ps | grep traced_ | tr -s " " | cut -d " " -f 2)
    if [ -z "$RESUME_PIDS" ]; then
      echo "No hay ningún proceso monitorizado"
      exit 2
    fi

    for pid in $RESUME_PIDS; do
      resume_strace_ge_gc "$pid"  # Asegúrate de tener una función llamada resume_strace_ge_gc que procesa el pid como lo necesitas
      TABLE+="$TABLE_LINE"
      sleep 0.1
    done
    sleep 1
    echo -e "\n"
    echo -e "\n"
    echo "========================================================="
    if [ -n "$INV" ]; then
      echo "$TABLE" | sort -k5 -n | column -t --table-columns Max_Time_Proccess,Max_Time,Total_Time,Calls,Errors
    else 
      echo "$TABLE" | sort -k5 -nr | column -t --table-columns Max_Time_Proccess,Max_Time,Total_Time,Calls,Errors
    fi
    echo
    exit $?

  elif [ "$option" == "-g" ]; then
# Opción '-g': Monitoreo de procesos en modo normal.
    echo -e "OPCION SELECCIONADA [-G] MONITORIZACION EN MODO RESUMEN [GUARDAR ARCHIVOS INDIVIDUALES EN SCDEBUG DE LA LA SALIDA DE STRACE.]\n"

    STOPPED_PROCESSES=$(ps | grep traced_ | tr -s ' ' | cut -d ' ' -f2 | tr -s '\n' ' ')

    for pid in $STOPPED_PROCESSES; do
      UUID=$(uuidgen)
      TRACE_FILE="$HOME/.scdebug/trace_$UUID.txt"

      strace -f -o "$TRACE_FILE" -p $pid > /dev/null 2>&1 &
      sleep 0.1
      kill -SIGCONT $pid
      wait
    done

    echo -e "\n"
    echo -e "Se han reanudado los procesos\n"
    echo -e "El resultado de la traza se encuentra en la siguiente ruta: ${TEXT_GREEN}$TRACE_FILE${TEXT_RESET}\n"
  else
    echo -e "${TEXTBG_RED}${TEXT_GREEN}WRONG_COMMAND:${TEXT_RESET}OPPS LA OPCION QUE INGRESASTE NO ES CORRECTA\n"
    MONITOR_HELP_MSG
  fi
}

#=====================================================================================================================================#
#                                                        PROGRAMA PRINCIAL                                                            #
#=====================================================================================================================================#

## MENSAJE DE BIENVENIDA AL INICAR EL SCRIPT

cat << _EOF_

              SCRIPT SCDEBUG PARA LA TRAZA DE LLAMADAS AL SISTEMAS
                            DE PROGRAMAS CON STRACE
      
                          DISEÑADO POR: ${TEXT_GREEN}alu0101604077${TEXT_RESET}
                $TEXT_GREEN$TIME_STAMP$TEXT_RESET

_EOF_

## BUCLE WHILE PARA PODER PROCESAR LA LINEA DE COMANDO

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      HELP_MSG
      shift
      ;;
    -sto)
      shift
      # PERMITE QUE STO ADMITA MULTIPLES ARGUMENTOS
      STRACE_OPTS=("${STRACE_OPTS[@]}" $1)
      ;;
    -nattch)
      shift
      while [ -n "$1" ]; do
        if [[ "$1" =~ ^[0-9]+$ ]]; then
          PID_TO_ATTACH="$1"
        else
          PROGRAM_NAME="$1"
          PID_TO_ATTACH=$(pgrep -o "$PROGRAM_NAME")
        fi

        if [ -n "$PID_TO_ATTACH" ]; then
          echo -e "EL PROCESO DE NATTCH EMPEZARA EN BREVE.\n"
          STRACE_CMD &

          while ps -p $! > /dev/null; do
            echo -e "EL -NATTCH ESTA EN PROCESO DE EJECUCION."
            sleep 10
          done
          echo "PROCESO FINALIZADO CORRECTAMENTE."
          echo -e "\n"
          echo -e "\n"
        else
          echo "${TEXTBG_RED}${TEXT_GREEN}ERROR_INVALID_PID${TEXT_RESET}No se encontró un proceso con el nombre de comando o PID: $1"
        fi

        shift
      done
      sleep 1.5
      TRACED_PROCESSES
      echo -e "\n"
      print_traces
      ;;
    -v)
      shift
      PROGRAM="$1"
      LASTEST_TRACES "$PROGRAM" "unic"
      ;;
    -vall)
      shift
      LASTEST_TRACES "$1" "all"
      ;;
    -k)
      shift
      KILL_PROCESS
      echo -e "\n"
      TRACED_PROCESSES
      sleep 0.5
      print_traces
      ;;
    -pattch)
      shift
      pids_to_attach=()
      while [ -n "$1" ] && ! [[ "$1" == -* ]]; do
          if [[ "$1" =~ ^[0-9]+$ ]]; then
              pids_to_attach+=("$1")
          else
              echo "${TEXTBG_RED}${TEXT_GREEN}ERROR_INVALID_PID${TEXT_RESET}: NO SE HA PROPORCIONADO UN PID VÁLIDO: $1" >&2
              echo -e "\n"
          fi
          shift
      done

      if [ "${#pids_to_attach[@]}" -gt 0 ]; then
          for pid in "${pids_to_attach[@]}"; do
              if [ -d "/proc/$pid" ]; then
                  program_name=$(ps -o comm= -p "$pid")
                  if [ -n "$program_name" ]; then
                      UUID=$(GET_UUID)
                      STRACE_COMMAND="strace $VERBOSE"
                      for arg in "${STRACE_OPTS[@]}"; do
                          STRACE_COMMAND="$STRACE_COMMAND $arg"
                      done
                      STRACE_COMMAND="$STRACE_COMMAND -o $OUTPUT_DIR/trace_${program_name}_$UUID.txt -p $pid"
                      eval "$STRACE_COMMAND" || {
                          echo "${TEXTBG_RED}${TEXT_GREEN}ERROR_STRACE${TEXT_RESET}: Ha ocurrido un error al ejecutar el comando strace para el PID: $pid" >&2
                          echo -e "\n"
                      }
                      echo "Haciendo attach al proceso $program_name (PID: ${TEXTBG_RED}${TEXT_GREEN}$pid${TEXT_RESET}) en segundo plano."
                      echo -e "\n"
                      echo "El archivo de traza se encuentra en la siguiente dirección: ${TEXT_GREEN}$OUTPUT_DIR/trace_${program_name}_$UUID.txt${TEXT_RESET}"
                      echo -e "\n"
                  else
                      echo "${TEXTBG_RED}${TEXT_GREEN}ERROR_INVALID_PID${TEXT_RESET}: No se encontró ningún proceso en ejecución con el PID: $pid"
                      echo -e "\n"
                  fi
              else
                  echo "${TEXTBG_RED}${TEXT_GREEN}ERROR_INVALID_PID${TEXT_RESET}: No se encontró ningún proceso en ejecución con el PID: $pid"
                  echo -e "\n"
              fi
          done
      else
          echo "${TEXTBG_RED${TEXT_GREEN}}ERROR_INVALID_PID${TEXT_RESET}: No se proporcionaron PIDs válidos para monitorear." >&2
          echo -e "\n"
      fi
      echo -e "\n"
      TRACED_PROCESSES
      sleep 0.5
      print_traces
      ;;
    -S)
      if [ "$2" == "" ]; then
        echo -e "${TEXTBG_RED}WRONG_COMMAND_LINE:${TEXT_RESET} PARECE SER QUE NO HAS INDICADO UN PROGRAMA DESPUES DE -S\nTE DEJO LA AYUDA PARA QUE TE GUIES\n"
        MONITOR_HELP_MSG
        exit 1
      fi
      stop "$2" "${@:3}"
      ;;
    -g|-gc|-ge)
      if [ "$2" == "-h" ] || [ "$2" == "-k" ]; then
        monitorizar_intento "$1" "$2"
        shift 2
      elif [ "$#" -eq 1 ]; then
        monitorizar_intento "$1"
        shift  
      else
        echo "Las opciones $1, $2 solo se pueden combinar con -h o -k. Consulta la ayuda para obtener más información."
               
      fi
      ;;
    *)
      PROGRAM="$1"
      shift
      PROGRAM_ARGS=("$@")
      STRACE_CMD

      echo -e "\n"
      TRACED_PROCESSES
      sleep 0.5
      print_traces
      ;;
  esac
  shift
done

## ======================================================================================================================##
##                                               FINAL DEL SCRIPT                                                        ##
## ======================================================================================================================##