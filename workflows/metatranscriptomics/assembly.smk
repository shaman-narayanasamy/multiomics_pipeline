import os
import subprocess
import pandas as pd

tmp_dir = os.environ.get("tmp_dir", config['tmp_dir'])

## Define input directory
raw_input_dir = config["input_dir"]["mt_assembly_input"]

## Define output directory
output_dir = os.path.join(config['output_dir'], "metatranscriptomics", "assembly")

## Define input files
# Read the sample table
sample_table = pd.read_table(config["data_table"], sep="\t", comment="#", dtype={"sample_alias": str})
sample_table = sample_table.dropna(subset=["MT_R1", "MT_R2"])
sample_table.set_index("sample_alias", drop=False, inplace=True)


def config_bool(value):
    if isinstance(value, bool):
        return value
    return str(value).lower() in {"1", "true", "yes", "y"}


MT_CONFIG = config.get("metatranscriptomics", {})
COMBINE_MT_REPLICATES = config_bool(MT_CONFIG.get("combine_replicates", False))
MT_REPLICATE_GROUP_COLUMN = MT_CONFIG.get("replicate_group_column", "biological_sample_alias")

if COMBINE_MT_REPLICATES:
    if MT_REPLICATE_GROUP_COLUMN not in sample_table.columns:
        raise ValueError(
            f"metatranscriptomics.combine_replicates requires column {MT_REPLICATE_GROUP_COLUMN!r}"
        )
    samples = sorted(sample_table[MT_REPLICATE_GROUP_COLUMN].dropna().astype(str).unique())
    input_dir = (
        raw_input_dir
        if os.path.basename(os.path.normpath(raw_input_dir)) == "combined"
        else os.path.join(raw_input_dir, "combined")
    )
else:
    samples = sample_table.index


workdir:
    output_dir

include:
    '../../rules/metatranscriptomics/assembly/megahit.smk'

include:
    '../../rules/metatranscriptomics/assembly/penguin.smk'

include:
    '../../rules/metatranscriptomics/assembly/bwa.smk'

rule all:
     input:
        expand("{sample}/megahit_assembly/final.contigs.fa", sample = samples),
        expand("{sample}/megahit_assembly/{sample}.megahit_contigs.fa", sample = samples),
        expand("{sample}/penguin_assembly/final.contigs.fa", sample = samples),
        expand("{sample}/penguin_assembly/{sample}.penguin_contigs.fa", sample = samples),
        expand('{sample}/{sample}_metaT.reads.sorted.bam', sample = samples),
        expand('{sample}/{sample}_metaT.reads.sorted.flagstat.txt', sample = samples)
