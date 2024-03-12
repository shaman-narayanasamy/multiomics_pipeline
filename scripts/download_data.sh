#!/bin/bash

# Define the output directory
metadata_table=$1
output_dir=$2

# Assuming your file is named 'table.txt' and is tab-separated.
# Skip the first line (header) and then iterate over each line.
tail -n +2 $metadata_table | grep -v "^#" | while IFS=$'\t' read -r sample_alias MG_R1 MG_R2 MT_R1 MT_R2
do
  # Download the entire directory structure recursively using wget -m
  wget -m -c -P "$output_dir" "$MG_R1"
  wget -m -c -P "$output_dir" "$MG_R2"
  wget -m -c -P "$output_dir" "$MT_R1"
  wget -m -c -P "$output_dir" "$MT_R2"
done
