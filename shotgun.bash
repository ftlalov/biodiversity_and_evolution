#!/bin/bash

# Script para analizar las lecturas 
# --------------------------------------------------------------------
#   Este script analiza el metagenoma con shotgun 
#   se ingresan los archivos de la carpeta /temp 
#   provenientes del script reads_preprocess.bash 
#   y se usa la configuración de lecturas del main
# ----------------------------------------------------------------------
###exportar conda por si no esta en el path 
export PATH="$HOME/miniconda1/bin:$PATH"
export PATH="$HOME/miniconda2/bin:$PATH"
export PATH="$HOME/miniconda3/bin:$PATH"
export PATH="$HOME/anaconda1/bin:$PATH"
export PATH="$HOME/anaconda2/bin:$PATH"
export PATH="$HOME/anaconda3/bin:$PATH"
##############################


config_seq=$1
archivo_muestras=$(cat "temp/new_samplefile.txt") ## archivo generado en reads_preprocess.bash
declare -A arreglo_fastq
declare -A array_conting

echo "$archivo_muestras"
source $HOME/miniconda3/etc/profile.d/conda.sh
conda activate biodiversity_and_evolution_p1




seleccionar_asignador_metagenomico() {
    echo "--- Paso 1: Selección del asignador ---"
    PS3="Selecciona el tipo de software (1, 2, 3): "
    options=("Kaiju" "Kraken" "Salir")
    select opt in "${options[@]}"; do
        case $opt in
            "Kaiju")
                
                echo "Selecciónando Kaiju."
                a=1
                break
                ;;
            "Kraken")
                a=2
                break
                ;;
            "Salir")
                echo "saliendo del programa"
                exit 0
                ;;
            *) echo "Opción inválida $REPLY";;
        esac
    done
}

rev_base_datos(){
    if [[ $a -eq 1 ]]; then 
        kaiju_db="database/kaiju"
        if [ -d "$kaiju_db" ]; then
            echo "La carpeta con la base de datos existe."

        else
            echo "La carpeta con la base No de datos existe"

            read -r -p "¿Desea descargar la base de datos? (S/N): " RESPUESTA
                case "${RESPUESTA,,}" in
                s*|y*) 
                    mkdir -p database database/kaiju  
                    wget -O database/kaiju/database/database.tgz https://kaiju-idx.s3.eu-central-1.amazonaws.com/2024/kaiju_db_fungi_2024-08-16.tgz
                    tar -xzvf database/kaiju/database.tgz -C database/kaiju/.
                    rm -rf database/kaiju/database.tgz
                    ;;    
                    *)
                        echo "Es necesario contar con la base de datos, saliendo del programa"
                        exit 1
                    ;;    
                esac      
            fi
    elif [[ $a -eq 2 ]]; then 
        #kraken
        kraken2_db="database/kraken2"
        if [ -d "$kraken2_db" ]; then
            echo "La carpeta con la base de datos existe."
        else
            echo "La carpeta con la base No de datos existe"
            read -r -p "¿Desea descargar la base de datos? (S/N): " RESPUESTA
                case "${RESPUESTA,,}" in
                s*|y*) 
                    mkdir -p database/database/kraken2 
                    wget -O database/kraken2/database/database.tgz https://genome-idx.s3.amazonaws.com/kraken/k2_standard_08_GB_20250714.tar.gz
                    tar -xvzf database/kraken2/database.tar.gz -C database/kraken2/.
                    rm -rf database/kraken2/database.tar.gz

                    ;;    
                    *)
                        echo "Es necesario contar con la base de datos, saliendo del programa"
                        exit 1
                    ;;    
                esac      
            fi
    fi

}
seleccion_ensamblador(){
    echo "--- Paso 2: Selección del ensamblador metagenómico ---"
    PS3="Selecciona el software para el ensamblado(1, 2, 3): "
    options=("metaspades" "megahit" "Salir")
    select opt in "${options[@]}"; do
        case $opt in
            "metaspades")
                
                echo "e realizará el ensamble metagenómico con metaspades"
                d=1
                break
                ;;
            "megahit")
                echo "Se realizará el ensamble metagenómico con megahit"
                d=2
                break
                ;;
            "Salir")
                echo "saliendo del programa"
                exit 0
                ;;
            *) echo "Opción inválida $REPLY";;
        esac
    done

}

