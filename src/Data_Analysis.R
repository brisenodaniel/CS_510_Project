# Purpose: Use data in ./Output subdirectory to make graphs and 
#	summary tables.
# Preconditions: ./Get_RMSE.R has run to completetion and has successfully populated
#	the Output subdirectory.
# Postconditions: The following files will be written to the ./Plots subdirectory:
#	Actual_vs_Pred_dist.png: Actual test partition $T_c$ distribution plotted
#		alongside the predicted $T_c$ distribution.
#	control_ave_err_density.png: Density plot of average raw errors. 
#		Raw error averages were taken from the 50 error vectors collected 
#		for the control data.
#	Pred_Q_Ave_brplt.png: RMSE, standard deviation of error, and the average 
#		of raw error plotted alongside each other for each predicted $T_c$
#		quartile.
#	Tc_dist.png: Density plot of $T_c$ values for all superconductors in dataset.
#	True_Q_brplt.png: RSME, standard deviation of error, and the average of raw 
#		errors plotted alongside each other for each true $T_c$ quartile.
#	Elemental_comparison_bxplt.pdf: Comparison of RMSE and Standard deviation 
#		between retraining and no-retraining conditions
#	Elemental_nrt_bxplt.pdf: RMSE and standard deviation of error on the element
#		subsets without retraining XGBoost on the element subsets. The RMSE 
#		and standard deviation of error for the control data are indicated 
#		with dashed lines.
#	Control_tbl.png: Average error statistics from the 50 control data error 
#		vectors. These error vectors were collected according to data 
#		collection process i, with no subsets of the data being taken.
#	Elemental_ntr_ave_tbl.png: Average error statistics from 50 error vectors
#		per element subset. The error vectors were collected according to 
#		process i.
#	Elemental_rt_ave_tbl.png: Average error statistics from 50 error vectors per 
#		element subset. The error vectors were collected according to process i.
#		In this case, XGBoost was retrained on the elemental subsets. 
#	quart_pred_ave_tbl.png: Average error statistics from 50 error vectors
#		collected for each predicted $T_c$ quartile.
#	quart_true_ave_tbl.png: Average error statistics from 50 error vectors
#		collected for each true $T_c$ quartile.
#	
#	
# TODO:
# 	Code was written ad-hoc with the goal of generating then exporting plots. Needs to be
#	re-written with more structure.
require(tidyverse)
require(gridExtra)
require(cowplot)
source('Dependencies.R')
source('Data_Splitter.R')
source('Model.R')
source('RMSE_Calculator.R')

round_df <- function(x, digits) {
  # round all numeric variables
  # x: data frame 
  # digits: number of digits to round
  numeric_columns <- sapply(x, mode) == 'numeric'
  x[numeric_columns] <-  round(x[numeric_columns], digits)
  x
}

control <- readRDS('../Output/control_err.rds')
colnames(control)[1]='RMSE'
decile <- readRDS('../Output/decile_err.rds')
colnames(decile)[1] = 'RMSE'
elemental_nrt <- readRDS('../Output/elemental_err_n_rt.rds')
colnames(elemental_nrt)[1] = 'RMSE'
elemental_rt <- readRDS('../Output/elemental_err_rt.rds')
colnames(elemental_rt)[1] = 'RMSE'
pred_q <- readRDS('../Output/output_quartile_errs.rds')
colnames(pred_q)[1]='RMSE'
quart <- readRDS('../Output/quartile_err.rds')
colnames(quart)[1] = 'RMSE'



##########################Get control averages
control_df <- control %>%
  select(-subset)
control_df <- data.frame(sapply(control_df, as.numeric))
control_ave <- data.frame(t(colMeans(control_df, na.rm = TRUE)))
control_toprint <- control_ave %>% 
  select(-control)%>%
  select(-correct_cnt) %>%
  round_df(3)

png('../Plots/Control_tbl.png',
    height = 50*nrow(control_toprint), 
    width = 80*ncol(control_toprint))
grid.table(control_toprint)
dev.off()
##########################split up the elemental subsets
##################No Retrain

#helper function
flt <- function(x){
  df <- elemental_nrt %>%
    filter(subset == x) %>%
    select(-subset)
  df <- sapply(df, as.numeric)
}

