##################################### Load Dependencies
source('Dependencies.R')
source('ErrorCalculator.R')
source('Model.R')
source('DataSplitter.R')
######################################### Helper Functions

## The following functions are used throughout this document
##    to format data appropriately for placement in
##    tables and plots
round_df <- function(df, digits){
  ## This function round all numeric vectors in a dataframe
  ## Params:
  ##    df: Dataframe to round
  ##    digits: number of digits to round to. If null function returns
  ##      original dataframe
  ## Returns: df with all numeric vectors rounded to the desired
  ##       digits
  if (is.null(digits))
    return(df)
  numeric_columns <- sapply(df, mode) == 'numeric'
  df[numeric_columns] <- round(df[numeric_columns],digits)
  return(df)
}

flt <- function(df, subset_id){
  ## This function returns a dataframe containing rows in
  ##   in df where the subset attribute is equal to subset_id.
  ##   The returned dataframe will not contain a subset column.
  ## Params:
  ##    df: dataframe to filter, should have a `subset` column
  ##    subset_id: string, the value to filter for
  filtered_df <- df %>%
      filter(subset==subset_id) %>%
      select(-subset)
    return(filtered_df)
}

attach_lbl <- function(vec,subset, digits=2, subset_lbl='Subset'){
  ## This function takes in a single named list and returns a dataframe
  ## containing the original list entries rounded to the number of decimals
  ## determined by the digits param, with an added column containing a
  ## string label determined by the subset param. The name of this column will
  ## be determined by the subset_lbl param.
  ##   Params:
  ##      vec: The list/vector to convert to a dataframe and label
  ##      subset: A string to be inserted into a new column in the dataframe.
  ##          typically, a label indicating which subset of the superconductor
  ##          data the data in vec was collected on.
  ##      digits: An int, the number of digits to round entries in vec to
  ##      subset_lbl: The column name for the new column containing `subset`, defaults
  ##          to 'Subset'
  ##   Returns: A dataframe containing the data in `vec`, with column names equal to the
  ##          names of the entires of `vec`, if specified, and containing a new column
  ##          named `subset_lbl` with entry `subset`.

  ## Add the subset label and convert to a dataframe
  df <- data.frame(t(vec)) %>%
    cbind(subset_lbl = subset) %>%
    round_df(digits)
  return(df)
}

make_numeric <- function(df, digits=NULL){
  ## This function converts all columns in df containing only strings
  ##  representing decimals to numeric types. Additionally, if digits is
  ##  speicified, this function will round all decimal entries in df to
  ##  the specified number of decimal places.
  ##    Params:
  ##       df: Dataframe, must contain only strings as data.
  ##       digits: Number of decimal places to round decimal entires in
  ##         df. If not specified or NULL, no rounding will take place.
  ##    Returns: df, but with all columns containing decimal strings converted
  ##         to numeric type.
  char_idx <- sapply(df,mode)=='character'
  ## check for string entries in dataframe. If none exist, then no entries need
  ## converting to numeric and return the rounded df. Else, continue with conversion
  if (!(TRUE %in% char_idx)){
    df <- round_df(df, digits)
    return(df)
    }
  df_chars <- df[char_idx]
  numeric_regex <- function(str) str_detect(str, "^-?\\d*\\.?\\d*$")
  numeric_cols <- sapply(df_chars, numeric_regex) %>%
    apply(2,all)
  df_chars[, numeric_cols] <- sapply(df_chars[,numeric_cols], as.numeric) %>%
    data.frame %>%
    round_df(digits)
  df[char_idx] <- df_chars
  return(df)
}

make_summary_df <- function(df, digits=NULL){
  ## This function takes in a dataframe as read in from
  ##  the Output folder and outputs a new dataframe
  ##  of the column means of all numeric entries
  ## Params:
  ##   df: Dataframe, must be a dataframe as outputted by
  ##    ErrorWriter.R into the ../Output folder.
  ##   digits: Int, number of decimal places to round numeric
  ##    entries in output dataframe
  ## Returns: A dataframe containing column means of all numeric columns
  ##    in df

  df <- df %>%
    make_numeric %>%
    colMeans(na.rm=TRUE) %>%
    t() %>%
    data.frame() %>%
    round_df(digits) %>%
    select(-correct_cnt)
  return(df)
}


