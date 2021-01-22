# The purpose of this script is to provide functions for collecting 
#	error statistics for predictions on different subsets of the
#	superconductor data. The error statistics are summarized in
#	error vectors containing:
#		RMSE
#		raw average error 
#		standard deviation of error
#		under-prediction count
#		over-prediction count
#		correct prediction count (expected to be 0)
#		average under-prediction error
#		average over-prediction error
#		standard deviation of under-prediction error
#		standard devaition of over-prediction error
#		
# Pre-conditions:
#	The following files should be sourced:
#		../Dependencies.R
#		../Data_Splitter.R
#		../Model.R
# Post-conditions:
#	Upon sourcing the file, the following functions will be loaded into
#	the runtime enviornment:
#		condense :: list(data_frame) => data_frame
#		rmse_subset :: data_frame x data_frame x XGBoost_bst model x boolean x string
#					=> error_vector
#		rmse_subset_vector :: data_frame x list(data_frame) x XGBoost_bst model x string x boolean
#			=> data_frame(error_vector x string) 
#		rmse_subset_1trial :: list(data_frame) x int x int x boolean => list(error_vector x string)
#		rmse_subset_ntrials :: list(data_frame) x int x boolean => list(error_vector x string)
#		rmse_subset_ntrials_as_df :: list(data_frame) x int x boolean => data_fame(error_vector x string)
#		err_output_quartiles_1trial :: int => data_frame(error_vector x int x int)
#		err_output_quartiles_ntrials:: int => data_frame(error_vector x int x int)
#		raw_err_collector -- appears to be unused. Need to remove
#		rmse_func :: XGBoost_bst model x Matrix x str => numeric
#		err_stats :: XGBoost_bst model x Matrix x str => error_vector
#		pred_err_stats :: vector(numeric) x vector(numeric) => error_vector
#		err_stats_quantiles :: XGBoost_bst model x Matrix x str => data_frame(err_vector x int)
# TODO: File needs significant refactoring:
#		Remove mentions of RMSE. File was originally intended to collect only RMSE data. It vastly outgrew
#			this puprose and RMSE labeling is misleading.
#		Eliminate unecessary retraining of XGBoost bst model.
#		Refactor and split up pred_err_stats and err_stats_quantiles. Functions are currently bloated and too
#			large to be easily human readable
#		Re-order and re-name function variable names to be consistent throughout file.
#		Eliminate unused functions.



#### The following variables are for increased computational efficiency  
NEW_MOD <- TRUE #Flag indicating if new control model has been set
control_rmse <- 0


#Helper function, turns list of df with same columns into
# one large df
condense <- function(df_list){
  df <- data.frame()
  for (i in 1:length(df_list)){
    df <- rbind(df, df_list[[i]])
  }
  return (df)
}

#helper function, decides if model needs to be retrained on reduced dataset
# and if so safely retrains it. Otherwise returns control_model
model_retrain <- function(data, subset, control_model, retrain, label){
  #if model should be retrained
  if(retrain){
    data_test <- intersect(data,subset) #partition of testing data also in subset
    data_train <- intersect(train,subset) #partition of superconductor dataset also in subset
    data_train <- setdiff(data_train,data_test) #remove partition in data_train also in data_test
                                                #ensures mutually exclusive testing & training data
    if(nrow(data_train)==0){#check for empty training data
      warnings("NO DATA IN SUBSET AVAILABLE TO TRAIN MODEL")
      warnings("WILL NOT RETRAIN MODEL THIS RUN")
      return(control_model)
    }
    else{#if training data exists 
      return (trainer(data_train,label))
    }
  }
  else{
    return(control_model) 
  }
}



