#!/bin/env bash

#SBATCH --job-name=GetErrs
#SBATCH --output=Errs.out
#SBATCH --error=Errs.err
#SBATCH --partition=defq
#SBATCH --time=00:15:00
#SBATCH --ntasks=10
#SBATCH --cpus-per-task=1

module load R
Rscript --vanilla Get_RMSE.R $SLURM_CPUS_ON_NODE
