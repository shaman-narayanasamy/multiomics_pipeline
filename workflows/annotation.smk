import subprocess
import pandas as pd

tmp_dir = os.environ.get("tmp_dir", config['tmp_dir'])

## Input input directory
coassembly_dir = config["input_dir"]["coassembly_contig_input"]

## Define output directory
output_dir = os.path.join(config['output_dir'],  "annotation")

## Define input files
# Read the sample table
samples = pd.read_table(config["data_table"], sep="\t", comment = "#").set_index("sample_alias", drop=False)

workdir:
    output_dir

include:
    '../rules/annotation/classification.smk'

rule all:
    input:
        expand("{sample}/catbat/{db_name}/CAT.contig2classification.names_added.txt", sample = samples.index, db_name=["gtdb", "nr"])
    output:
        touch("annotation.done")
