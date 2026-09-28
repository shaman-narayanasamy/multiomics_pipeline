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
if "biological_sample_alias" in samples.columns:
    samples["biological_sample_alias"] = samples["biological_sample_alias"].astype(str)
    mg_sample_by_assembly_sample = (
        samples.drop_duplicates(subset=["biological_sample_alias"])
        .set_index("biological_sample_alias")["sample_alias"]
        .astype(str)
        .to_dict()
    )
    assembly_samples = sorted(mg_sample_by_assembly_sample)
else:
    samples.set_index("sample_alias", drop=False, inplace=True)
    assembly_samples = list(samples.index)
    mg_sample_by_assembly_sample = {sample: sample for sample in assembly_samples}


def mg_assembly_read(sample, read):
    mg_sample = mg_sample_by_assembly_sample[str(sample)]
    return os.path.join(mg_reads_dir, mg_sample, f"{mg_sample}_{read}.processed.fastq.gz")

workdir:
    output_dir

include:
    '../../rules/metagenomics/assembly/penguin.smk'

rule all:
     input:
        expand("{sample}/penguin_assembly/final.contigs.fa", sample = assembly_samples),
        expand("{sample}/penguin_assembly/{sample}.penguin_contigs.fa", sample = assembly_samples),
        expand("{sample}/{sample}.assembly_contigs.fa", sample = assembly_samples)
