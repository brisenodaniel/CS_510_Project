build_table <- function(subset_list,df){
	subset_col <- ncol(df)
	subset_type <- colnames(df)[subset_col]
	df <- make_numeric(df,subset_col, subset_type)
	ave_dispatch <- function(subset_id) subset_ave(subset_id,
						       subset_col,
						       subset_type,
						       df)
	ave_df <- lapply(subset_list,ave_dispatch) %>%
		condense(ave_list) %>%
		round_df(3)
}

make_numeric <- function(df,subset_col,subset_type){
	df <- sapply(df[,-subset_col],as.numeric) %>%
		data.frame() %>%
		mutate('{subset_type}' := df[,subset_col])
}

subset_ave <- function(subset_id, subset_col, subset_type, df){
	df <- df %>% filter(!!as.name(subset_type) == subset_id) %>%
		select(-!!as.name(subset_type))
	df_ave <- colMeans(df) %>% 
		t() %>%
		data.frame()
	df_ave <- df_ave %>% mutate(!!as.name(subset_type) = subset_id)
}
