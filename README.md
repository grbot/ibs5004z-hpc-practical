# IBS5004Z: From a laptop to HPC

This practical follows one small bioinformatics task from beginning to end. You will first perform the task manually, then run it as a reusable shell script, and finally submit the same script as a scheduled Slurm batch job:

**manual command → reusable shell script → scheduled Slurm batch job**

The repository is the authoritative guide for the practical. Every command block is labelled **LAPTOP**, **ILIFU LOGIN NODE**, or **ILIFU COMPUTE NODE** so that you always know where to run it.

## Before the practical

You need:

- an Ilifu username and the correct Ilifu login hostname supplied by the lecturer;
- an SSH client (`ssh` and `scp` are included in macOS and Linux; Windows users can use PowerShell or Windows Terminal); and
- Git and a download tool such as `curl`.

In the examples below:

- replace `<username>` with your Ilifu username;
- replace `<ilifu-login-host>` with the hostname supplied by the lecturer;
- replace `<repository-url>` with the GitHub URL for this repository;
- replace `<FASTQ-RELEASE-URL>` with the direct URL for the `example.fastq.gz` GitHub Release asset; and
- replace `<job-id>` with the job number printed by `sbatch`.

Do not type the angle brackets (`<` and `>`) around replacement values.

## Part 1 — Set up on your laptop

The Git repository contains the instructions and scripts. The FASTQ data is downloaded separately from a GitHub Release so that sequencing data is not stored in Git history.

### Clone the repository

**Run on: LAPTOP**

```bash
git clone <repository-url>
cd ibs5004z-hpc-practical
```

### Download the teaching FASTQ

**Run on: LAPTOP**

```bash
mkdir -p data
curl -L <FASTQ-RELEASE-URL> -o data/example.fastq.gz
```

If `curl` is unavailable, use:

```bash
wget <FASTQ-RELEASE-URL> -O data/example.fastq.gz
```

Verify that the file exists and inspect its first eight lines without extracting it:

```bash
ls -lh data/example.fastq.gz
gzip -cd data/example.fastq.gz | head -n 8
```

### Understand the FASTQ format

A FASTQ file stores sequencing reads and a quality score for every base. Each read occupies four lines:

```text
@read_name
ACGTTGCA
+
IIIIIIII
```

The four lines contain:

1. a read identifier beginning with `@`;
2. the nucleotide sequence;
3. a separator beginning with `+`; and
4. encoded base-quality characters.

Because every read has four lines:

```text
number of reads = number of lines / 4
```

Real FASTQ files are often compressed with gzip and end in `.fastq.gz`. Do not decompress the teaching file: the commands and scripts in this practical can read it directly.

The repository should now contain:

```text
ibs5004z-hpc-practical/
├── README.md
├── data/
│   ├── README.md
│   └── example.fastq.gz
├── scripts/
│   └── count_reads.sh
└── slurm/
    └── count_reads.sbatch
```

The `.gitignore` intentionally excludes FASTQ files and generated results. Only `data/README.md` is tracked in the `data` directory.

## Part 2 — Transfer the repository and data to Ilifu

Move to the directory above the repository:

**Run on: LAPTOP**

```bash
cd ..
ls ibs5004z-hpc-practical
```

Copy the complete directory, including the downloaded FASTQ, to your Ilifu home directory using either `scp`:

```bash
scp -r ibs5004z-hpc-practical <username>@<ilifu-login-host>:~/
```

or `rsync`:

```bash
rsync -av ibs5004z-hpc-practical/ <username>@<ilifu-login-host>:~/ibs5004z-hpc-practical/
```

Connect to Ilifu:

```bash
ssh <username>@<ilifu-login-host>
```

Your prompt will change after login. Verify that both the repository and FASTQ arrived:

**Run on: ILIFU LOGIN NODE**

```bash
cd ~/ibs5004z-hpc-practical
pwd
ls -lh
ls -lh data/example.fastq.gz
```

The login node is for connecting, transferring files, and submitting jobs. Do not run compute-intensive analyses on it.

## Part 3 — Perform the operation manually on a compute node

An interactive Slurm job gives you a shell on a compute node. Request a small allocation:

