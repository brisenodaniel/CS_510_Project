# Purpose: Split superconductor dataset into subsets based off of 
#	component elements and Tc quartiles. Also provides helper function to split 
#	a dataframe into training and testing data.
# Pre-conditions: 
#	The following dataframes must be loaded into the runtime enviornment from "../Data/tc.RData" :
#		train: A collection of 82 atomic properties for 21263 superconductors. The names of the 
#			superconductors and their component elements are omitted.
#		unique_m: A collection of 21263 superconductor names, critical temperatures, and broken up
#			chemical formulas. The ith row in unique_m corresponds to the ith superconductor in 
#			train.
#	Packages: dplyr
#	All requirements can be satisfied by sourcing "../Dependencies.R"
# Post-conditions: 
#	The following subsets of train and unique_m will be loaded into the runtime enviornment:
#		b2mg_train, b2mg_unique_m: Superconductors containing B2Mg
#		cu_train, cu_unique_m: Curpate superconductors
#		fe_train, fe_unique_m: Superconductors containing Iron
#		hg_train, hg_unique_m: Superconductors containing Mercury
#		train_deciles, unique_m_deciles: Lists of size 10 containing superconductor dataframes divided into deciles.
#			The first index contains the first decile, the second index the second decile, ect.
#		train_quartiles, unique_m_quartiles: List of size 4 containing superconductor dataframes divided into quartiles.
#			The first index contains the first decile, the second index the second decile, ect.
#	The following function will be loaded into the runtime enviornment:
#		Signature: partition :: data_frame x float -> list[data_frame, data_frame] 
#		Desc: Function takes as parameters a data frame and a float less than 1. It returns a list of length 2, containing
#			randomly partitioned training and testing data frames. The sizes of the training and testing partitions are determined by 
#			the numeric parameter.

#TODO: Decile datasets are never used in analysis, and take up a considerable amount of mem - need to be removed. Precense or absence of duplicates
# in data did not substantially affect end results, so managment of duplicates should be removed.
########################### Split by Element #################################################
cutter <- function( elem_list, exclusive = FALSE){
  if (!exclusive) {
    df_train <- train %>% filter(unique_m[,elem_list] != 0)
    df_unique_m <- unique_m %>% filter(unique_m[,elem_list] != 0)
    return(list(df_train, df_unique_m))
  }
  else {
    df_train <- train %>% filter(unique_m[,elem_list] == 0)
    df_unique_m <- unique_m %>% filter(unique_m[,elem_list] == 0)
    return(list(df_train, df_unique_m))
  }
}


############################ Elements with Iron
fe_train <- data.frame(cutter('Fe')[1])
fe_unique_m <- data.frame(cutter('Fe')[2])

############################ Elements with Mercury 
hg_train <- data.frame(cutter('Mg')[1])
hg_unique_m <- data.frame(cutter('Mg')[2])

############################# Cuprates 
cu_train <- data.frame(cutter('Cu')[1])
cu_unique_m <- data.frame(cutter('Cu')[2])

########################## B2Mg
rx <- regex('.*B2.*Mg.*',dotall=TRUE)
b2mg_train <- train %>% filter(str_detect(unique_m$material,rx))
b2mg_unique_m <- unique_m %>% filter(str_detect(unique_m$material,rx))
b2mg_unique_m$material
######################### Split By Tc Quantile #######################



train_tile <- train %>% mutate(decile = ntile(train$critical_temp, 10), 
                               quartile = ntile(train$critical_temp,4))

######################## Deciles
flt <- function(x) filter(train_tile, decile==x)
train_deciles <- lapply(c(1:10),flt)

flt <- function(x) filter(unique_m, train_tile$decile==x)
unique_m_deciles <- lapply(c(1:10),flt)



######################### Quantiles
flt <- function(x) filter(train_tile, quartile==x)
train_quartiles <- lapply(c(1:4), flt)


flt <- function(x) filter(unique_m, train_tile$quartile==x)
unique_m_quartiles <- lapply(c(1:4),flt)

rm(train_tile)
####################### Test and Training Data Functions

# Signature: partition :: data_frame x float -> list[data_frame, data_frame] 
# Desc: Function randomly paritions a dataframe into training and testing data.
# Params: data = data_frame containing all available data for training and 
#		testing.
#	  train_partition: positive float less than one equal to the
#		proportion nrow(train_data)/nrow(data) for the desired 
#		train partition train_data. For example, train_partition=2/3
#		would divide data into 2/3 training data and 1/3 testing data.
# Returns:
#	list('train'=train_dat, 'test'=test_dat): List containing training and
#		testing data partitions, with corresponding labels.
partition <- function(data, train_partition){
  train_idx <- sample(1:nrow(data), train_partition*nrow(data))
  test_idx <- setdiff(1:nrow(data), train_idx)
  train_dat <- data[train_idx,]
  test_dat <- data[test_idx,]
  
  return(list('train'=train_dat, "test"=test_dat))
}









# Found duplicate data in train dataframe
# This might be an error as distinct materials are exteremely unlikely to have
# exactly the same properties. In fact, this may be impossible

# The following code removes all duplicate data from the df



rmDuplicates <- function(data, nms) {
  dupes <- duplicated(data)
  dupes_idx <- which(dupes)
  data_nd <- data[-dupes_idx]
  nms_nd <- nms[-dupes_idx]
  return( list(data_nd, nms_nd) )
}
# 
# unduped <- rmDuplicates(train, unique_m)
# train <- unduped[[1]]
# unique_m <- unduped[[2]]
# head(train)
# head(unique_m)