preguntar_ensamblado() {
    read -r -p "¿Desea realizar un ensamble metagenómico antes de la asignación (S/N): " RESPUESTA
    case "${RESPUESTA,,}" in
        s*|y*) 
            echo "Se ha elegido realizar un ensamble metagenómico"
            c=1
            seleccion_ensamblador 
         ;;    
        *)
            echo "Se realizará la asignación taxonómica directamente de las lecturas"
            c=2
          ;;    
    esac      

}

definir_array(){
    if [[ $config_seq == "SE" ]];then
       
        while IFS="," read -r condicion r1; do
            if [[ ! -z "$condicion" && ! -z "$r1" ]]; then
                arreglo_fastq["$condicion"]="$r1"
            else
            echo "No se logró procesar el archivo de muestras"
            echo "Favor de ingresar un archivo valido"
            exit 1
            fi
        done <<< "$archivo_muestras"
            
    elif [[ $config_seq == "PE" ]];then 
        
        DELIMITADOR="@"
        ##creador de la matriz
        while IFS="," read -r condicion R1 R2 ; do
            if [[ ! -z "$condicion" && ! -z "$R1" && ! -z "$R2" ]]; then #revisar que el archivo no esta vacio 
                arreglo_fastq["$condicion"]="${R1}${DELIMITADOR}${R2}"
            else 
                echo "Error de formato, introducir de esta manera"    
                echo "Identificador R1.fastq.gz R2.fastq.gz "
                echo "Favor de ingresar un archivo valido"
                exit 1
            fi    

        done <<< "$archivo_muestras"       
    fi    

}

def_array_assembly(){ 
    archivo_ensambles=$(cat "temp/condition_assembly_path.txt")
        while IFS="," read -r condicion r1; do
            if [[ ! -z "$condicion" && ! -z "$r1" ]]; then
                array_conting["$condicion"]="$r1"
            else
            echo "No se logró procesar el archivo de muestras"
            echo "Favor de ingresar un archivo valido"
            exit 1
            fi
        done <<< "$archivo_ensambles"

}

ensamblar_metaspades() {
    if [[ $config_seq == "SE" ]];then
        echo -e "\033[31mLamentablemente metaspades no soporta lecturas Single End.\033[0m"
        echo -e "\033[31mSeleccionar ensamblador valido (megahit).\033[0m"
        echo ""
        seleccion_ensamblador
    elif [[ $config_seq == "PE" ]];then 
        echo "Iniciando Ensamble con metaspades Lecturas Pareadas"
        definir_array
        echo "" > temp/condition_assembly_path.txt #crea un archivo vacio para vaciar las direcciones de los archivos finales del ensamble
        for condicion in "${!arreglo_fastq[@]}"; do
                R1_R2_PATHS="${arreglo_fastq[$condicion]}"
                IFS="${DELIMITADOR}" read -r path_R1 path_R2 <<< "$R1_R2_PATHS" 
                metaspades -1 $path_R1 -2 $path_R2 -o temp/"$condicion"_assembly/
                assembly_path="temp/${condicion}_assembly/scaffolds.fasta"           
                echo "${condicion},$(realpath "$assembly_path")" >> temp/condition_assembly_path.txt
        
        done 

    fi    
    
}


ensamblar_megahit() {
    if [[ $config_seq == "SE" ]];then
        echo "Iniciando Ensamble con megahit Lecturas no pareadas" #
        definir_array
        > temp/condition_assembly_path.txt

        for condicion in "${!arreglo_fastq[@]}"; do
            fastq_path="${arreglo_fastq[$condicion]}"
            
            megahit -r $fastq_path -o temp/"$condicion"_assembly/

            assembly_path="temp/${condicion}_assembly/final.contigs.fa"           
            echo "${condicion},$(realpath "$assembly_path")" >> temp/condition_assembly_path.txt

        done

    elif [[ $config_seq == "PE" ]];then 
        echo "Iniciando ensamble con megahit Lecturas Pareadas"
        definir_array

        echo "" > temp/condition_assembly_path.txt   #crea un archivo vacio para vaciar las direcciones de los archivos finales del ensamble
        
        for condicion in "${!arreglo_fastq[@]}"; do
                R1_R2_PATHS="${arreglo_fastq[$condicion]}"
                IFS="${DELIMITADOR}" read -r path_R1 path_R2 <<< "$R1_R2_PATHS" 
                megahit -1 $path_R1 -2 $path_R2 -o temp/"$condicion"_assembly/
                assembly_path="temp/${condicion}_assembly/final.contigs.fa"           
                echo "${condicion},$(realpath "$assembly_path")" >> temp/condition_assembly_path.txt

        done     

    fi    
}

