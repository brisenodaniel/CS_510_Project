# Purpose of script is call functions from RMSE_Calculator
#	to calculate error statistics (in the form of error 
#	vectors) for different subsets of the superconductor
#	data, and to save these statistics to disk as .rds files.
# Preconditions: Files Dependencies.R, Data_Splitter.R, Model.R, RMSE_Calculator.r,  
#	and subdirectory ../Data/ must be present in same directory as this file. 
#	../Data/ directory must contain tc.RData file.
# Postconditions: The following files will be written to disk in the ../Output subdirectory:
#	control_err.rds: contains error statistics for predictions over any superconductor
#		in the train dataframe (note that this is not testing data, but the entire
#		superconductors database as a dataframe loaded from tc.RData).
#	decile_err.rds: contains error statistics for predictions on superconductors belonging
#		to different true (as opposed to predicted) critical temperature deciles
#	quartile_err.rds: contains error statistics for predictions on superconductors belonging 
#		to different true (as opposed to predicted) critical temperature quartiles.
#	output_quartile_err.rds: contains error statistics for predictions on supreconductors
#		belonging to different predicted critical temperature quaritles.
#	elemental_err_n_rt.rds: contains error statistics for predictions on superconductors
#		containing certain compounds (element subsets). For this data, the XGBoost model was trained 
#		on an unrestricted class of superconductors.
#	elemental_err_rt.rds: contains error statistics for predictions on suprecondutors
#		containing certain compounds (element subsets). For this data, the XGBoost model was trained 
#		only on superconductors in the same element subset as the testing data.
# TODO: Eliminate decile_err calculation. It is not used in final analysis and is computationally expensive
#	to compute.
source('Dependencies.R')
source('Data_Splitter.R')
source('Model.R')
source('RMSE_Calculator.R')

system.time({
ntrials <- 2
####### full set of err vects
control_err <- rmse_subset_ntrials_as_df(list('trn'=train),ntrials)
saveRDS(control_err, file = '../Output/control_err.rds')
gc()
###### Get RMSE Data by Element Subsets with no retraining
elemental_subsets <- list(fe_train, hg_train, cu_train, b2mg_train)
names(elemental_subsets) = c('Fe','Hg','Cu' ,'B2Mg')
elemental_err_no_retrain <- rmse_subset_ntrials_as_df(elemental_subsets,ntrials)
saveRDS(elemental_err_no_retrain, file = '../Output/elemental_err_n_rt.rds')
gc()
###### Get RMSE Data by Element Subsets with retraining 
elemental_err_retrained <- rmse_subset_ntrials_as_df(elemental_subsets,ntrials,retrain = TRUE)
rm(elemental_subsets)
gc()
saveRDS(elemental_err_retrained, file = '../Output/elemental_err_rt.rds')
###### Get RMSE Data by Quartile
filt <- function(x) subset(x,select = -c(decile, quartile))
quartiles <- lapply(train_quartiles,filt)
rm(train_quartiles)
names(quartiles) <- c(1:4)
quartile_err <- rmse_subset_ntrials_as_df(quartiles,ntrials)
rm(quartiles)
gc()
saveRDS(quartile_err, file = '../Output/quartile_err.rds')

###### Get RMSE Data by Decile
deciles <- lapply(train_deciles,filt)
rm(train_deciles)
names(deciles) <- c(1:10)
decile_err <- rmse_subset_ntrials_as_df(deciles,ntrials)
rm(deciles)
gc()
saveRDS(decile_err, file = '../Output/decile_err.rds')

##### Get Error Statistics by output quartile
output_quartile_errs <- err_output_quartiles_ntrials(ntrials)
saveRDS(output_quartile_errs, file = '../Output/output_quartile_errs.rds')

})


