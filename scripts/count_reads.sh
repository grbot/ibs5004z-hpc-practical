#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <reads.fastq[.gz]>" >&2
    exit 1
fi

fastq=$1

if [[ ! -f "$fastq" ]]; then
    echo "Error: file not found: $fastq" >&2
    exit 1
fi

if [[ "$fastq" == *.gz ]]; then
    line_count=$(gzip -cd -- "$fastq" | wc -l)
else
    line_count=$(wc -l < "$fastq")
fi

if (( line_count % 4 != 0 )); then
    echo "Error: $fastq has $line_count lines, which is not divisible by 4." >&2
    echo "This does not look like a complete four-line FASTQ file." >&2
    exit 1
fi

read_count=$((line_count / 4))

echo "File: $fastq"
echo "Lines: $line_count"
echo "Reads: $read_count"