make_subset_summary_df <- function(df, subsets, subset_lbl='subset', digits=NULL){
  ##This function has the same functionality as make_summary_df, but it
  ## first splits the dataframe into subsets determined by the `subsets` parameter,
  ## then takes the means over these subsets.
  ## Params:
  ##   df: Dataframe, must be a datarfame as outputted by ErrorWriter.R into the
  ##       ../Output folder.
  ##   subsets: a list of strings. Each item of this list must correspond to an entry
  ##     in the `subset` column of df. Averages will be taken over the subsets of df
  ##     with `subset` entry equal to each item of `subsets`.
  ##   subset_lbl: string, the name of a new column wich will indicate wich subset each
  ##     row of the output dataframe corresponds to
  ##   digits: int, number of decimal places to round all numeric entries in df.
  ## Returns: A dataframe of rows corresponding to averages taken over each subset, specified
  ##  by the `subsets` param.
  subset_filter <- function(subset) flt(df,subset)
  make_subset_df <- function(df_subset) make_summary_df(df_subset, digits)
  subset_dfs <- sapply(subsets,subset_filter) %>%
    apply(2,data.frame) %>%
    lapply(make_subset_df)
  reattach_subset_lbl <- function(subset){
    subset_dfs[[subset]] <<- subset_dfs[[subset]] %>%
      mutate("{subset_lbl}":=subset)
  }
  subset_dfs <- lapply(subsets,reattach_subset_lbl)
  subset_df <-  condense(subset_dfs)
  return(subset_df)
}


print_table <- function(filename, table){
  ## Function prints a dataframe as a table to a png file in the ../Plots
  ## subdirectory.
  ## Params:
  ##   filename: Name of the png file to be printed into ../Plots
  ##   table: dataframe table to be printed to the png
  file_path <- sprintf('../Plots/%s', filename)
  png(file_path,
      height = 50*nrow(table),
      width = 80*ncol(table))
  grid.table(table)
  dev.off()
}
############################################## Import Data

##Data collected from testing model on entire dataset of superconductors
control <- readRDS('../Output/control_err.rds')
##Data collected from testing model on each superconductor Tc quartile separately
decile <- readRDS('../Output/decile_err.rds')
##Data collected from testing model on each element subset (Fe, Hg, Cu, B2Mg2) separately
##when model is trained on an unrestricted set of superconductors
elemental_nrt <- readRDS('../Output/elemental_err_nrt.rds')
##Data collected from testing model on each element subset (Fe, Hg, Cu, B2Mg2) separately
##when the model is trained only on superconductors from each element subset
elemental_rt <- readRDS('../Output/elemental_err_rt.rds')
##Data collected from testing model on each predicted Tc quartile separately
predicted_quartile<- readRDS('../Output/output_quartile_errs.rds')
##Data collected from testing model on each true Tc quartile separately
quartile <- readRDS('../Output/quartile_err.rds')

########################################## Generate Summary Data Tables and Print to Png
## Control data (entire dataset)
control_df <- make_summary_df(control,3)
print_table('control_tbl', control_df)
##### Element Subsets
element_subsets <- c('Fe', 'Hg', 'Cu', 'B2Mg')
## No retrain
element_nrt_df <- make_subset_summary_df(elemental_nrt,
                                          element_subsets,
                                          subset_lbl="Element",
                                          digits=3)
print_table('element_no_retrain_tbl', element_nrt_df)

## Retrain
element_rt_df <- make_subset_summary_df(elemental_rt,
                                         element_subsets,
                                         subset_lbl="Element",
                                         digits=3)
print_table('element_retrain_tbl', element_rt_df)

##### Decile data
decile_df <-  make_subset_summary_df(decile,
                                      1:10,
                                      subset_lbl="Decile",
                                      digits=3)
print_table('decile_tbl', decile_df)

##### Quartile data
##True Tc Quartile
quartile_true_df <-  make_subset_summary_df(quartile,
                                             1:4,
                                             subset_lbl='Quartile',
                                             digits=3)
print_table('quartile_true_tbl', quartile_true_df)

##Predicted Tc Quartile
quartile_pred_df <- make_subset_summary_df(predicted_quartile,
                                            1:4,
                                            subset_lbl='Quartile',
                                            digits=3)