asignar_tax_kaiju() {
    mode=$1
    if [[ $mode == "assembly" ]]; then
        echo "asignación taxonómica del ensamble kaiju"
    elif [[ $mode == "lecturas" ]]; then
         if [[ $config_seq == "SE" ]]; then
        echo "Asignación con Kaiju Lecturas No Pareadas" #
         elif [[ $config_seq == "PE" ]]; then 
            echo "Asignación con Kaiju Lecturas Pareadas"
            definir_array
            echo "" > temp/assignation_files.txt
            t="database/kaiju/nodes.dmp"
            f="database/kaiju/kaiju_db_fungi.fmi"

            for condicion in "${!arreglo_fastq[@]}"; do
                R1_R2_PATHS="${arreglo_fastq[$condicion]}"
                IFS="${DELIMITADOR}" read -r path_R1 path_R2 <<< "$R1_R2_PATHS" 
                kaiju -t "$t" -f "$f" -i $path_R1 -j $path_R2 -o temp/"$condicion"_kaiju.out -z 8
                assing_path="temp/${condicion}_kaiju.out"           
                echo "${condicion},$(realpath "$assing_path")" >> temp/assignation_files.txt
        
            done 
        fi    
    fi
}

asignar_tax_kraken(){
        mode=$1
    if [[ $mode == "assembly" ]]; then
        echo "asignación taxonómica del ensamble con kraken"
    elif [[ $mode == "lecturas" ]]; then
         if [[ $config_seq == "SE" ]]; then
            echo "Asignación con kraken Lecturas No Pareadas" #
         elif [[ $config_seq == "PE" ]]; then 
            echo "Asignación con kraken Lecturas Pareadas"
            definir_array
            kraken2_db="database/kraken2"
            touch temp/kraken_asig_report.txt
             for condicion in "${!arreglo_fastq[@]}"; do
                R1_R2_PATHS="${arreglo_fastq[$condicion]}"
                IFS="${DELIMITADOR}" read -r path_R1 path_R2 <<< "$R1_R2_PATHS" 
                kraken2 --paired --threads 8 --db $kraken2_db --report temp/"$condicion"_report.txt --output temp/"$condicion"_kraken_out.txt   $path_R1 $path_R2 
                assing_path="temp/${condicion}_kraken_out.txt"           
                echo "${condicion},$(realpath "$assing_path")" >> temp/assignation_files.txt
                report_path="temp/${condicion}_report.txt "
                echo "${condicion},$(realpath "$report_path")" >> temp/kraken_asig_report.txt
                
            done 
            for i in "S" "F" "C" "K" ;do
                Rscript kraken_report.R $i "all_samples_$i"
            done

        fi    
    fi
}

####Codigo principal #########################################################



seleccionar_asignador_metagenomico
rev_base_datos
preguntar_ensamblado

if [[ $a -eq 1 ]]; then 
    echo "kaiju"
    
    if [[ $c -eq 1 ]];then
        ### para ingresar al correcto ensamblador        
        if [[ $d -eq 1 ]]; then
            #ensamblar  con metaspades
            ensamblar_metaspades
        elif [[ $d -eq 2 ]]; then
            #ensamble con megahit 
            ensamblar_megahit
        fi
        # asignar con kaiju con contings
        asignar_tax_kaiju assembly
    elif [[ $c -eq 2 ]]; then 
        #asignar de lecturas
        asignar_tax_kaiju lecturas
    fi

elif [[ $a -eq 2 ]]; then 
        echo "kraken"
        if [[ $c -eq 1 ]]; then
            ### para ver que ensamblador se usa         
            if [[ $d -eq 1 ]]; then
                #ensamblar  con metaspades
                ensamblar_metaspades
            elif [[ $d -eq 2 ]]; then
                #ensamble con megahit
                #ensamblar_megahit 
                echo ""

            fi

            # asignar con kraken con contings
            asignar_tax_kraken assembly
            echo "kraken"
        elif [[ $c -eq 2 ]]; then
            #realizar asignación directamente con kraken con SE 
                #asignar directamente de lecturas con kraken  
            asignar_tax_kraken lecturas
        fi


fi

