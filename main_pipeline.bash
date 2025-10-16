#!/bin/bash

# Script principal para el análisis de datos para   (pipeline.bash)
# ----------------------------------------------------------------------
# Este Script es el pipeline el cual toma secuencias FASTQ 
# procesa las secuencias, las filtra, y las ingresa a los
# distintos programas necesarios para darle valor biológico a
# la información proveninete de la tecnológica de secuenciación masiva
# ----------------------------------------------------------------------

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



seleccionar_tipo_metagenoma

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