fe_nrt <- flt('Fe')
hg_nrt <- flt('Hg')
cu_nrt <- flt('Cu')
b2mg_nrt <- flt('B2Mg')

#get mean values
fe_nrt_ave <- colMeans(fe_nrt, na.rm = TRUE)
hg_nrt_ave <- colMeans(hg_nrt, na.rm = TRUE)
cu_nrt_ave <- colMeans(cu_nrt, na.rm = TRUE)
b2mg_nrt_ave <- colMeans(b2mg_nrt, na.rm = TRUE)

#re-attach labels
attach_lbl <- function(vec,subset){
  df <- cbind(t(vec),'Subset' = subset)
  df <- data.frame(df)
  df[,-12] <- as.numeric(df[,-12])
  return(df)
}
fe_nrt_ave <- attach_lbl(fe_nrt_ave, 'Fe')
hg_nrt_ave <- attach_lbl(hg_nrt_ave, 'Hg')
cu_nrt_ave <- attach_lbl(cu_nrt_ave, 'Cu')
b2mg_nrt_ave <- attach_lbl(b2mg_nrt_ave,'B2Mg')
elemental_nrt_ave <- condense(list(fe_nrt_ave,hg_nrt_ave,cu_nrt_ave,b2mg_nrt_ave)) %>%
  round_df(3) %>%
  select(-correct_cnt) %>%
  select(-control)


png('../Plots/Elelmental_nrt_ave_tbl.png',
    height = 50*nrow(elemental_nrt_ave), 
    width = 80*ncol(elemental_nrt_ave))
grid.table(elemental_nrt_ave)
dev.off()
###############With Retrain
#helper function
flt <- function(x){
  df <- elemental_rt %>%
    filter(subset == x) %>%
    select(-subset)
  df <- sapply(df, as.numeric)
}

fe_rt <- flt('Fe')
hg_rt <- flt('Hg')
cu_rt <- flt('Cu')
b2mg_rt <- flt('B2Mg')

fe_rt_ave <- colMeans(fe_rt, na.rm = TRUE)
hg_rt_ave <- colMeans(hg_rt, na.rm = TRUE)
cu_rt_ave <- colMeans(cu_rt, na.rm = TRUE)
b2mg_rt_ave <- colMeans(b2mg_rt, na.rm = TRUE)



#Generate table
attach_lbl <- function(vec,subset){
  df <- cbind(t(vec),'Subset' = subset)
  df <- data.frame(df)
  df[,-12] <- as.numeric(df[,-12])
  return(df)
}

fe_rt_ave <- attach_lbl(fe_rt_ave, 'Fe')
hg_rt_ave <- attach_lbl(hg_rt_ave, 'Hg')
cu_rt_ave <- attach_lbl(cu_rt_ave, 'Cu')
b2mg_rt_ave <- attach_lbl(b2mg_rt_ave,'B2Mg')
elemental_rt_ave <- condense(list(fe_rt_ave,hg_rt_ave,cu_rt_ave,b2mg_rt_ave)) %>%
  round_df(3) %>%
  select(-correct_cnt) %>%
  select(-control)


png('../Plots/Elelmental_rt_ave_tbl.png',
    height = 50*nrow(elemental_rt_ave), 
    width = 80*ncol(elemental_rt_ave))
grid.table(elemental_rt_ave)
dev.off()

################################Get True T_c Quartile Averages
flt <- function(x){
  df <- quart %>%
    filter(subset == x) %>%
    select(-subset)
  df <- sapply(df, as.numeric)
}

attach_lbl <- function(vec,q){
  df <- cbind(t(vec),'Quartile' = q)
  df <- data.frame(df)
  return(df)
}

q1_true <- flt('1')
q2_true <- flt('2')
q3_true <- flt('3')
q4_true <- flt('4')

q1_true_ave <- colMeans(q1_true) %>% attach_lbl(1)
q2_true_ave <- colMeans(q2_true) %>% attach_lbl(2)
q3_true_ave <- colMeans(q3_true) %>% attach_lbl(3)
q4_true_ave <- colMeans(q4_true) %>% attach_lbl(4)

