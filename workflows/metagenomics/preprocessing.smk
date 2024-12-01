import subprocess
import pandas as pd

tmp_dir = os.environ.get("tmp_dir", config['tmp_dir'])

## Define output directory
output_dir = os.path.join(config['output_dir'],  "metagenomics", "preprocessing")

## Define input files
# Read the sample table
samples = pd.read_table(config["data_tables"]["all"], sep="\t", comment="#", dtype={"sample_alias": str})
samples = samples.dropna(subset=["MG_R1", "MG_R2"])
samples.set_index("sample_alias", drop=False, inplace=True)

workdir:
    output_dir

include:
    '../../rules/metagenomics/preprocessing/trimmomatic.smk'

rule all:
     input:
        expand("{sample}/{sample}_R1.processed.fastq.gz", sample = samples.index),
        expand("{sample}/{sample}_R2.processed.fastq.gz", sample = samples.index),
        expand("{sample}/{sample}_SE.processed.fastq.gz", sample = samples.index)
