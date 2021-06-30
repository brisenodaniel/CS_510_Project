# This script attempts to load required packages.
# If required packages are not found on local device,
# this script will attempt to download them.
# In addition, this script will load tc.RData, needed
# in the Data_Splitter.R file.
rm(list = ls())

if(!require(pacman)){
  install.packages('pacman')
}

pacman::p_load(dplyr,
               stringr,
               rlist,
               xgboost,
               Matrix,
               Metrics,
               tidyverse,
               gridExtra,
               cowplot)

#Prepare Global Environment
load('../Data/tc.RData')
