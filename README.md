# CS 510 Project #
## Author: Daniel Briseno Servin ###
### Description ###

This project is a review of the XGBoost model for predicting the critical temperature of an arbitrary superconductor, as [proposed here](https://linkinghub.elsevier.com/retrieve/pii/S0927025618304877). 

In the linked paper, a RMSE of ~9.5 is given as the only metric for the model's performance. In this project I conduct a finer grained analysis of the predictive power of XGBoost at the task of predicting critical temperatures. More specifically, I analyze the performance of XGBoost across not only a general class of superconductors (as is done in the original paper), but also on certain classes of superconductors which are of particular practical interest. Additionally, I analyze how XGBoost performs on superconductors in different critical temperature quartiles.

I conclude that XGBoost's RMSE of 9.5 as the only error metric might be misleading, since analyzing the performance across quartiles shows a low temperature bias which increases as the critical temperature of a superconductor becomes higher. A full write-up of methods and results can be found [here](./Final_paper/Final_Project_Writeup/Final_Project_Writeup.pdf).

#### Instructions on Running Code ####
- In terminal, navigate to `./src`
- To test XGBoost model and collect error vectors, call `$ Rscript Get_RMSE.R`.
  - The program will take approximately 2 minutes to run on 4 cores.
  - Output files are sent to the Output directory. The relevant `.rds` files are
    - control_err.rds: 50 error vectors collected off of 50 random test-train partitions
    - decile_err.rds: 500 error vectors collected for the true T_c deciles (not used in final paper)
    - quartile_err.rds: 200 error vectors collected for the true T_c quartiles
    - output_quartile_errs.rds: 200 error vectors collected for the predicted T_c quartiles
    - elemental_err_rt.rds: 200 error vectors collected for Fe, Hg, Cu, and MgB_2 based superconductors. 
      - rt indicates that the model was trained only on Fe, Hg, Cu, and MgB_2 when predicting T_c for Fe, Hg, Cu, and MgB_2, respectively
    - elemental_err_n_rt.rds: 200 error vectors collected for Fe, Hg, Cu, and MgB_2 based superconductors
      - n_rt indicates that a generalized model was used for these predictions (model trained on unrestricted training dataset)
- All plots used in final paper are present in the Plots folder.
  - To re-generate plots, call `$ Rscript Data_Analysis.R`
  - All plots will be saved to the `./Plots` directory.
  
#### Details on Model Training ###
- All machine learning was performed using the R [XGBoost](https://cran.r-project.org/web/packages/xgboost/index.html) package. 
- Model ran for 50 trials, each trial randomly partitioning tc.RData into 1/3 test and 2/3 training data.
- Model was trained and tested accordingly. Depending on the subset being tested, only a subset of the training data may have been used.

#### Overview of Files #####
- Dependencies.R: File programmatically ensures that all needed packages are loaded, and that any missing packages are installed and loaded into environment.
- Data_Splitter.R: File handles random 1/3 test 2/3 train partitioning of superconductor data. File also generates elemental subsets, and partitions the superconductors by T_c quartile and decile.
- Model.R: File handles training XGBoost model and prediction of T_c values using data matrices of superconductor data.
- RMSE_Calculator.R: File handles collection of RMSE and other error statistics for predictions by XGBoost given training data and testing data.
  - Makes calls to Data_Splitter.R, Model.R
- Get_RMSE.R: File orchestrates the 50 trials and collects the output from RMSE_Calculator from each trial.
  - Makes calls to RMSE_Calculator
  - Generates file output. All output goes to output folder.
- Data_Analysis.R
  - Used interactively, file collects statistics from output folder and generates plots.
  - Depends on output from Get_RMSE.R, but makes no direct calls. 
