
#trainer: vector(int) x str x int => XGBoost
trainer <- function(train_idx, label='critical_temp', nthreads=4){
	label_values <- as.matrix(train[train_idx,] %>% select(all_of(label)))
	training_data <- as.matrix(train[train_idx,] %>% select(-all_of(label)))
	bst <-  bst <- xgboost(data=training_data,
                 label = label_values,
                 max_depth = 16,
                 nthread= nthreads, 
                 objective = 'reg:squarederror', 
                 eval_metric='rmse',
                 nrounds=best_rounds, 
                 eta= 0.02,
                 min_child_depth = 1, 
                 colsample_bytree = 0.5, 
                 subsample = 0.5,
		 verbose = 0)
	return(bst)
}


#predictor: XGBoost x int => int
predictor <- function(mod, data_idx){
	data_v <-as.matrix(train[data_idx,] %>% select(-"critical_temp"))
	#data_v <- t(data_v)
	pred <- predict(mod,data_v)
	return(pred)
}

#predict_many: XGBoost x vector(int) => vector(int)
predict_many <- function(mod, data_idxs){
	pred <- function(idx) predictor(mod, idx)
	pred_vector <- vapply(data_idxs,pred,1)
	return(pred_vector)
}
