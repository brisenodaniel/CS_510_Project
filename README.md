# CS 510 Project #
## Author: Daniel Briseno Servin ###
### Description ###

This project is a review of the XGBoost model for predicting the critical temperature of an arbitrary superconductor, as [proposed here](https://linkinghub.elsevier.com/retrieve/pii/S0927025618304877). 

In the linked paper, a RMSE of ~9.5 is given as the only metric for the model's performance. In this project I conduct a finer grained analysis of the predictive power of XGBoost at the task of predicting critical temperatures. More specifically, I analyze the performance of XGBoost across not only a general class of superconductors (as is done in the original paper), but also on certain classes of superconductors which are of particular practical interest. Additionally, I analyze how XGBoost performs on superconductors in different critical temperature quartiles.

#### Instructions on Running Code ####
- In terminal, navigate to [`./src`](./src)
- To test the XGBoost model, collect error statistics and re-generate plots, call `$Rscript Main.R`
  - This program will take approximatively 30 minutes to run on 4 cores.
- To test XGBoost model and collect error statistics without re-generating plots, call `$Rscript ErrorWriter.R`
  - This program will take approximately 30 minutes to run on 4 cores
- To re-generate plots using error statistics collected earlier, run `$Rscript ErrorAnalysis.R`
  - This program will take approximately 1 minute to run.	
  - All plots are outputted to the [./Plots](./Plots) subdirectory.

#### Details on the Superconductor Dataset ####

The data used in this analysis is the [Superconductivity Data Dataset](https://archive.ics.uci.edu/ml/datasets/Superconductivty+Data) from the [UCI Machine Learning Repository](https://archive.ics.uci.edu/ml/index.php). This dataset is locally stored in [./Data/](./Data) as `tc.RData`  and consists of the following two tables:

- `train ` : A dataset of 82 features taken from 21263 superconductors. The 82nd feature is critical temperature and is used as the target label throughout this analysis. The other 81 features are functions of the following atomic properties of the elements in the superconductors:
  - Atomic Mass
  - First Ionization Energy
  - Atomic Radius
  - Density
  - Electron Affinity
  - Fusion Heat
  - Thermal Conductivity
  - Valence (typical number of chemical bonds formed by the element)
- `unique_m` : Contains the chemical formulas for the 21263 superconductors in `train`, with each row in `unique_m` giving the chemical formula for the same row in `train`.

#### Details on [`./Output/`](./Output/) Directory

- This directory contains error statistics collected off of 50 different test/train splits of the the training data, as outputted by [`./src/ErrorWriter.R`](./src/ErrorWriter.R), and used by [`./src/DataAnalysis.R`](./src/DataAnalysis.R) to generate plots. The `.rds` files in this directory are:
  - [control_err.rds](./Output/control_err.rds) : Error statistics collected off of 50 random test-train partitions of the entire testing data.
  - [quartile_err.rds](./Output/quartile_err.rds) : Error statistics collected separately on each critical temperature quartile after 50 random test-train partitions of the testing data. Each superconductor in the test split is placed in a quartile based off of its _true_ critical temperature.
  - [output_quartile_errs.rds](./Output/output_quartile_errs.rds) : Error statistics collected separately on each critical temperature quartile after 50 random test-train partitions of the testing data. Each superconductor in the test split is placed in a quartile based off of its _predicted_ critical temperature.
  - [elemental_err_nrt.rds](./Output/elemental_err_nrt.rds) : Error statistics collected separately for superconductors containing Fe, Hg, Cu, and MgB_2.
  - [elemental_err_rt.rds](./Output/elemental_err_rt.rds) : Error statistics collected separately for superconductors containing Fe, Hg, Cu, and MgB_2 when the XGBoost decision tree is trained exclusively on superconductors containing Fe, Hg, Cu, or MgB_2, respectively.

#### Details on Model Training ###
- All machine learning was performed using the R [XGBoost](https://cran.r-project.org/web/packages/xgboost/index.html) package. 
- Model ran for 50 trials, each trial randomly partitioning tc.RData into 1/3 test and 2/3 training data.
- Depending on the subset being tested, only a subset of the training data may have been used.

#### Overview of Program Files in [./src/](./src) #####
- [Dependencies.R](./src/Dependencies.R): File programmatically ensures that all needed packages are installed and loaded into the environment. File also clears the environment of all variables and objects to prevent memory overuse from running source files interactively, thus, this file should only be run at the start of Data Analysis.
- [DataSplitter.R](./src/DataSplitter.R) : File handles random 1/3 test 2/3 train partitioning of superconductor data. File also generates subsets of superconductors containing Fe, Mg, Hg, and MgB_2, and partitions the superconductors by critical temperature quartile.
- [Model.R](Model.R) : File handles training XGBoost model and prediction of critical temperature values.
- [Buffer.R](./src/Buffer.R) : Used for runtime optimization. Caches test and train data indices and tuned XGBoost models trained on those indices. When appropriate, XGBoost models and test-train splits are re-used rather than re-computed from scratch.
- [ErrorCalculator.R](./src/ErrorCalculator.R) : File handles collection of error statistics for predictions by XGBoost given training data and testing data.
  - Makes calls to DataSplitter.R, Model.R
- [ErrorWriter.R](./src/ErrorWriter.R) : File orchestrates 50 trials of error data collection per test condition, and saves output to [./Output/](./Output).
  - Makes calls to ErrorCalculator, Dependencies.R
- [DataAnalysis.R ](./src/DataAnalysis.R) : File uses error statistics in [./Output/](./Output) to generate tables and plots for data visualization and analysis. All plots and tables are saved to [./Plots/](./Plots).
- [Main.R](./src/Main.R) : File calls [ErrorWriter.R](./src/ErrorWriter.R), then [DataAnalysis.R](./src/DataAnalysis.R) to re-generate error statistics then re-generate plots and tables.
