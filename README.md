# IBS5004Z: From a laptop to HPC

This practical begins by connecting your laptop securely to Ilifu. You will then follow one small bioinformatics task from beginning to end: first performing it manually, then running it as a reusable shell script, and finally submitting the same script as a scheduled Slurm batch job.

**manual command → reusable shell script → scheduled Slurm batch job**

The repository is the authoritative guide for the practical. Every command block is labelled **LAPTOP**, **ILIFU LOGIN NODE**, or **ILIFU COMPUTE NODE** so that you always know where to run it.

## Before the practical

You need:

- your Ilifu username;
- the private SSH key associated with your Ilifu account;
- access to your two-factor authentication method; and
- the software described in Part 0 below.

In the examples below:

- replace `<username>` with your Ilifu username;
- replace `<FASTQ-RELEASE-URL>` with the direct URL for the `example.fastq.gz` GitHub Release asset; and
- replace `<job-id>` with the job number printed by `sbatch`.

Do not type the angle brackets (`<` and `>`) around replacement values.

## Part 0 — Prepare your laptop and connect to Ilifu

In this part, you will prepare a terminal, protect your private key, complete two-factor authentication, and confirm that you can reach Ilifu. The lecturer will guide the class through the institution-specific key and two-factor setup.

### Windows: install and open Git Bash

Download and install [Git for Windows](https://git-scm.com/install/windows), accepting the standard installation options. Open **Git Bash** from the Start menu after installation.

Git Bash gives Windows users the Git, SSH, SCP, and Unix-style command-line tools used in this practical. Run all **LAPTOP** commands in Git Bash.

### macOS and Linux: open a terminal

- On macOS, open **Terminal** from Applications → Utilities.
- On Linux, open your usual terminal application.

### Check the required commands

**Run on: LAPTOP**

```bash
command -v git ssh scp
git --version
ssh -V
```

The first command should print a location for each program, and the next two should display version information. Ask for help before continuing if `git`, `ssh`, or `scp` cannot be found.

### Store and protect your private key

Your lecturer will explain how the key for your Ilifu account is provided or registered. The example below assumes the private-key file is currently in your laptop's `Downloads` directory and is called `ilifu_key`. Adjust the source filename if yours is different.

**Run on: LAPTOP**

```bash
mkdir -p ~/.ssh
mv ~/Downloads/ilifu_key ~/.ssh/ilifu_key
chmod 700 ~/.ssh
chmod 600 ~/.ssh/ilifu_key
```

The private key is a credential. **Never email it, share it with another student, add it to this repository, or upload it to GitHub.**

### Make your first connection

**Run on: LAPTOP**

```bash
ssh -i ~/.ssh/ilifu_key <username>@slurm.ilifu.ac.za
```

During the first connection:

1. SSH may ask whether you trust the host. Check that the hostname is `slurm.ilifu.ac.za` and confirm the host fingerprint with the lecturer before answering `yes`.
2. If your private key has a passphrase, enter it when prompted. No characters will appear while you type.
3. Complete the Ilifu two-factor authentication prompt using the method demonstrated by the lecturer.

Your private-key passphrase and your two-factor authentication response are separate credentials. Depending on the authentication configuration, you may not see every prompt described above.

After a successful connection, your prompt will change because your shell is now running on the Ilifu login node. Confirm this, then return to your laptop:

**Run on: ILIFU LOGIN NODE**

```bash
hostname
exit
```

Do not continue until you can connect successfully. If you encounter an account, key, or two-factor authentication problem, ask the lecturer or Ilifu support for help; another student's private key must not be used.

## Part 1 — Set up on your laptop

The Git repository contains the instructions and scripts. The FASTQ data is downloaded separately from a GitHub Release so that sequencing data is not stored in Git history.

### Clone the repository

**Run on: LAPTOP**

```bash
git clone https://github.com/grbot/ibs5004z-hpc-practical.git
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

Copy the complete directory, including the downloaded FASTQ, to your Ilifu home directory through Ilifu's dedicated transfer node using either `scp`:

```bash
scp -i ~/.ssh/ilifu_key -r ibs5004z-hpc-practical <username>@transfer.ilifu.ac.za:~/
```

or, if `rsync` is installed, use:

```bash
rsync -av -e "ssh -i ~/.ssh/ilifu_key" ibs5004z-hpc-practical/ <username>@transfer.ilifu.ac.za:~/ibs5004z-hpc-practical/
```

Connect to Ilifu:

```bash
ssh -i ~/.ssh/ilifu_key <username>@slurm.ilifu.ac.za
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
scp -i ~/.ssh/ilifu_key <username>@transfer.ilifu.ac.za:~/ibs5004z-hpc-practical/results/read_count_<job-id>.txt retrieved-results/
```

Check the retrieved file:

```bash
cat retrieved-results/read_count_<job-id>.txt
```

You have now kept code and data separate, moved data from your laptop to HPC, understood and run an analysis interactively, scheduled it as a batch job, and brought the result back.

## Troubleshooting

- **`No such file or directory`**: check your current directory with `pwd`, then list its contents with `ls`.
- **`Identity file ... not accessible`**: check the key filename and location with `ls -l ~/.ssh`.
- **`UNPROTECTED PRIVATE KEY FILE`**: run `chmod 600 ~/.ssh/ilifu_key`, then try again.
- **`Permission denied` during SSH/SCP**: check your username, private key, and two-factor authentication response. Never try another student's private key.
- **Two-factor authentication fails**: check that your device has the correct time and that you are using the authentication method registered for your Ilifu account. Ask the lecturer or Ilifu support if it continues to fail.
- **The job remains pending**: run `squeue -u "$USER"`; a `PD` state means it is waiting for resources.
- **The job fails**: inspect `slurm-<job-id>.out` first. Error messages are written there.
- **Your FASTQ is not gzip-compressed**: use a filename ending in `.fastq`; the supplied counting scripts support both compressed and uncompressed FASTQ files. For manual inspection, use `head -n 8 data/example.fastq` instead of `gzip -cd ...`.