print_table('quartile_pred_tbl', quartile_pred_df)

######################################### Plot Generation

###### Plot the critical temperature (Tc) distribution of the data

ggplot(train, aes(x=critical_temp)) +
  geom_density() +
  labs(x='Critical Temperature (Tc)') +
  ggtitle('Distribution of Superconductor Critical Temperature (Tc)')
ggsave('../Plots/Tc_dist.png')

###### Residuals density plot (check for normally distributed errors)

control_ave_err <- select(control, ave_err)
ggplot(control_ave_err, aes(x=ave_err)) +
  geom_density(adjust=0.8) + 
  labs(x='Average Raw Error') + 
  xlim(-1,1) + 
  ggtitle("Distribution of Average Raw Errors") + 
  theme(plot.title=element_text(size=15))

ggsave('../Plots/control_ave_err_density.png')

###### Distribution of predicted and true Tc value comparison

###Generate predictions for a single train/test data partition
##Take data partition
part_idxs  <-  partition(1:nrow(train),2/3)
##Train XGboost regression tree
bst <- trainer(part_idxs[['train']])
##make predictions and extract true label values
pred <- predict_many(bst, part_idxs[['test']]) %>%
  data.frame
actual <- train[part_idxs[['test']],] %>% select(critical_temp)
##Add labels to the data for ploting purposes
label_pred <- rep_len('Predicted', nrow(pred))
label_true <- rep_len('Actual', nrow(pred))
plt_pred <- cbind('critical_temp'=pred, 'label'=label_pred)
plt_true <- cbind('critical_'=actual, 'label'=label_true)
names(plt_pred) <- names(plt_true)
plt_data <- rbind(plt_pred, plt_true)

##Make density plot
ggplot(plt_data) +
  geom_density(aes(x=critical_temp, color=label)) +
  labs(color="", x="Critical Temperature") +
  ggtitle("Actual Critical Temperature Distribution vs Predicted") +
  theme(plot.title=element_text(size=12))
ggsave('../Plots/Actual_vs_Pred_dist.png')

########Make side-by-side bar plots of RMSE and SD of error for
########element subsets in both the retraining and no retraining conditions

make_element_plot <- function(ave_df, title_rmse, title_sd, title_plt){
  ##Build the RMSE barplot
  element_RMSE_plt <- ggplot(ave_df, aes(x=Element, y=RMSE)) +
    geom_col(aes(fill=Element)) +
    theme(legend.position = 'none') +
    geom_hline(yintercept = 9.5,linetype='dashed') +
    geom_text(aes(3.8,9.5,label='Control RMSE',vjust=-1)) + 
    ggtitle(title_rmse) +
    theme(plot.title=element_text(size=15))

  ##Build the SD barplot
  element_SD_ERR_plt <- ggplot(ave_df, aes(x=Element, y=std_err))+
    geom_col(aes(fill=Element)) +
    theme(legend.position = 'none') +
    labs(y="Standard Deviation of Error")+
    geom_hline(yintercept = 8.099,linetype='dashed') +
    geom_text(aes(3.8,8.099,label='Control Err SD',vjust=-1)) + 
    ggtitle(title_sd) +
    theme(plot.title=element_text(size=13))

  ##Combine barplots into single side-by-side pdf and print
  hlay <- rbind(c(1,1,1,1,1,1,NA,2,2,2,2,2,2),
                c(1,1,1,1,1,1,NA,2,2,2,2,2,2),
                c(1,1,1,1,1,1,NA,2,2,2,2,2,2))

  pdf(file=sprintf('../Plots/%s', title_plt),
      width=10,
      height=5)
  grid.arrange(element_RMSE_plt, element_SD_ERR_plt, layout_matrix = hlay)
  dev.off()
}

##No retraining condition
make_element_plot(element_nrt_df,
                  'XGBoost RSME Without Retraining',
                  'XGBoost SD of Error Without Retraining',
                  'Element_ntr_brplt.pdf')

##Retraining condition
make_element_plot(element_rt_df,
                  'XGBoost RMSE With Retraining',
                  'XGBoost SD of Error With Retraining',
                  'Element_rt_brplt.pdf')

