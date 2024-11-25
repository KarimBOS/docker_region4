#!/bin/bash

bldred='\033[1;31m' # Bold Red / Rojo Negrita
bldgrn='\033[1;32m' # Bold Green / Verde Negrita
bldblu='\033[1;34m' # Bold Blue / Azul Negrita
bldylw='\033[1;33m' # Bold Yellow / Amarillo Negrita
txtrst='\033[0m' # Text Reset / Restablecer texto

if [ -n "$nocolor" ] && [ "$nocolor" = "nocolor" ]; then
  bldred='' # Disable Red / Desactivar Rojo
  bldgrn='' # Disable Green / Desactivar Verde
  bldblu='' # Disable Blue / Desactivar Azul
  bldylw='' # Disable Yellow / Desactivar Amarillo
  txtrst='' # Disable Text Reset / Desactivar Restablecimiento de Texto
fi

logit () {
  printf "%b\n" "$1" | tee -a "$logger" # Log a message / Registrar un mensaje
}

info () {
  local infoCountCheck
  local OPTIND c
  while getopts c args
  do
    case $args in
    c) infoCountCheck="true" ;; # Check for count / Verificar por cuenta
    *) exit 1 ;;
    esac
  done
  if [ "$infoCountCheck" = "true" ]; then
    printf "%b\n" "${bldblu}[INFO]${txtrst} $2" | tee -a "$logger" # Info message with count / Mensaje de info con cuenta
    totalChecks=$((totalChecks + 1)) # Increment total checks / Incrementar total de verificaciones
    return
  fi
  printf "%b\n" "${bldblu}[INFO]${txtrst} $1" | tee -a "$logger" # Regular info message / Mensaje de información regular
}

pass () {
  local passScored
  local passCountCheck
  local OPTIND s c
  while getopts sc args
  do
    case $args in
    s) passScored="true" ;; # Check if scored / Verificar si puntuado
    c) passCountCheck="true" ;; # Check for count / Verificar por cuenta
    *) exit 1 ;;
    esac
  done
  if [ "$passScored" = "true" ] || [ "$passCountCheck" = "true" ]; then
    printf "%b\n" "${bldgrn}[PASS]${txtrst} $2" | tee -a "$logger" # Pass message with count / Mensaje de pase con cuenta
    totalChecks=$((totalChecks + 1)) # Increment total checks / Incrementar total de verificaciones
  fi
  if [ "$passScored" = "true" ]; then
    currentScore=$((currentScore + 1)) # Increment score / Incrementar puntuación
  fi
  if [ "$passScored" != "true" ] && [ "$passCountCheck" != "true" ]; then
    printf "%b\n" "${bldgrn}[PASS]${txtrst} $1" | tee -a "$logger" # Regular pass message / Mensaje de pase regular
  fi
}

warn () {
  local warnScored
  local OPTIND s
  while getopts s args
  do
    case $args in
    s) warnScored="true" ;; # Check if scored / Verificar si puntuado
    *) exit 1 ;;
    esac
  done
  if [ "$warnScored" = "true" ]; then
    printf "%b\n" "${bldred}[WARN]${txtrst} $2" | tee -a "$logger" # Warning message with score / Mensaje de advertencia con puntuación
    totalChecks=$((totalChecks + 1)) # Increment total checks / Incrementar total de verificaciones
    currentScore=$((currentScore - 1)) # Decrease score / Reducir puntuación
    return
  fi
  printf "%b\n" "${bldred}[WARN]${txtrst} $1" | tee -a "$logger" # Regular warning message / Mensaje de advertencia regular
}

note () {
  local noteCountCheck
  local OPTIND c
  while getopts c args
  do
    case $args in
    c) noteCountCheck="true" ;; # Check for count / Verificar por cuenta
    *) exit 1 ;;
    esac
  done
  if [ "$noteCountCheck" = "true" ]; then
    printf "%b\n" "${bldylw}[NOTE]${txtrst} $2" | tee -a "$logger" # Note message with count / Mensaje de nota con cuenta
    totalChecks=$((totalChecks + 1)) # Increment total checks / Incrementar total de verificaciones
    return
  fi
  printf "%b\n" "${bldylw}[NOTE]${txtrst} $1" | tee -a "$logger" # Regular note message / Mensaje de nota regular
}

yell () {
  printf "%b\n" "${bldylw}$1${txtrst}\n" # Yell message / Mensaje de advertencia
}

