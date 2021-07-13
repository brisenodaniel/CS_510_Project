#buffer stores entires of the form (XGBoost model, test indices)
#	train indices can be inferred from the test indices
#	so they are not included in the buffer
buffer_store <- list() #buffer mutable variable

#buffer: int => list( list( XGBoost x vector(int) ) )
buffer <- function(nreps){
	if( length(buffer_store) < nreps ){
		buffer_store <<- lapply(1:nreps, build_buffer)
	}
	return(buffer_store)
}

#build_buffer: int => list( XGBoost x vector(int) ) 
build_buffer <- function(n){
	buffer_entry <- list()
	if(n>length(buffer_store)){
		idxs <- partition(1:nrow(train), 2/3)
		mod <- trainer(idxs[['train']], nthreads=6)
		test_idx <- idxs[['test']]
		buffer_entry <- list('model'=mod,
				     'test_idx'= test_idx)
	}
	else{
		buffer_entry <- buffer_store[[n]]
	}
	return(buffer_entry)
}

#extract_buffer: list(XGBoost x vector(int)) =>
#	list(XGBoost x vector(int) x vector(int))
extract_buffer <- function(buffer_entry){
	train_idx <- setdiff(1:nrow(train),
			     buffer_entry[['test_idx']])
	buffer_entry <- list.append(buffer_entry, 
				    'train_idx'=train_idx)
	return(buffer_entry)
}

#clear_buffer: None => SIDE_EFFECT
clear_buffer <- function(){
	buffer_store <<- list()
	#gc()
}