#########Make barplot comparing performance of the retraining and no retraining
#########conditions

##add training condition labels to the residuals
nrt_plt_data <- mutate(element_nrt_df, Train='No Retrain')
rt_plt_data <- mutate(element_rt_df, Train='Retrain')
element_plt_data <- rbind(nrt_plt_data, rt_plt_data)


## Build RMSE comparison plot

element_RMSE_plt <- ggplot(element_plt_data, aes(y=RMSE, x=Element, fill=Train)) +
  geom_col(position='dodge')+
  theme(legend.position='none') +
  geom_hline(yintercept=9.5, linetype='dashed') +
  geom_text(aes(4.02,9.5,label='Control RMSE', vjust=-1)) +
  labs(y='Standard Deviation of Error') + ggtitle('XGBoost RMSE') +
  theme(plot.title = element_text(size=15))

##Build SD comparison plot
element_SD_ERR_plt <- ggplot(element_plt_data, aes(y=std_err, x=Element, fill=Train)) +
  geom_col(position='dodge') + labs(fill= 'Train Condition') + 
  geom_hline(yintercept = 9.5,linetype='dashed') +
  geom_text(aes(3.9,8.099,label='Control Err SD',vjust=-4.2)) +
  labs(y="Standard Deviation of Error")+ ggtitle('XGBoost SD of Error')+
  theme(plot.title = element_text(size=15))

##Put both plots in one side-by-side image and print to the ../Plots directory
hlay <- rbind(c(1,1,1,1,1,1,1,NA,2,2,2,2,2,2,2,2,2),
              c(1,1,1,1,1,1,1,NA,2,2,2,2,2,2,2,2,2),
              c(1,1,1,1,1,1,1,NA,2,2,2,2,2,2,2,2,2))
pdf(file='../Plots/Element_comparison_bxplt.pdf',
    width = 10,
    height =5)
grid.arrange(element_RMSE_plt, element_SD_ERR_plt, layout_matrix=hlay)
dev.off()


##########Plot RMSE, SD of error and Average error alongside each other in a barplot
##########for quartile data

#####Helper functions for quartile data plotting

format_quartile_error_data <- function(df){
  ##This function puts RSME, SD of error and the absolute
  ##value of average error from df into a new df in long format,
  ##with an added column indicating the type of error metric shown
  ##in each row
  quartile_rmse <- df %>%
    select(RMSE, Quartile) %>%
    mutate('error_metric'='RMSE')
  quartile_ave <- df %>%
    select(ave_err, Quartile) %>%
    abs() %>%
    mutate('error_metric'='Ave')
  quartile_sd <- df %>%
    select(std_err, Quartile) %>%
    mutate('error_metric'='SD')
  colnames(quartile_rmse) <- c('error_value',
                               'quartile',
                               'error_metric')
  colnames(quartile_ave) <- colnames(quartile_rmse)
  colnames(quartile_sd) <- colnames(quartile_ave)
  quartile_plt_data <- rbind(quartile_rmse,
                             quartile_ave,
                             quartile_sd)
}

print_quartile_error_barplot <- function(df, plt_title, fig_title){
  ##This function plots the absolute value of error, standard deviation of
  ##error and RMSE alongside each other in a barplot for quartile error data

  ##put data into long format
  df_plt <- format_quartile_error_data(df)
  ##build plot
  ggplot(df_plt, aes(y=error_value, x=quartile, fill=error_metric)) +
    geom_col(position='dodge') +
    geom_hline(yintercept = 9.5,linetype='dashed') +
    geom_text(aes(1.05,9.5,label='Control RMSE',vjust=-1)) +
    labs(y="Error Value", x='Quartile', fill='Error Metric')+
    ggtitle(plt_title)+
    theme(plot.title = element_text(size=15))
  ggsave(sprintf('../Plots/%s',fig_title))
}

##plot True Tc Quartile error data
print_quartile_error_barplot(quartile_true_df,
                             'RMSE, SD, and Average Error Over Quartiles',
                             'True_Q_error_brplt.png')

##Plot Predicted Tc Quartile error data
print_quartile_error_barplot(quartile_pred_df,
                             'RMSE, SD, and Average Error Over Predicted Quartiles',
                             'Pred_Q_error_brplt.png')