**Run on: ILIFU LOGIN NODE**

```bash
srun --pty --time=00:10:00 --cpus-per-task=1 --mem=1G bash
```

You may wait briefly while Slurm finds a compute node. If your course instructions require an account or partition, add the supplied `--account=...` or `--partition=...` option.

Confirm that you are on a compute node and return to the practical directory:

**Run on: ILIFU COMPUTE NODE**

```bash
hostname
cd ~/ibs5004z-hpc-practical
```

Inspect the first two FASTQ records (eight lines):

```bash
gzip -cd data/example.fastq.gz | head -n 8
```

Count all lines:

```bash
gzip -cd data/example.fastq.gz | wc -l
```

The output should be divisible by four. Store the line count and calculate the number of reads manually:

```bash
lines=$(gzip -cd data/example.fastq.gz | wc -l)
echo "Lines: $lines"
echo "Reads: $((lines / 4))"
```

You now understand the operation that the scripts will automate: decompress to standard output, count the lines, and divide by four.

## Part 4 — Run the reusable shell script interactively

Inspect the supplied script before running it:

**Run on: ILIFU COMPUTE NODE**

```bash
less scripts/count_reads.sh
```

Press `q` to leave `less`. Then run the script on the teaching FASTQ:

```bash
bash scripts/count_reads.sh data/example.fastq.gz
```

The script performs the same calculation and also checks that the number of lines is divisible by four. Its read count should match your manual result.

End the interactive job:

```bash
exit
```

You should now be back on the Ilifu login node.

## Part 5 — Submit and monitor a scheduled Slurm batch job

First inspect the batch script. Notice its `#SBATCH` resource requests and the command that calls the reusable counting script:

**Run on: ILIFU LOGIN NODE**

```bash
cd ~/ibs5004z-hpc-practical
less slurm/count_reads.sbatch
```

Press `q` to leave `less`. Submit the job and pass it the FASTQ filename:

```bash
sbatch slurm/count_reads.sbatch data/example.fastq.gz
```

Slurm will print a job ID, for example:

```text
Submitted batch job 123456
```

Monitor queued and running jobs:

```bash
squeue --me
```

If `squeue --me` is not supported, use:

```bash
squeue -u "$USER"
```

A short job may finish before you see it in the queue. That is normal. Optionally inspect the completed job's accounting information:

```bash
sacct -j <job-id> --format=JobID,JobName,State,Elapsed,ExitCode
```

Inspect the generated result and Slurm log:

```bash
ls -lh results
ls -lh slurm-*.out
cat results/read_count_<job-id>.txt
cat slurm-<job-id>.out
```

The batch result should match both the manual count and the interactive script output. You have now progressed from a manual command, to a reusable shell script, to a scheduled Slurm batch job.

## Part 6 — Retrieve the result to your laptop

If you are still connected to Ilifu, leave the login node:

**Run on: ILIFU LOGIN NODE**

```bash
exit
```

Your prompt should now be your laptop prompt. Move into the local repository and retrieve the result:

**Run on: LAPTOP**

```bash
cd path/to/ibs5004z-hpc-practical
mkdir -p retrieved-results
scp <username>@<ilifu-login-host>:~/ibs5004z-hpc-practical/results/read_count_<job-id>.txt retrieved-results/
```

Check the retrieved file:

```bash
cat retrieved-results/read_count_<job-id>.txt
```

You have now kept code and data separate, moved data from your laptop to HPC, understood and run an analysis interactively, scheduled it as a batch job, and brought the result back.

## Troubleshooting

- **`No such file or directory`**: check your current directory with `pwd`, then list its contents with `ls`.
- **`Permission denied` during SSH/SCP**: check the username, hostname, and authentication instructions supplied for the course.
- **The job remains pending**: run `squeue -u "$USER"`; a `PD` state means it is waiting for resources.
- **The job fails**: inspect `slurm-<job-id>.out` first. Error messages are written there.
- **Your FASTQ is not gzip-compressed**: use a filename ending in `.fastq`; the supplied counting scripts support both compressed and uncompressed FASTQ files. For manual inspection, use `head -n 8 data/example.fastq` instead of `gzip -cd ...`.
