import subprocess
import glob
import os
import pandas as pd

tmp_dir = os.environ.get("tmp_dir", config['tmp_dir'])

## Define output directory
output_dir = os.path.join(config['output_dir'],  "annotation")

## Define input files

# Determine input source
if "genomes_dir" in config:
    print("Using genome directory")
    # Get all FASTA files from the folder
    genomes = glob.glob(f"{config['genomes_dir']}/*.fasta")
elif "genome_list" in config:
    # Use the provided list of files
    print("Using genome_list")
    genomes = config["genome_list"]
elif "genome_table" in config:
    print("Using table with list of genomes")
    # Read the TSV file and extract the file paths
    genome_df = pd.read_csv(config["genome_table"], sep="\t")
    genomes = genome_df["fasta"].tolist()

else:
    raise ValueError("Please provide either 'genomes_dir', 'genome_list', or 'genome_table' in the config.")

# Create a mapping from bin IDs to genome paths
genome_index = {
    os.path.splitext(os.path.basename(genome))[0]: genome
    for genome in genomes if genome.endswith(".fasta")
}

# Extract bin IDs
bin_ids = list(genome_index.keys())

workdir:
    output_dir

include:
    '../rules/annotation/classification.smk'

include:
    '../rules/annotation/annotation.smk'

rule all:
    input:
        #expand("catbat/{db_name}/BAT.bin2classification.names_added.txt", db_name = ["nr", "gtdb"]),
        #expand("catbat/{db_name}/catbat_summary.done", db_name = ["nr", "gtdb"]),
        expand("bakta/{bin_id}/bakta.done", bin_id = bin_ids),
        expand("bakta/{bin_id}", bin_id = bin_ids),
        "bakta/custom_proteins.fasta"
    output:
        touch("annotation.done")
