#!/bin/bash
###################
# Prgroma para el preproseamiento de lecturas, se requieren las lecturas
# 
#
###################
config_seq=$1
archivo_muestras=$2
archivo_muestras2=$archivo_muestras
declare -A arreglo_fastq

###exportar conda por si no esta en el path 
export PATH="$HOME/miniconda1/bin:$PATH"
export PATH="$HOME/miniconda2/bin:$PATH"
export PATH="$HOME/miniconda3/bin:$PATH"
export PATH="$HOME/anaconda1/bin:$PATH"
export PATH="$HOME/anaconda2/bin:$PATH"
export PATH="$HOME/anaconda3/bin:$PATH"

echo "iniciando pre procesamiento de las lecturas"

echo "$config_seq"
echo "$archivo_muestras"




### Inicio del script
    source $HOME/miniconda3/etc/profile.d/conda.sh
    conda activate biodiversity_and_evolution_p1
    mkdir -p temp/
    rm -rf temp/*

    muestras_trim="temp/new_samplefile.txt"
    >"$muestras_trim"

    if [[ $config_seq == "SE" ]];then
       # creador de la matriz de tratamiento y ubicación
        while read -r condicion r1; do
        if [[ ! -z "$condicion" && ! -z "$r1" ]]; then
            arreglo_fastq["$condicion"]="$r1"
        else
            echo "No se logró procesar el archivo de muestras"
            echo "Favor de ingresar un archivo valido"
            exit 1
        fi
        
        done < <(awk 'NF{print $1 "\t" $2}' "$archivo_muestras2")

        #echo "Se encontraron las siguientes muestras"
        #echo "${!arreglo_fastq[@]}"
        
       
        ## Ciclo para revisar el tamaño de los archivos para validar su existencia y que no esten vacios
        for condicion in "${!arreglo_fastq[@]}"; do
            fastq_path="${arreglo_fastq[$condicion]}"
             
            echo -n "Revizando el archivo ${condicion} "  
            if [[ -f $fastq_path  ]]; then 
                size_b=$( du -b "$fastq_path" | awk '{print $1}')
                if [ "$size_b" -gt 0 ]; then  ## revisa si es diferente de 0
######################## preprocesamiento de las lecturas SE    
                    trim_galore --basename $condicion $fastq_path --length 30 --gzip --output_dir temp/  
                    #size_human=$(numfmt --to=iec --suffix=B --format='%.2f' $size_b 2>/dev/null || echo "$size_b Bytes")
                    #echo "La condicion $condicion tuvo un tamaño de $size_human" 
                    cat $fastq_path >> temp/all_merged.fq.gz
                    ### nuevo archivo de muestras
                    fq_trim_path="temp/${condicion}_trimmed.fq.gz"
                    echo "${condicion},$(realpath "$fq_trim_path")" >> "$muestras_trim"
                    cat $fq_trim_path >> temp/all_trim.fq.gz
                    L_antes=$(zcat $fastq_path | paste - - - - | wc -l ) 
                    L_despues=$(zcat $fq_trim_path | paste - - - - | wc -l ) 
                    B_antes=$(zcat $fastq_path | paste - - - - | cut -f2 | tr -d "\n" | wc -c) 
                    B_despues=$(zcat $fq_trim_path | paste - - - - | cut -f2 | tr -d "\n" | wc -c ) 
                    echo " $condicion,$L_antes,$L_despues,$B_antes,$B_despues" >> temp/anydes_pormuestra.txt


                else 
                    echo "El archivo de la condición $condicion esta vacio"
                    echo "Favor de revizar el archivo o la ruta"
                fi               
            else 
                echo "Para la $condicion No se encuentra la dirección del siguiente archivo $fastq_path "  
                echo "Corregir y volver a ingresar archivos"
            fi
        done
        fastqc temp/all_merged.fq.gz -o temp/
        fastqc temp/all_trim.fq.gz -o temp/

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
########aqui coomienza el script para las lecturas pareadas
                    
                    trim_galore --paired --basename $condicion $path_R1 $path_R2 --length 30 --gzip --output_dir temp/  

                    cat $path_R1 >> temp/all_merged.fq.gz
                    cat $path_R2 >> temp/all_merged.fq.gz

                    ### nuevo archivo de muestras
                    fq1_trim_path="temp/${condicion}_val_1.fq.gz"
                    fq2_trim_path="temp/${condicion}_val_2.fq.gz"

                    echo "${condicion},$(realpath "$fq1_trim_path"),$(realpath "$fq2_trim_path")" >> "$muestras_trim"
                    cat $fq1_trim_path >> temp/all_trim.fq.gz
                    cat $fq2_trim_path >> temp/all_trim.fq.gz
                    
                    L_antes_1=$(zcat $path_R1 | paste - - - - | wc -l ) 
                    L_despues_1=$(zcat $fq1_trim_path | paste - - - - | wc -l ) 
                    B_antes_1=$(zcat $path_R1 | paste - - - - | cut -f2 | tr -d "\n" | wc -c) 
                    B_despues_1=$(zcat $fq1_trim_path| paste - - - - | cut -f2 | tr -d "\n" | wc -c ) 
                    
                    L_antes_2=$(zcat $path_R2 | paste - - - - | wc -l ) 
                    L_despues_2=$(zcat $fq2_trim_path | paste - - - - | wc -l ) 
                    B_antes_2=$(zcat $path_R2 | paste - - - - | cut -f2 | tr -d "\n" | wc -c) 
                    B_despues_2=$(zcat $fq2_trim_path | paste - - - - | cut -f2 | tr -d "\n" | wc -c ) 
                    
                    echo "r1 $condicion,$L_antes_1,$L_despues_1,$B_antes_1,$B_despues_1" >> temp/anydes_pormuestra.txt
                    echo "r2 $condicion,$L_antes_2,$L_despues_2,$B_antes_2,$B_despues_2" >> temp/anydes_pormuestra.txt

                else 
                    echo "Almenos uno de los archivos de la $condicion esta vacio"
                    echo "Favor de revizar el archivo o la ruta"
                fi               
            else 
                echo "Para la $condicion no se encuentra la ruta de almenos uno de los archivos "  
                echo "Corregir y volver a ingresar archivos"
            fi
        done 
        fastqc temp/all_merged.fq.gz -o temp/
        fastqc temp/all_trim.fq.gz -o temp/


    fi        
