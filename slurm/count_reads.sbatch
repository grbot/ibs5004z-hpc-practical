#!/usr/bin/env bash
#SBATCH --job-name=count_reads
#SBATCH --time=00:05:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --output=slurm-%j.out

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: sbatch $0 <reads.fastq[.gz]>" >&2
    exit 1
fi

fastq=$1
project_dir=${SLURM_SUBMIT_DIR:-$PWD}
result_dir="$project_dir/results"
result_file="$result_dir/read_count_${SLURM_JOB_ID:-manual}.txt"

mkdir -p "$result_dir"

bash "$project_dir/scripts/count_reads.sh" "$fastq" | tee "$result_file"

echo "Result saved to: $result_file"