quart_true_ave <- condense(list(q1_true_ave, q2_true_ave, q3_true_ave, q4_true_ave))%>%
  round(3) %>%
  select(-correct_cnt)

png('../Plots/quart_true_ave_tbl.png',
    height = 50*nrow(quart_true_ave), 
    width = 80*ncol(quart_true_ave))
grid.table(quart_true_ave)
dev.off()

#################################Get Predicted T_c Quartile Averages
flt <- function(x){
  df <- pred_q %>%
    filter(quartile == x) %>%
    select(-quartile) %>%
    select(-Trial)
}


q1_pred <- flt('1')
q2_pred <- flt('2')
q3_pred <- flt('3')
q4_pred <- flt('4')

q1_pred_ave <- colMeans(q1_pred)
q2_pred_ave <- colMeans(q2_pred)
q3_pred_ave <- colMeans(q3_pred)
q4_pred_ave <- colMeans(q4_pred)



q1_pred_ave <- colMeans(q1_pred) %>% attach_lbl(1)
q2_pred_ave <- colMeans(q2_pred) %>% attach_lbl(2)
q3_pred_ave <- colMeans(q3_pred) %>% attach_lbl(3)
q4_pred_ave <- colMeans(q4_pred) %>% attach_lbl(4)

quart_pred_ave <- condense(list(q1_pred_ave, q2_pred_ave, q3_pred_ave, q4_pred_ave))%>%
  round(3) %>%
  select(-correct_cnt)

png('../Plots/quart_pred_ave_tbl.png',
    height = 50*nrow(quart_pred_ave), 
    width = 80*ncol(quart_pred_ave))
grid.table(quart_pred_ave)
dev.off()


#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Plots

#T_c Distribution of the data

train$critical_temp
ggplot(train, aes(x=critical_temp)) + geom_density() + labs(x='Critical Temperature')
ggsave('../Plots/Tc_dist.png')
#ggplot(train, aes(x=critical_temp)) + geom_boxplot()


############################# Confirmation of Systemic errors

#First identify systemic error in control dataset

#If errors are random, then we should see that the average raw error is
#approximately normally distributed around 0

control_ave_err <- select(control_df,ave_err)
class(control_ave_err)
ggplot(control_ave_err, aes(x=ave_err)) +
  geom_density(adjust=0.8) + 
  labs(x='Average Raw Error') + 
  xlim(-5.4,0) + 
  ggtitle("Distribution of Average Raw Errors") + 
  theme(plot.title=element_text(size=15))

ggsave('../Plots/control_ave_err_density.png')

#instead of that we see a distribution extremely centered around -4.998
#and not remotely close to centered at 0. Thus we see a significant 
#systemic error towards underprediction


#To further characterize the systemic error we can plot the distribution
# of predicted and actual Tc values
#T_c Distrubution of prediction vs actual for one run over testing data
part  <-  partition(train,2/3)
bst <- trainer(part[['train']],'critical_temp')
test <- part[['test']] %>% select(-critical_temp)
pred <-data.frame( predict_vector(bst,test))
actual <- part[['test']] %>% select(critical_temp)
label_pred <- rep_len('Predicted', nrow(pred))
label_true <- rep('Actual', times = nrow(pred))

plt_pred <- cbind("critical_temp"=pred, "label" = label_pred)
plt_true <- cbind('critical_temp'=actual, 'label'=label_true)
names(plt_pred) <- names(plt_true)
plt_data <- rbind(plt_pred, plt_true)


ggplot(plt_data) + 
  geom_density(aes(x=critical_temp, color=label)) + 
  labs(color="", x="Critical Temperature") +
  ggtitle("Actual Critical Temperature Distribution vs Predicted") +
  theme(plot.title=element_text(size=12))
ggsave('../Plots/Actual_vs_Pred_dist.png')

#And we see that XGBoost overestimates the number of superconductors with
#very low Tc. XGBoost does identify a cluster of moderatley high Tc conductors
#, but underestimates the Tc at which this cluster occurs.


# Moreover, we see that the standard deviation of errors is 8.099,
#meaning that there is likely still a bit of random error, and XGBoost optimized
#to remove the systemic bias would still likely have a RMSE of approx 9.518, which is 
#why the algorithm trained as is did not identify this bias, as the target metric was
#RMSE



