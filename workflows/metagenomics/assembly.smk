import os
import subprocess
import pandas as pd

tmp_dir = os.environ.get("tmp_dir", config['tmp_dir'])

## Define input directory
mg_reads_dir = config["input_dir"]["mg_assembly_input"]

## Define output directory
output_dir = os.path.join(config['output_dir'],  "metagenomics", "assembly")

## Define input files
# Read the sample table
#samples = pd.read_table(config["data_table"]["all"], sep="\t", comment="#", dtype={"sample_alias": str})
samples = pd.read_table(config["data_table"], sep="\t", comment="#", dtype={"sample_alias": str})
samples = samples.dropna(subset=["MG_R1", "MG_R2"])
samples.set_index("sample_alias", drop=False, inplace=True)

workdir:
    output_dir

include:
    '../../rules/metagenomics/assembly/penguin.smk'

rule all:
     input:
        expand("{sample}/penguin_assembly/final.contigs.fa", sample = samples.index)
