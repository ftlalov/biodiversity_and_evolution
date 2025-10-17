#!/usr/bin/env/Rscript
args <- commandArgs(trailingOnly = TRUE)

TARGET_RANK <- args[1]
output_name <- args[2]
# Lista de paquetes requeridos
paquetes_requeridos <- c("tidyverse", "data.table")

# Bucle para verificar, instalar y cargar los paquetes
for (paquete in paquetes_requeridos) {
  # 1. Verificar si el paquete está instalado
  if (!requireNamespace(paquete, quietly = TRUE)) {
    
    # 2. Si no está instalado, instalarlo
    install.packages(paquete)
  }
  
  # 3. Cargar el paquete (ya sea recién instalado o ya existente)
  library(paquete, character.only = TRUE)
}
library(tidyverse)
library(data.table)
##### argumentos



###para poder guardar el grafico con un nombre especifico

OUTPUT_DIR <- "temp/"
FILE_SUFFIX <- "_composition_barplot.png"
output_filename <- paste0(OUTPUT_DIR, output_name, FILE_SUFFIX)



asig_data <- fread("temp/kraken_asig_report.txt", 
                   header = FALSE, 
                   sep = ",", 
                   col.names = c("sample_name", "file_path"))
asig_data <- asig_data %>%  mutate(file_path = str_trim(file_path)) ## limpiar archivo

#TARGET_RANK <- "S"
MIN_ABUNDANCE_THRESHOLD <- 1.0
## crear nombres
report_files <- setNames(asig_data$file_path, asig_data$sample_name)
### funcion para leer los 
read_kraken_report <- function(file_path, sample_name) {
    data <- fread(file_path, sep = "\t", header = FALSE, fill = TRUE, 
                col.names = c("perc_clade", "reads_clade", "reads_assigned", 
                              "rank_code", "taxon_id", "scientific_name"))
    data %>%
    mutate(sample = sample_name, scientific_name = str_trim(scientific_name)) %>%  select(sample, perc_clade, rank_code, scientific_name)                         
}
## ejecutar funcion
kraken_data_long <- map2_dfr(report_files, names(report_files), read_kraken_report)
#### filtrar nivel taxonomico 
filtered_data <- kraken_data_long %>%
  filter(rank_code == TARGET_RANK, scientific_name != "unclassified")
final_data <- filtered_data %>%
  group_by(scientific_name) %>%  
  mutate(mean_perc = mean(perc_clade)) %>%
  ungroup() %>%
  mutate(plot_name = if_else(mean_perc < MIN_ABUNDANCE_THRESHOLD, "Other_Taxa", scientific_name),
  ) %>% group_by(sample, plot_name) %>%
  summarise(perc_plot = sum(perc_clade), .groups = 'drop') %>% mutate(plot_name = fct_reorder(plot_name, perc_plot, .fun = sum, .desc = TRUE))

### creacion del grafico 
    barplot_kraken <- ggplot(final_data, aes(x = sample, y = perc_plot, fill = plot_name)) +
        geom_bar(stat = "identity", position = "stack", width = 0.8) +
        geom_text( data = final_data %>% group_by(sample) %>% summarise(total_perc = sum(perc_plot), .groups = 'drop'),
        aes(x = sample, y = total_perc, label = paste0(round(total_perc, 1), "%")),
        inherit.aes = FALSE,  just = -0.5,        
        size = 3.5,
        color = "black"
    ) +
        labs( title = paste("Composición Taxonómica (Nivel:", TARGET_RANK, ")"),
        x = "Muestra",
        y = "Abundancia Relativa (%)",
        fill = paste("Taxón (", TARGET_RANK, ")") ) +
        scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
    legend.position = "right",  plot.title = element_text(hjust = 0.5, face = "bold") )

ggsave( output_filename, plot = barplot_kraken, width = 10, height = 6)
q(save = "no")