# This script attempts to load required packages.
# If required packages are not found on local device,
# this script will attempt to download them.
# In addition, this script will load tc.RData, needed
# in the Data_Splitter.R file.
rm(list = ls())

if(!require(pacman)){
  install.packages('pacman')
}

pacman::p_load(tidyverse,
               rlist,
               xgboost,
               Matrix,
               Metrics,
               gridExtra,
               cowplot,
	             profvis)

#Prepare Global Environment
load('../Data/tc.RData')
