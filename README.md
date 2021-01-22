# Final Project Code #
## Author: Daniel Briseno Servin ###
#### Instructions on Running Code ####
- To test XGBoost model and collect error vectors, call `rscript Get_RMSE.R` on command line.
  - The program will take approximately 8 hours to run on 4 cores.
  - Output files are sent to the Output folder. The relevant `.rds` files are
    - control_err.rds: 50 error vectors collected off of 50 random test-train partitions
    - decile_err.rds: 500 error vectors collected for the true T_c deciles (not used in final paper)
    - quartile_err.rds: 200 error vectors collected for the true T_c quartiles
    - output_quartile_errs.rds: 200 error vectors collected for the predicted T_c quartiles
    - elemental_err_rt.rds: 200 error vectors collected for Fe, Hg, Cu, and MgB_2 based superconductors. 
      - rt indicates that the model was trained only on Fe, Hg, Cu, and MgB_2 when predicting T_c for Fe, Hg, Cu, and MgB_2, respectivley
    - elemental_err_n_rt.rds: 200 error vectors collected for Fe, Hg, Cu, and MgB_2 based superconductors
      - n_rt indicates that a generalized model was used for these predictions (model trained on unrestricted training dataset)
- All plots used in final paper are present in the Plots folder.
  - To re-generate plots, source Data_Analysis.R
  
#### Details on Model Training ###
- All machine learning was performed using the R [XGboost](https://cran.r-project.org/web/packages/xgboost/index.html) package. 
- Model ran for 50 trials, each trial randomly partitioning tc.RData into 1/3 test and 2/3 training data.
- Model was trained and tested accordingly. Depending on the subset being tested, only a subset of the training data may have been used.

#### Overview of Files #####
- Dependencies.R: File programatically ensures that all needed packages are loaded, and that any missing packages are installed and loaded into enviornment.
- Data_Splitter.R: File handles random 1/3 test 2/3 train partitioning of superconductor data. File also generates elemental subsets, and partitions the superconductors by T_c quartile and decile.
- Model.R: File handles training XGBoost model and prediction of T_c values using data matrices of superconductor data.
- RMSE_Calculator.R: File handles collection of RMSE and other error statistics for predictions by XGBoost given training data and testing data.
  - Makes calls to Data_Splitter.R, Model.R
- Get_RMSE.R: File orchestrates the 50 trials and collects the output from RMSE_Calculator from each trial.
  - Makes calls to RMSE_Calculator
  - Generates file output. All output goes to output folder.
- Data_Analysis.R
  - Used interactivley, file collects statstics from output folder and generates plots.
  - Depends on output from Get_RMSE.R, but makes no direct calls. 
