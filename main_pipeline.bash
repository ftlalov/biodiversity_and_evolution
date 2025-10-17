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
archivo_muestras2=$archivo_muestras
declare -A arreglo_fastq


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
    echo "$config_seq"
    if [[ $config_seq == "SE" ]];then
       # creador de la matriz de tratamiento y ubicación
            while read -r condicion r1; do
            if [[ ! -z "$condicion" && ! -z "$r1" ]]; then
                arreglo_fastq["$condicion"]=$r1
            else
                echo "No se logró procesar el archivo de muestras"
                echo "Favor de ingresar un archivo valido"
                exit 1
            fi
        
        done < <(awk 'NF{print $1 "\t" $2}' "$archivo_muestras")

        echo "Se encontraron las siguientes muestras"
        echo "${!arreglo_fastq[@]}"
        echo "${arreglo_fastq[@]}"

        ## Ciclo para revisar el tamaño de los archivos para validar su existencia y que no esten vacios
        for condicion in "${!arreglo_fastq[@]}"; do
            fastq_path="${arreglo_fastq[$condicion]}"
             
            echo -n "Revizando el archivo ${condicion} "  
            if [[ -f $fastq_path  ]]; then 
                size_b=$( du -b "$fastq_path" | awk '{print $1}')
                echo "$size_b"
                if [ "$size_b" -gt 0 ]; then  ## revisa si es diferente de 0
                    size_human=$(numfmt --to=iec --suffix=B --format='%.2f' $size_b 2>/dev/null || echo "$size_b Bytes")
                    echo "La condicion $condicion tuvo un tamaño de $size_human" 
                else 
                    echo "El archivo de la condición $condicion esta vacio"
                    echo "Favor de revizar el archivo o la ruta"
                fi               
            else 
                echo "Para la $condicion No se encuentra la dirección del siguiente archivo $fastq_path "  
                echo "Corregir y volver a ingresar archivos"
            fi
        done

    elif [[ $config_seq == "PE" ]];then 
        DELIMITADOR="@"
        ##creador de la matriz
        while read -r condicion R1 R2 ; do
            if [[ ! -z "$condicion" && ! -z "$R1" && ! -z "$R2" ]]; then #revisar que el archivo no esta vacio 
                arreglo_fastq["$condicion"]="${R1}${DELIMITADOR}${R2}"
            else 
                echo "Error de formato, introducir de esta manera"    
                echo "Identificador R1.fastq.gz R2.fastq.gz "
                echo "Favor de ingresar un archivo valido"
                exit 1
            fi    

        done < <(awk 'NF{print $1 "\t" $2 "\t" $3}' "$archivo_muestras")
        for condicion in "${!arreglo_fastq[@]}"; do
              R1_R2_PATHS="${arreglo_fastq[$condicion]}"
              #echo "$R1_R2_PATHS"
            IFS="${DELIMITADOR}" read -r path_R1 path_R2 <<< "$R1_R2_PATHS" 
            #echo "$path_R1"
            #echo "$path_R2"
            if [[ -f "$path_R1" && -f "$path_R2" ]]; then
                
                R2_size_b=$( du -b "$path_R2" | awk '{print $1}')
                R1_size_b=$( du -b "$path_R1" | awk '{print $1}')
                #echo "$R1_size_b"
                #echo "$R2_size_b"
                if [[ "$R1_size_b" -gt 0  && "$R2_size_b" -gt 0  ]]; then  ## revisa si es diferente de 0
                    R1size_human=$(numfmt --to=iec --suffix=B --format='%.2f' $R1_size_b 2>/dev/null || echo "$R1_size_b Bytes")
                    R2size_human=$(numfmt --to=iec --suffix=B --format='%.2f' $R2_size_b 2>/dev/null || echo "$R2_size_b Bytes")
                    echo "La condicion $condicion tuvo dos lecturasm, con los siguientes tamaños"
                    echo "Lectura R1 $R1size_human"
                    echo "lectura R2 $R2size_human" 

                    echo "Continuando al menu de selección de metodología"
                else 
                    echo "Almenos uno de los archivos de la $condicion esta vacio"
                    echo "Favor de revizar el archivo o la ruta"
                fi               
            else 
                echo "Para la $condicion no se encuentra la ruta de almenos uno de los archivos "  
                echo "Corregir y volver a ingresar archivos"
            fi
        done 



    fi        
}

verificar_datos
seleccionar_tipo_metagenoma

####### esqueleto principal 

if [[ $a -eq 1 ]]; then 
        echo "Iniciando para metagenoma 16S/18S"
#        bash enviroment_verification.bash
        echo "se Ha completado la verificación"
        bash reads_preprocess.bash "$config_seq" "$archivo_muestras2"
        bash 16s.bash "$config_seq"
    elif [[ $a -eq 2 ]]; then 
        echo "Iniciando para metagenoma Shotgun"
#        bash enviroment_verification.bash
        echo "se Ha completado la verificación"
        bash reads_preprocess.bash "$config_seq" "$archivo_muestras2"
        bash shotgun.bash "$config_seq"

    fi










