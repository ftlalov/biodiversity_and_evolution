#!/bin/bash

# Script para verificar y/o crear entornos de trabajo para Pipeline
# --------------------------------------------------------------------
# Este script analiza si los programas necesarios estan instalados,
# de lo contrario instalara los programas necesarios
# ----------------------------------------------------------------------

echo "Verificando los programas y los ambientes, favor de esperar"

###exportar conda por si no esta en el path 
export PATH="$HOME/miniconda1/bin:$PATH"
export PATH="$HOME/miniconda2/bin:$PATH"
export PATH="$HOME/miniconda3/bin:$PATH"
export PATH="$HOME/anaconda1/bin:$PATH"
export PATH="$HOME/anaconda2/bin:$PATH"
export PATH="$HOME/anaconda3/bin:$PATH"

# Funcion para ver si existe un comando
check_comando() {
    if ! whereis "$1" >/dev/null 2>&1; then
        echo "Error: El comando '$1' no está instalado. Instalar comando para continuar" >&2
        exit 1
        else
        echo "$1 Instalado"
    fi
}

### Funcion para ver existe conda
check_conda() {
    a=$(conda --version 2>&1 )
    if [[ $a == *"not found"* ]]; then
    echo "Conda no es accesible"
    install_anaconda

    else
        echo "Conda está instalado y accesible."
        echo "$a" # Show the actual version
    fi
}

### Funcion para instalar anaconda
install_anaconda() {
    read -r -p "¿Desea instalar el anaconda? (S/N): " RESPUESTA
     case "${RESPUESTA,,}" in
        s*|y*) 
            echo "Instalando miniconda"
            
            MINICONDA_INSTALLER_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
            INSTALLER_SCRIPT="Miniconda_Installer.sh"
            INSTALL_PATH="$HOME/miniconda3"
            echo "Descargando conda"
            wget -O $INSTALLER_SCRIPT $MINICONDA_INSTALLER_URL
            
            bash "$INSTALLER_SCRIPT" -b -p "$INSTALL_PATH"

            echo "Instalación completa"

            rm "$INSTALLER_SCRIPT"

            echo "Configurando Conda..."
            
            if [ -f "$INSTALL_PATH/bin/conda" ]; then
                 "$INSTALL_PATH/bin/conda" init bash
                echo "¡Instalación y configuración completada! 🎉"
                echo "Es necesario Cerrar el programa y volver a iniciar"
                exit 1
            else
            echo "Error: La instalación de Conda falló." >&2
            fi    

         ;;    
        *)
            echo "No se ha iniciado la isntalación, saliendo del programa"
            exit 1
          ;;    
    esac      
}

###### Verificar si wget está disponible

check_comando wget
check_conda

