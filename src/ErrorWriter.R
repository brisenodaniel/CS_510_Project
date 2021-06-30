source('Dependencies.R')
source('DataSplitter.R')
source('Buffer.R')
source('ErrorCalculator.R')
source('Model.R')
require('profvis')


# str x str x str x bool x int => SIDE_EFFECT(Write file)
write_errs <- function(folder, file, subset_list, retrain=FALSE, n=50){
	path <- paste0(folder, '/',file)
	err_df <- get_n_errors_on_subset_lst(subset_list,retrain=retrain, n=n)
	if (str_detect(subset_list[[1]],".*q.*")){
		filt <- function(x) str_extract(x,"\\d")
		quartile <- vapply(err_df$subset,filt,"1") 
		err_df <- err_df %>% mutate('quartile'=quartile) %>%
			select(-subset)
	}
	else if (subset_list[[1]] == 'all'){
		err_df <- err_df %>% select(-subset)
	}
	saveRDS(err_df, file=path)
	print(err_df)
}


folder <- "../Output"
elemental_subsets <- c('Fe','Cu','Mg','B2Mg')
quartiles <- c('q1','q2','q3','q4')

write_errs(folder, 
   	   'control_err.rds', 
   	   'all', 
   	   n=2)

write_errs(folder,
           'quartile_err.rds',
           quartiles,
           n=2)

write_errs(folder, 
	   'elemental_err_rt.rds', 
	   elemental_subsets, 
	   retrain=TRUE, 
	   n=2)

write_errs(folder, 
	   'elemental_err_nrt.rds',
	   elemental_subsets,
	   n=2)


write_errs(folder,
	   'output_quartile_errs.rds',
	   'q_out',
	   n=2)

clear_buffer()




