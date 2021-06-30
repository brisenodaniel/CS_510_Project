#vector(str) x bool x int => df( df(err_vect x str))
get_n_errors_on_subset_lst <- function(subset_list, retrain=FALSE, n=50){
	errs_dispatch <- function(subset){
		get_n_errors_on_subset(subset, retrain, n)
	}
	return( lapply(subset_list, errs_dispatch) %>% condense() )
}

#str x bool x int => df(err_vect ++ str)
get_n_errors_on_subset <- function(subset_id, retrain, n){
	err_dispatch <- function(buffer_entry) get_error_on_subset(subset_id,
								 retrain,
								 buffer_entry)
	buf <-  buffer(n)
	errs <- lapply(buf, err_dispatch)
	return ( condense(errs) )
}

#str x bool x list(XGBoost x vector(int)) => df( err_vect ++ str )
get_error_on_subset <- function(subset_id, retrain, buffer_entry){ 
	err_vect <- NULL
	if(str_detect(subset_id, ".*out$")){
		err_df <- get_error_output_quartile(buffer_entry)
		return(err_df)
	}
	else{
		subset_idx <- split_data(subset_id)
		test_idx <- intersect(buffer_entry[['test_idx']],
				      subset_idx)
		train_idx <- extract_buffer(buffer_entry)[['train_idx']] %>%
			intersect(subset_idx)
		model <- buffer_entry[['model']]
		err_vect <- get_error(test_idx, train_idx, model, retrain) %>%
			list.append('subset'=subset_id)
		return(data.frame(err_vect))
	}
}

#vector(int) x vector(int) x XGBoost x Boolean => error_vector
get_error <- function(test_idx, train_idx, model, retrain){
	if(retrain){
		model <- trainer(train_idx)
	}
	pred <- predict_many(model, test_idx)
	actual <- train[test_idx,] %>%
		pull('critical_temp')
	return(	pred_err_stats(pred, actual) )
}

# list( XGBoost x vector(int) ) => df( err_vect ++ str )
get_error_output_quartile <- function(buffer_entry){
	#obtain predicted and true Tc values
	model <- buffer_entry[['model']]
	test_idx <- buffer_entry[['test_idx']]
	pred <- predict_many(model, test_idx) %>% 
		data.frame()
	actual_Tc <- train[test_idx,] %>%
		select('critical_temp') %>% 
		pull(1)

	#attach actual Tc values to predictions and label quartiles
	pred <- pred %>% mutate(actual=actual_Tc) %>%
		mutate(quartile=ntile(pred,4))

	
	errs_dispatch <- function(n_quart){
		extract_output_quartile(n_quart, pred)
	}
	
	errs <- lapply(1:4, errs_dispatch)
	return( condense(errs) )
}

#int x df( int x int x int ) => err_vect ++ str
extract_output_quartile <- function( n_quart, data){
	q <- data %>% 
		filter(quartile==n_quart) %>%
		select(-quartile)
	q_pred <- q %>% 
		select(-actual) %>% 
		pull(1)
	q_actual <- q %>% 
		select(actual) %>%
		pull(1)
	err_vect <- pred_err_stats(q_pred, q_actual) %>%
		list.append('subset'=toString(n_quart))
	return(err_vect)
}

# obtain summary error rate statistics for given prediction vector
#vector(numeric) x vector(numeric) => list(numeric) 
pred_err_stats <- function(pred, actual){
	#obtain rmse
	rmse_full <- rmse(pred, actual)
  
	#obtain mean error and std of error
	raw_diff <- pred - actual
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
	ret_vect <- list(
		'RMSE' = rmse_full,
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

#list( df ) => df
condense <- function(df_list){
	df <- data.frame()
	for (i in 1:length(df_list)){
		df <- rbind(df, df_list[[i]])
	}
	return(df)
}