beginjson () {
  printf "{\n  \"dockerbenchsecurity\": \"%s\",\n  \"start\": %s,\n  \"tests\": [" "$1" "$2" | tee "$logger.json" 2>/dev/null 1>&2 # Begin JSON log / Comenzar registro en formato JSON
}

endjson () {
  printf "\n  ],\n  \"checks\": %s,\n  \"score\": %s,\n  \"end\": %s\n}" "$1" "$2" "$3" | tee -a "$logger.json" 2>/dev/null 1>&2 # End JSON log / Finalizar registro en formato JSON
}

logjson () {
  printf "\n  \"%s\": \"%s\"," "$1" "$2" | tee -a "$logger.json" 2>/dev/null 1>&2 # Log JSON data / Registrar datos en JSON
}

SSEP=
SEP=
startsectionjson() {
  printf "%s\n    {\n      \"id\": \"%s\",\n      \"desc\": \"%s\",\n      \"results\": [" "$SSEP" "$1" "$2" | tee -a "$logger.json" 2>/dev/null 1>&2 # Start section in JSON / Comenzar sección en JSON
  SEP=
  SSEP=","
}

endsectionjson() {
  printf "\n      ]\n    }" | tee -a "$logger.json" 2>/dev/null 1>&2 # End section in JSON / Finalizar sección en JSON
}

starttestjson() {
  printf "%s\n        {\n          \"id\": \"%s\",\n          \"desc\": \"%s\",\n          " "$SEP" "$1" "$2" | tee -a "$logger.json" 2>/dev/null 1>&2 # Start test in JSON / Comenzar prueba en JSON
  SEP=","
}