#function to calculate rmse for given subset and training data
rmse_subset <- function(data, 
                        subset,
                        mod_control, 
                        retrain,
                        label = 'critical_temp'){
  #obtain testing data partition for subset of interest
  data_test <- intersect(data,subset) 
  #if retrain=T, retrain model only on training data also present in subset 
  mod_test <- model_retrain(data, subset, mod_control, retrain, label)
  
  #obtain RMSE values for control and test models and data
  if (NEW_MOD){ #only compute control RMSE if control model or control data
                  #have changed or been set for the first time
    NEW_MOD <<- FALSE
    control_rmse <<- rmse_funct(mod_control,data,label)
  }
  #compute error statistics for test model and data
  test_err <- err_stats(mod_test,data_test,label)
  return(c(test_err, 'control' = control_rmse))
}


#function to calculate rmse vectors for given data subsets and training data
rmse_subset_vector <- function(data,
                               subset_vect, 
                               model, 
                               label = 'critical_temp',
                               retrain=FALSE){
  
  rmse_subset_partial <- function(subset) rmse_subset(data, 
                                                      subset, 
                                                      model, 
                                                      retrain, 
                                                      label=label)
  #assemble template return value vector for err_subset
  template_vector <- c(
    'test' = 0,
    'ave_err' = 0,
    'std_err' = 0,
    'under_cnt' = 0,
    'over_cnt' = 0,
    'correct_cnt' = 0,
    'ave_under' = 0,
    'std_under' = 0,
    'ave_over' = 0,
    'std_over' = 0,
    'control' = 0
  )
  
  rmse_vec <- vapply(subset_vect, rmse_subset_partial, c(template_vector))
  rmse_vec <- cbind( t(rmse_vec), 'subset' = names(subset_vect) ) #TODO: might cause issues
  return( rmse_vec)
}

 rmse_subset_1trial <- function(subset, trial_num, ntrials, retrain){
   NEW_MOD <<- TRUE
   print('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
   print(sprintf("Trial ", trial_num,"/",ntrials))
   print('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
   partitions <- partition(train,2/3)
   train_df <- partitions[['train']]
   test_df <- partitions[['test']]
   mod <- trainer(train,'critical_temp')
   return( rmse_subset_vector(test_df, subset, mod, retrain = retrain)  )
 }

 #Function calculates 50 iterations of rmse values for subsets
 rmse_subset_ntrials <- function(subsets, ntrials = 50, retrain = FALSE){
   trials <- 1:ntrials
   rmse_partial <- function(x) rmse_subset_1trial(subsets,x,ntrials,retrain)
   return(lapply(trials,rmse_partial))
 }

#same functionaity as rmse_subset_ntrials, but return value is a single 
 #dataframe instead of a list of dataframes
rmse_subset_ntrials_as_df <- function(subsets, ntrials=50, retrain = FALSE){
  rmse_df <- rmse_subset_ntrials(subsets, ntrials, retrain)
  return( condense(rmse_df))
}

err_output_quartiles_1trial <- function(trial){
  partitions <- partition(train,2/3)
  train_df <- partitions[['train']]
  test_df <- partitions[['test']]
  mod <- trainer(train,'critical_temp')
  err_df <- err_stats_quantiles(mod,test_df) %>%
            mutate('Trial' = c(trial,trial,trial,trial))
  return(err_df)
}

err_output_quartiles_ntrials <- function(trials = 50){
  trials <- 1:trials
  err_lst <- lapply(trials,err_output_quartiles_1trial)
  return( condense(err_lst))
}



################################## Raw Error Collection ####################################
 
# #collects raw error vector for given subset 
 raw_err_collector <- function(model,subsets){
  err_vect_partial <- function(subset) err_vect(model,subset)
  return(lapply(subsets,err_vect_partial))
 }


#rmse calculating function
rmse_funct <- function(mod, full_m,label = 'critical_temp'){
  test_m <- full_m %>% select(-label)
  actual_ct <- full_m %>% select(label)
  pred <- predict_vector(mod,test_m)
  return( rmse(as.numeric(t(actual_ct)), pred) )
}

#full error stats calculating function
err_stats <- function(mod, full_m, label = 'critical_temp'){
  #obtain prediction on test data
  test_m <- full_m %>% select(-label)
  actual_ct <- full_m %>% select(label)
  pred <- predict_vector(mod,test_m)
  
  return(pred_err_stats(pred,actual_ct))
}


# obtain summary error rate statistics for given prediction vector
pred_err_stats <- function(pred, actual){
  #obtain rmse
  rmse_full <- rmse(as.numeric(t(actual)), pred)
  
  #obtain mean error and std of error
  raw_diff <- t(pred - actual)
  ave_err <- mean(raw_diff)
  std_err <- std(raw_diff)
  
  
  #obtain count of over and under prediction
  under_pred <- raw_diff[raw_diff<0]
  over_pred <- raw_diff[raw_diff>0]
  exact_pred <- raw_diff[raw_diff == 0]
  under_cnt <- length(under_pred)
  over_cnt <- length(over_pred)
  
  #obtain number of exact predictions
  correct_cnt <- length(exact_pred)
  
  
  #obtain mean and std over_estimation
  ave_over <- mean(over_pred)
  std_over <- std(over_pred)
  
  #obtain mean and std under_estimation
  ave_under <- mean(under_pred)
  std_under <- std(under_pred)
  
  #assemble return vector
  ret_vect <- c(
    'test' = rmse_full,
    'ave_err' = ave_err,
    'std_err' = std_err,
    'under_cnt' = under_cnt,
    'over_cnt' = over_cnt,
    'correct_cnt' = correct_cnt,
    'ave_under' = ave_under,
    'std_under' = std_under,
    'ave_over' = ave_over,
    'std_over' = std_over
  )
  return(ret_vect)
}

#obtain summary error rate statistics for outpt divided by predicted critical_temp 
# quartiles
err_stats_quantiles <- function(mod, full_m, label = 'critical_temp'){
  #obtain prediction vector
  test_m <- full_m %>% select(-label)
  actual_ct <- full_m %>% select(label)
  pred <- predict_vector(mod,test_m)
  pred <- data.frame(pred)
  
  #attach actual ct values
  pred <- mutate(pred, actual = actual_ct)
  
  #partition into quartiles
  pred <- pred %>% mutate(quartile = ntile(pred,4))
  
  q1 <- pred %>% 
    filter(quartile==1) %>%
    select(-quartile)
  q2 <- pred %>% 
    filter(quartile==2) %>%
    select(-quartile)
  q3 <- pred %>% 
    filter(quartile==3) %>%
    select(-quartile)
  q4 <- pred %>% 
    filter(quartile==4) %>%
    select(-quartile)
  rm(pred)
  
  
  #separate true values from predicted values
  q1_pred <- q1 %>% select(-actual)
  q1_actual <- q1 %>% select(actual)
  
  q2_pred <- q2 %>% select(-actual)
  q2_actual <- q2 %>% select(actual)
  
  q3_pred <- q3 %>% select(-actual)
  q3_actual <- q3 %>% select(actual)
  
  q4_pred <- q4 %>% select(-actual)
  q4_actual <- q4 %>% select(actual)
  
  #convert from df to matrix
  q1_pred <- as.matrix(q1_pred)
  q2_pred <- as.matrix(q2_pred)
  q3_pred <- as.matrix(q3_pred)
  q4_pred <- as.matrix(q4_pred)
  
  #predict err stats for quartiles
  q1_stats <- data.frame( t(pred_err_stats(q1_pred, q1_actual)))
  q2_stats <- data.frame(t(pred_err_stats(q2_pred, q2_actual)))
  q3_stats <- data.frame(t(pred_err_stats(q3_pred, q3_actual)))
  q4_stats <- data.frame(t(pred_err_stats(q4_pred, q4_actual)))
  
  #contruct quartile dataframe
  q_df <- t(list(q1_stats, q2_stats,q3_stats,q4_stats))
  q_df <- condense( t(q_df))
  colnames(q_df) <- names(q1_stats)
  
  #add quartile tag
  quar <- 1:4
  q_df <- q_df %>% mutate('quartile' = quar)
  return(q_df)
}











