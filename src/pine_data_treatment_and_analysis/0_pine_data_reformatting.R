# script meant to reformat data for genomic prediction
# note: text is formatted from Addins using Style active file from styler package

# clear memory and source libraries
rm(list = ls())
library(devtools)
install_other_requirements <- F
if (install_other_requirements) {
  install.packages("BiocManager")
  library(BiocManager)
  BiocManager::install("snpStats")
  BiocManager::install("mixOmicsTeam/mixOmics")
  py_install("umap-learn", pip = T, pip_ignore_installed = T)
}
library(mixOmics)
library(data.table)
library(plotly)
library(ggplot2)
library(umap)
library(Matrix)
library(graphics)
library(htmlwidgets)
library(rstudioapi)
library(stringr)
library(tidyr)
library(dplyr)
library(lsmeans)

# detect and set script path automatically, and source functions
setwd(dirname(getActiveDocumentContext()$path))
source("../functions.R")

# set options to increase memory
options(expressions = 5e5)
options(warn = -1)
emm_options(rg.limit = 10e6)

# set path for genomic data and phenotype data
genom_dir_path <- "../../data/genomic_data/"
pheno_dir_path <- "../../data/phenotype_data/"

# set output result path for genomic graphics
output_genom_graphics_path <- "../../results/genomic_prediction_graphics/"

# set maximum number of principal components to be tested using akaike
# information criterion
max_n_comp_ <- 10

# define traits_
traits_ <- c("H", "I", "D", "T4", "T5", "T6")

# get phenotypic data
pheno_df <- as.data.frame(fread(paste0(
  pheno_dir_path,
  "PhenotypeField.txt"
)))
# drop last empty column
pheno_df <- pheno_df[, -ncol(pheno_df)]
colnames(pheno_df)[match("ID", colnames(pheno_df))] <- "Genotype"

# transform data with pivot_longer to
# group columns H, I, D, T4, T5, T6 based on years
pheno_df <- as.data.frame(pheno_df %>%
  pivot_longer(
    cols = starts_with(c("H", "I", "D", "T4", "T5", "T6")),
    names_to = c(".value", "Year"),
    names_pattern = "([A-Za-z0-9]+)[-]?(\\d{2})"
  ) %>%
  mutate(Year = as.integer(paste0("20", Year))))

# create environment variable
pheno_df$Envir <- paste0(
  pheno_df$Site, "_",
  pheno_df$Year, "_",
  pheno_df$Block
)

# generate latitude and longitude variables per environment
pheno_df <- generate_latitude_longitude_variables_by_environment(
  pheno_df
)

# get genomic data
geno_df <- t(as.data.frame(fread(paste0(
  genom_dir_path,
  "genotypefield.txt"
))))
colnames_ <- geno_df[1, ]
colnames(geno_df) <- colnames_
geno_df <- geno_df[-1, ]
geno_df <- replace_nn_with_most_frequent(geno_df)
rownames_ <- rownames(geno_df)
geno_df <- recode_genotypes(geno_df) # recode as 0, 1 and 2
rownames(geno_df) <- rownames_

# write reformatted datasets
fwrite(pheno_df,
  file = paste0(pheno_dir_path, "phenotype_data.csv")
)
fwrite(as.data.frame(geno_df),
  file = paste0(genom_dir_path, "genomic_data.csv"),
  row.names = T
)
