#!/bin/bash

# Script principal para el análisis de datos para   (pipeline.bash)
# ----------------------------------------------------------------------
# Este Script es el pipeline el cual toma secuencias FASTQ 
# procesa las secuencias, las filtra, y las ingresa a los
# distintos programas necesarios para darle valor biológico a
# la información proveninete de la tecnológica de secuenciación masiva
# ----------------------------------------------------------------------
config_seq=$1
archivo_muestras="$2"
declare -A archivos


##Filtro de datos necesarios para acceder al script
if [ -z "$1" ]; then
    echo "Error, Debe especificar el tipo de lectura (PE o SE) como primer argumento." >&2
    echo "Uso: $0 [PE|SE] [archivo_muestras]" >&2
    exit 1
fi
config_seq=$(echo "$1" | tr '[:lower:]' '[:upper:]')
if [[ "$config_seq" != "PE" && "$config_seq" != "SE" ]]; then
    echo " Error: El tipo de lectura proporcionado ('$1') no es válido." >&2
    echo "   Solo se permiten 'PE' (Paired-End) o 'SE' (Single-End)." >&2
    exit 1
fi

if [ -z "$2" ]; then
    echo "Es necesario ejecutar con el archivo de muestras"
    echo "Este debe contener el nombre de las muestras"
    echo "junto con la/las rutas absolutas de los FASTQ"
    echo "Uso: $0 [PE|SE] [archivo_muestras]"
    exit 1
fi

 # Función para la selección del tipo de metagenoma
seleccionar_tipo_metagenoma() {
    echo "--- Paso 1: Selección del Tipo de Metagenoma ---"
    PS3="Selecciona el tipo de análisis (1, 2, 3): "
    options=("Amplicon (16S/18S)" "Shotgun (Whole Genome Shootgun)" "Salir")
    select opt in "${options[@]}"; do
        case $opt in
            "Amplicon (16S/18S)")
                METAGENOMA_TIPO="amplicon"
                echo "Seleccionado: Metagenoma de Amplicon (16S/ITS)."
                a=1
                break
                ;;
            "Shotgun (Whole Genome Shootgun)")
                METAGENOMA_TIPO="shotgun"
                echo "Seleccionado: Metagenoma de Shotgun (WGS)."
                a=2
                break
                ;;
            "Salir")
                echo "Saliendo del programa."
                exit 0
                ;;
            *) echo "Opción inválida $REPLY";;
        esac
    done
}

verificar_datos() {
   echo "$archivo_muestras"
   while read -r ALIAS FILE_PATH; do
        if [[ ! -z "$ALIAS" && ! -z "$FILE_PATH" ]]; then
            FILES["$ALIAS"]="$FILE_PATH"
        fi
    done < <(awk 'NF{print $1 "\t" $2}' "$SAMPLE_MAPPING_FILE")

}

verificar_datos
#seleccionar_tipo_metagenoma

####### esqueleto principal 

if [[ $a -eq 1 ]]; then 
        echo "Iniciando para metagenoma 16S/18S"
        bash enviroment_verification.bash
        echo "se Ha completado la verificación"

    elif [[ $a -eq 2 ]]; then 
        echo "Iniciando para metagenoma Shotgun"
        bash enviroment_verification.bash
        echo "se Ha completado la verificación"


    fi