#Analysis of elemental subsets

#No Retraining

elemental_nrt_ave

elemental_RMSE_nrt_plt <- ggplot(elemental_nrt_ave, aes(x=Subset, y=RMSE)) + geom_col(aes(fill=Subset)) +
  theme(legend.position = 'none') +
  geom_hline(yintercept = 9.5,linetype='dashed') +
  geom_text(aes(3.8,9.5,label='Control RMSE',vjust=-1)) + 
  ggtitle('XGBoost RMSE Without Retraining') +
  theme(plot.title=element_text(size=15))




elemental_SD_ERR_nrt_plt <- ggplot(elemental_nrt_ave, aes(x=Subset, y=std_err)) + geom_col(aes(fill=Subset)) +
  theme(legend.position = 'none') +labs(y="Standard Deviation of Error")+
  geom_hline(yintercept = 8.099,linetype='dashed') +
  geom_text(aes(3.8,8.099,label='Control Err SD',vjust=-1)) + 
  ggtitle('XGBoost SD of Error Without Retraining') +
  theme(plot.title=element_text(size=13))


hlay <- rbind(c(1,1,1,1,1,1,NA,2,2,2,2,2,2),
              c(1,1,1,1,1,1,NA,2,2,2,2,2,2),
              c(1,1,1,1,1,1,NA,2,2,2,2,2,2))

pdf(file='../Plots/Elemental_nrt_bxplt.pdf',
    width=10,
    height=5)
grid.arrange(elemental_RMSE_nrt_plt, elemental_SD_ERR_nrt_plt, layout_matrix = hlay)
dev.off()


########With Retraining
elemental_rt_ave
elemental_nrt_ave

#combine both datasets into a single with Retrain Tag
nrt <- rep_len('No Retrain', 4)
rt <-  rep_len('Retrain',4)
elemental_rt_plt <- cbind(elemental_rt_ave,'Train' = rt)
elemental_nrt_plt <- cbind(elemental_nrt_ave, 'Train' = nrt)
elemental_plt <- rbind(elemental_rt_plt, elemental_nrt_plt)

elemental_RMSE_plt <- ggplot(elemental_plt, aes(y=RMSE, x=Subset, fill=Train)) +
  geom_col(position='dodge') + theme(legend.position = 'none') + 
  geom_hline(yintercept = 9.5,linetype='dashed') +
  geom_text(aes(4.02,9.5,label='Control RMSE',vjust=-1)) +
  labs(y="Standard Deviation of Error")+ ggtitle('XGBoost RMSE')+
  theme(plot.title = element_text(size=15))


elemental_SD_ERR_plt <- ggplot(elemental_plt, aes(y=std_err, x=Subset, fill=Train)) +
  geom_col(position='dodge') + labs(fill= 'Train Condition') + 
  geom_hline(yintercept = 9.5,linetype='dashed') +
  geom_text(aes(3.9,8.099,label='Control Err SD',vjust=-4.2)) +
  labs(y="Standard Deviation of Error")+ ggtitle('XGBoost SD of Error')+
  theme(plot.title = element_text(size=15))
hlay <- rbind(c(1,1,1,1,1,1,1,NA,2,2,2,2,2,2,2,2,2),
              c(1,1,1,1,1,1,1,NA,2,2,2,2,2,2,2,2,2),
              c(1,1,1,1,1,1,1,NA,2,2,2,2,2,2,2,2,2))
pdf(file='../Plots/Elemental_comparison_bxplt.pdf',
    width = 10,
    height =5)
grid.arrange(elemental_RMSE_plt, elemental_SD_ERR_plt, layout_matrix=hlay)
#dev.copy(pdf, '../Plots/Elemental_comparison_bxplt.pdf')
dev.off()
#In conclusion, XGBoost preforms better on Fe, Hg, worse on B2Mg, Cu. 
#Improvement in Hg is surprising, considering its distribution
#In general, it is not desirable to re-train. Only B2Mg showed improvements
#when retraining, and these improvements were minimal compared to the loss of predictive 
#power for Cu, Fe, and Hg
#Thus, for the XGBoost algorithm, the generality of the algorithm does not come with a 
#cost, rather a benefit for these subsets
  


