import subprocess
import pandas as pd

tmp_dir = os.environ.get("tmp_dir", config['tmp_dir'])

## Input input directory
input_dir = config["input_dir"]["download"]

## Define output directory
output_dir = os.path.join(config['output_dir'],  "metagenomics", "preprocessing")

## Define input files
# Read the sample table
samples = pd.read_table(config["data_table"], sep="\t", comment = "#").set_index("sample_alias", drop=False)

workdir:
    output_dir

include:
    '../../rules/metagenomics/preprocessing/trimmomatic.smk'

rule all:
     input:
        expand("{sample}/{sample}_R1.processed.fastq.gz", sample = samples.index),
        expand("{sample}/{sample}_R2.processed.fastq.gz", sample = samples.index),
        expand("{sample}/{sample}_SE.processed.fastq.gz", sample = samples.index)