log_to_json() {
  if [ $# -eq 1 ]; then
    printf "\"result\": \"%s\"" "$1" | tee -a "$logger.json" 2>/dev/null 1>&2 # Log result in JSON / Registrar resultado en JSON
    return
  fi
  if [ $# -eq 2 ] && [ $# -ne 1 ]; then
    printf "\"result\": \"%s\",\n          \"details\": \"%s\"" "$1" "$2" | tee -a "$logger.json" 2>/dev/null 1>&2 # Log result and details in JSON / Registrar resultado y detalles en JSON
    return
  fi
  truncItems=$3
  if [ "$limit" != 0 ]; then
    truncItems=""
    ITEM_COUNT=0
    for item in $3; do
      truncItems="$truncItems $item"
      ITEM_COUNT=$((ITEM_COUNT + 1))
      if [ "$ITEM_COUNT" == "$limit" ]; then
        truncItems="$truncItems (truncated)" # Truncate items if limit reached / Truncar elementos si se alcanza el límite
        break;
      fi
    done
  fi
  itemsJson=$(printf "[\n            "; ISEP=""; ITEMCOUNT=0; for item in $truncItems; do printf "%s\"%s\"" "$ISEP" "$item"; ISEP=","; done; printf "\n          ]")
  printf "\"result\": \"%s\",\n          \"details\": \"%s: %s\",\n          \"items\": %s" "$1" "$2" "$truncItems" "$itemsJson" | tee -a "$logger.json" 2>/dev/null 1>&2 # Log result, details, and items in JSON / Registrar resultado, detalles y elementos en JSON
}

logcheckresult() {
  log_to_json "$@" # Log check result to JSON / Registrar resultado de verificación en JSON

  # Log remediation in JSON if available / Registrar remediación en JSON si está disponible
  if [ -n "$remediation" ] && [ "$1" != "PASS" ] && [ "$printremediation" =Aquí tienes el script actualizado con los comentarios en inglés junto a sus traducciones al español:

```bash
#!/bin/bash

bldred='\033[1;31m' # Bold Red / Rojo Negrita
bldgrn='\033[1;32m' # Bold Green / Verde Negrita
bldblu='\033[1;34m' # Bold Blue / Azul Negrita
bldylw='\033[1;33m' # Bold Yellow / Amarillo Negrita
txtrst='\033[0m' # Text Reset / Restablecer texto

if [ -n "$nocolor" ] && [ "$nocolor" = "nocolor" ]; then
  bldred='' # Disable Red / Desactivar Rojo
  bldgrn='' # Disable Green / Desactivar Verde
  bldblu='' # Disable Blue / Desactivar Azul
  bldylw='' # Disable Yellow / Desactivar Amarillo
  txtrst='' # Disable Text Reset / Desactivar Restablecimiento de Texto
fi

logit () {
  printf "%b\n" "$1" | tee -a "$logger" # Log a message / Registrar un mensaje
}

info () {
  local infoCountCheck
  local OPTIND c
  while getopts c args
  do
    case $args in
    c) infoCountCheck="true" ;; # Check for count / Verificar por cuenta
    *) exit 1 ;;
    esac
  done
  if [ "$infoCountCheck" = "true" ]; then
    printf "%b\n" "${bldblu}[INFO]${txtrst} $2" | tee -a "$logger" # Info message with count / Mensaje de info con cuenta
    totalChecks=$((totalChecks + 1)) # Increment total checks / Incrementar total de verificaciones
    return
  fi
  printf "%b\n" "${bldblu}[INFO]${txtrst} $1" | tee -a "$logger" # Regular info message / Mensaje de información regular
}

pass () {
  local passScored
  local passCountCheck
  local OPTIND s c
  while getopts sc args
  do
    case $args in
    s) passScored="true" ;; # Check if scored / Verificar si puntuado
    c) passCountCheck="true" ;; # Check for count / Verificar por cuenta
    *) exit 1 ;;
    esac
  done
  if [ "$passScored" = "true" ] || [ "$passCountCheck" = "true" ]; then
    printf "%b\n" "${bldgrn}[PASS]${txtrst} $2" | tee -a "$logger" # Pass message with count / Mensaje de pase con cuenta
    totalChecks=$((totalChecks + 1)) # Increment total checks / Incrementar total de verificaciones
  fi
  if [ "$passScored" = "true" ]; then
    currentScore=$((currentScore + 1)) # Increment score / Incrementar puntuación
  fi
  if [ "$passScored" != "true" ] && [ "$passCountCheck" != "true" ]; then
    printf "%b\n" "${bldgrn}[PASS]${txtrst} $1" | tee -a "$logger" # Regular pass message / Mensaje de pase regular
  fi
}

warn () {
  local warnScored
  local OPTIND s
  while getopts s args
  do
    case $args in
    s) warnScored="true" ;; # Check if scored / Verificar si puntuado
    *) exit 1 ;;
    esac
  done
  if [ "$warnScored" = "true" ]; then
    printf "%b\n" "${bldred}[WARN]${txtrst} $2" | tee -a "$logger" # Warning message with score / Mensaje de advertencia con puntuación
    totalChecks=$((totalChecks + 1)) # Increment total checks / Incrementar total de verificaciones
    currentScore=$((currentScore - 1)) # Decrease score / Reducir puntuación
    return
  fi
  printf "%b\n" "${bldred}[WARN]${txtrst} $1" | tee -a "$logger" # Regular warning message / Mensaje de advertencia regular
}

note () {
  local noteCountCheck
  local OPTIND c
  while getopts c args
  do
    case $args in
    c) noteCountCheck="true" ;; # Check for count / Verificar por cuenta
    *) exit 1 ;;
    esac
  done
  if [ "$noteCountCheck" = "true" ]; then
    printf "%b\n" "${bldylw}[NOTE]${txtrst} $2" | tee -a "$logger" # Note message with count / Mensaje de nota con cuenta
    totalChecks=$((totalChecks + 1)) # Increment total checks / Incrementar total de verificaciones
    return
  fi
  printf "%b\n" "${bldylw}[NOTE]${txtrst} $1" | tee -a "$logger" # Regular note message / Mensaje de nota regular
}

yell () {
  printf "%b\n" "${bldylw}$1${txtrst}\n" # Yell message / Mensaje de advertencia
}

beginjson () {
  printf "{\n  \"dockerbenchsecurity\": \"%s\",\n  \"start\": %s,\n  \"tests\": [" "$1" "$2" | tee "$logger.json" 2>/dev/null 1>&2 # Begin JSON log / Comenzar registro en formato JSON
}

endjson () {
  printf "\n  ],\n  \"checks\": %s,\n  \"score\": %s,\n  \"end\": %s\n}" "$1" "$2" "$3" | tee -a "$logger.json" 2>/dev/null 1>&2 # End JSON log / Finalizar registro en formato JSON
}

logjson () {
  printf "\n  \"%s\": \"%s\"," "$1" "$2" | tee -a "$logger.json" 2>/dev/null 1>&2 # Log JSON data / Registrar datos en JSON
}

SSEP=
SEP=
startsectionjson() {
  printf "%s\n    {\n      \"id\": \"%s\",\n      \"desc\": \"%s\",\n      \"results\": [" "$SSEP" "$1" "$2" | tee -a "$logger.json" 2>/dev/null 1>&2 # Start section in JSON / Comenzar sección en JSON
  SEP=
  SSEP=","
}

endsectionjson() {
  printf "\n      ]\n    }" | tee -a "$logger.json" 2>/dev/null 1>&2 # End section in JSON / Finalizar sección en JSON
}

starttestjson() {
  printf "%s\n        {\n          \"id\": \"%s\",\n          \"desc\": \"%s\",\n          " "$SEP" "$1" "$2" | tee -a "$logger.json" 2>/dev/null 1>&2 # Start test in JSON / Comenzar prueba en JSON
  SEP=","
}

log_to_json() {
  if [ $# -eq 1 ]; then
    printf "\"result\": \"%s\"" "$1" | tee -a "$logger.json" 2>/dev/null 1>&2 # Log result in JSON / Registrar resultado en JSON
    return
  fi
  if [ $# -eq 2 ] && [ $# -ne 1 ]; then
    printf "\"result\": \"%s\",\n          \"details\": \"%s\"" "$1" "$2" | tee -a "$logger.json" 2>/dev/null 1>&2 # Log result and details in JSON / Registrar resultado y detalles en JSON
    return
  fi
  truncItems=$3
  if [ "$limit" != 0 ]; then
    truncItems=""
    ITEM_COUNT=0
    for item in $3; do
      truncItems="$truncItems $item"
      ITEM_COUNT=$((ITEM_COUNT + 1))
      if [ "$ITEM_COUNT" == "$limit" ]; then
        truncItems="$truncItems (truncated)" # Truncate items if limit reached / Truncar elementos si se alcanza el límite
        break;
      fi
    done
  fi
  itemsJson=$(printf "[\n            "; ISEP=""; ITEMCOUNT=0; for item in $truncItems; do printf "%s\"%s\"" "$ISEP" "$item"; ISEP=","; done; printf "\n          ]")
  printf "\"result\": \"%s\",\n          \"details\": \"%s: %s\",\n          \"items\": %s" "$1" "$2" "$truncItems" "$itemsJson" | tee -a "$logger.json" 2>/dev/null 1>&2 # Log result, details, and items in JSON / Registrar resultado, detalles y elementos en JSON
}

logcheckresult() {
  log_to_json "$@" # Log check result to JSON / Registrar resultado de verificación en JSON

  # Log remediation in JSON if available / Registrar remediación en JSON si está disponible
  if [ -n "$remediation" ] && [ "$1" != "PASS" ] && [ "$printremediation" =The script you provided is a Bash script designed for logging and formatting messages in different colors and styles, with support for both regular output and JSON output. It has functions to log different levels of messages, including `info`, `warn`, `pass`, and `note`, each with options to track counts and scores.

Here is an explanation of key parts of the script:

- **Color Setup**: 
  - The script defines color variables (e.g., `bldred`, `bldgrn`, etc.) for different message types. These are used to make messages visually distinct in the terminal.
  
- **Log Functions**:
  - `logit`: Logs a message to the console and a log file.
  - `info`, `warn`, `pass`, and `note`: These are used to log messages with different levels of importance (info, warning, success, and notes). Each of these functions can output messages in specific colors and can track the count of messages or the score of a test.
  - `yell`: Logs a message in yellow text.
  
- **JSON Logging**:
  - Functions like `beginjson`, `endjson`, and `logjson` are used to structure log data in JSON format, which could be useful for integrating with other systems or tools that process JSON.

- **Checks and Score Tracking**:
  - The script includes logic to track the number of checks and scores. For example, passing tests increment the score, while warnings reduce the score.

- **Flexible Output**:
  - There are multiple conditional checks in each function to handle different logging scenarios, including counts, scores, and whether to include additional details.

This script would be useful in a scenario where you are running automated tests or security checks and want to log both human-readable messages and machine-readable JSON output for later analysis or integration. The inclusion of color makes it easy to spot the status of tests in the terminal, while the JSON structure can be used for further automation or reporting.

Let me know if you'd like to focus on any specific part of the script or have any further questions!
