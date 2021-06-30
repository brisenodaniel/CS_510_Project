source("Dependencies.R")

#given an identifying string 
# for a subset, returns the indices
# of train that contain entries belonging
# to that subset
# split_data : str => vector(int)
split_data <- function(subset_id){
	if( str_detect(subset_id, "q.*") ){
		return(split_quart(subset_id))
	}
	else if (subset_id == 'all'){
		return (1:nrow(train))
	}
	else{
		return(split_elem(subset_id))
	}
}


#given an identifying string for an element
# subset, returns the indices of train that 
# contain entries belonging to that subset.
#Param: subset_id: must be one of the following:
#	"Fe", "Cu", "Mg", "B2Mg"
# split_elem : str => vector(int)
split_elem <- function(subset_id){
  idx <- NULL  
  if(subset_id=='B2Mg'){
    rx <- regex('.*B2.*Mg.*',dotall=TRUE)
    idx <- which(str_detect(unique_m$material,rx))
  }
  else{
    idx <- which(unique_m[,subset_id] !=0)
  }
  return(idx)
}

#given an identifying string for a Tc quartile,
# returns the indicies of train that contain
# entries in that Tc quartile.
#Param: subset_id: must be of the following strings:
#	"q1", "q2", "q3", "q4". Strings correspond to
#	the first, second, third and fourth Tc quartiles.
#split_quart: str => vector(int)
split_quart <- function(subset_id){
	train_tile <- train %>% mutate(quartile = ntile(train$critical_temp,4))
	q <- as.numeric(str_extract(subset_id,"\\d"))
	idx <- which(train_tile$quartile == q)
	return(idx)
}


#given a set of indices and a train partition size,
# randomly chooses indices for training and testing
# data.
# Params: idxs: A vector of indices from Train df 
#	train_partition: a number equal to the number
#	 of datapoints in the desired train partition
#	 divided by the total number of datapoints in train.
#partition : vector(int) x int => list( vector(int) x vector(int) )
partition <- function(idxs, train_partition){
	train_idx <- sample(idxs, train_partition*length(idxs))
	test_idx <- setdiff(idxs, train_idx)
	return(list('train'=train_idx, 'test'=test_idx))
}




































