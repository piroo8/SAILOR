#!/bin/bash

# Submit the preprocessing / cleanup job first
pre_job=$(sbatch --parsable test_clean_pre_dec28.sh)

echo "Submitted preprocessing job: $pre_job"

# Submit dependent training jobs
sbatch --dependency=afterok:$pre_job jan16_train_sqaure_50.sh
sbatch --dependency=afterok:$pre_job jan16_train_sqaure_75.sh
sbatch --dependency=afterok:$pre_job jan16_train_sqaure_100.sh

echo "Submitted training jobs dependent on $pre_job"