################################Analysis of True Tc Quartiles


#As would be expected from the underpredicion bias, the table shows that 
#XGBoost performs increasingly bad for higher Tc quartiles.
#Surprisingly however, the best predictions are not in the inner quartiles,
#but in the lowest quartile. This shows a serious underprediction problem.

##plot RMSE alongside absolute value of average error
#construct df containing ave_err and RMSE in long format
rsme <- rep_len('RMSE',nrow(quart_true_ave))
avrg <- rep_len('Ave',nrow(quart_true_ave))
stdev <- rep_len('SD', nrow(quart_true_ave))
quart_t_rmse <- select(quart_true_ave,RMSE) %>%
  cbind('Quartile'=quart_true_ave$Quartile,'error_metric' = rsme)

quart_t_ave <- quart_true_ave %>%
  select(ave_err) %>%
  abs() %>%
  cbind('Quartile' = quart_true_ave$Quartile, 'error_metric'=avrg)

quart_t_std <- quart_true_ave %>%
  select(std_err) %>%
  cbind('Quartile' = quart_true_ave$Quartile, 'error_metric'=stdev)

colnames(quart_t_ave) <- c('error_value','quartile','error_metric')
colnames(quart_t_rmse) <- colnames(quart_t_ave)
colnames(quart_t_std) <- colnames(quart_t_ave) 

quart_err_plt <- rbind(quart_t_rmse, quart_t_ave,quart_t_std)

#plot
ggplot(quart_err_plt, aes(y=error_value, x=quartile, fill=error_metric)) +
  geom_col(position='dodge') + 
  geom_hline(yintercept = 9.5,linetype='dashed') +
  geom_text(aes(1.05,9.5,label='Control RMSE',vjust=-1)) +
  labs(y="Error Value", x='Quartile', fill='Error Metric')+ ggtitle('RMSE, SD, and Average Error Over Quartiles')+
  theme(plot.title = element_text(size=15))

ggsave('../Plots/True_Q_Ave_brplt.png')


#############Motivated by trends seen in the quartiles of the true Tc values,
# I seek a similar trend but in the predicted Tc values, since this would be
# our only hope of a quick fix


rsme <- rep_len('RMSE',nrow(quart_pred_ave))
avrg <- rep_len('Ave',nrow(quart_pred_ave))
stdev <- rep_len('SD', nrow(quart_pred_ave))
quart_p_rmse <- select(quart_pred_ave,RMSE) %>%
  cbind('Quartile'=quart_pred_ave$Quartile,'error_metric' = rsme)

quart_p_ave <- quart_pred_ave %>%
  select(ave_err) %>%
  abs() %>%
  cbind('Quartile' = quart_pred_ave$Quartile, 'error_metric'=avrg)

quart_p_std <- quart_pred_ave %>%
  select(std_err) %>%
  cbind('Quartile' = quart_pred_ave$Quartile, 'error_metric'=stdev)

colnames(quart_p_ave) <- c('error_value','quartile','error_metric')
colnames(quart_p_rmse) <- colnames(quart_p_ave)
colnames(quart_p_std) <- colnames(quart_p_ave) 

quart_err_plt <- rbind(quart_p_rmse, quart_p_ave,quart_p_std)

#plot
ggplot(quart_err_plt, aes(y=error_value, x=quartile, fill=error_metric)) +
  geom_col(position='dodge') + 
  geom_hline(yintercept = 9.5,linetype='dashed') +
  geom_text(aes(1.05,9.5,label='Control RMSE',vjust=-1)) +
  labs(y="Error Value", x='Quartile',fill='Error Metric')+ ggtitle('RMSE, SD, and Average Error Over Predicted Quartiles')+
  theme(plot.title = element_text(size=15))

ggsave("../Plots/Pred_Q_Ave_brplt.png")


tc <- train$critical_temp
tc <- data.frame('critical_temp'=tc)
ggplot(tc, aes(x=critical_temp)) + geom_density() + labs(x='Critical Temperature')+
  ggtitle('Distribution of Superconductor Critical Temperatures') + xlim(0,NA)

ggsave("../Plots/Tc_dist.png")

