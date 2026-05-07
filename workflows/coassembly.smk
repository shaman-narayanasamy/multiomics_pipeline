import os
import subprocess
import pandas as pd

tmp_dir = os.environ.get("tmp_dir", config['tmp_dir'])

## Define input directories
mg_reads_dir = config["input_dir"]["mg_assembly_input"]
mt_reads_dir = config["input_dir"]["mt_assembly_input"]
mt_contigs_dir = config["input_dir"]["mt_contig_input"]

## Define output directory
output_dir = os.path.join(config['output_dir'], "coassembly")

## Define input files
# Read the sample table
sample_ids = pd.read_table(config["data_table"], sep="\t", comment="#", dtype={"sample_alias": str})


def config_bool(value):
    if isinstance(value, bool):
        return value
    return str(value).lower() in {"1", "true", "yes", "y"}


MT_CONFIG = config.get("metatranscriptomics", {})
COMBINE_MT_REPLICATES = config_bool(MT_CONFIG.get("combine_replicates", False))
MT_REPLICATE_GROUP_COLUMN = MT_CONFIG.get("replicate_group_column", "biological_sample_alias")

if COMBINE_MT_REPLICATES:
    if MT_REPLICATE_GROUP_COLUMN not in sample_ids.columns:
        raise ValueError(
            f"metatranscriptomics.combine_replicates requires column {MT_REPLICATE_GROUP_COLUMN!r}"
        )
    mg_rows = sample_ids.dropna(subset=["MG_R1", "MG_R2"]).copy()
    mt_rows = sample_ids.dropna(subset=["MT_R1", "MT_R2"]).copy()
    mg_rows[MT_REPLICATE_GROUP_COLUMN] = mg_rows[MT_REPLICATE_GROUP_COLUMN].astype(str)
    mt_rows[MT_REPLICATE_GROUP_COLUMN] = mt_rows[MT_REPLICATE_GROUP_COLUMN].astype(str)
    samples = sorted(
        set(mg_rows[MT_REPLICATE_GROUP_COLUMN]).intersection(mt_rows[MT_REPLICATE_GROUP_COLUMN])
    )
    mg_sample_by_coassembly_sample = (
        mg_rows.drop_duplicates(subset=[MT_REPLICATE_GROUP_COLUMN])
        .set_index(MT_REPLICATE_GROUP_COLUMN)["sample_alias"]
        .astype(str)
        .to_dict()
    )
    mt_sample_by_coassembly_sample = {sample: sample for sample in samples}
    mt_reads_dir = (
        mt_reads_dir
        if os.path.basename(os.path.normpath(mt_reads_dir)) == "combined"
        else os.path.join(mt_reads_dir, "combined")
    )
else:
    sample_ids = sample_ids.dropna(subset=["sample_alias"])
    sample_ids.set_index("sample_alias", drop=False, inplace=True)
    samples = sample_ids.index
    mg_sample_by_coassembly_sample = {sample: sample for sample in samples}
    mt_sample_by_coassembly_sample = {sample: sample for sample in samples}


def coassembly_mg_read(sample, read):
    mg_sample = mg_sample_by_coassembly_sample[str(sample)]
    return os.path.join(mg_reads_dir, mg_sample, f"{mg_sample}_{read}.processed.fastq.gz")


def coassembly_mt_read(sample, read):
    mt_sample = mt_sample_by_coassembly_sample[str(sample)]
    return os.path.join(mt_reads_dir, mt_sample, f"{mt_sample}_{read}.processed.filtered.fastq.gz")


def coassembly_mt_contigs(sample):
    return os.path.join(mt_contigs_dir, str(sample), "megahit_assembly", "final.contigs.fa")

workdir:
    output_dir

include:
    '../rules/coassembly/megahit.smk'

include:
    '../rules/coassembly/bwa_index.smk'

include:
    '../rules/coassembly/bwa_mg.smk'

include:
    '../rules/coassembly/bwa_mt.smk'

include:
    '../rules/coassembly/coverm_contig.smk'

rule all:
     input:
        expand("{sample}/megahit_assembly/final.contigs.fa", sample = samples),
        expand("{sample}/{sample}.coassembly_contigs.fa", sample = samples),
        expand("{sample}/{sample}_metaG.reads.sorted.bam", sample = samples),
        expand("{sample}/{sample}_metaG.reads.sorted.bam.bai", sample = samples),
        expand("{sample}/{sample}_metaG.reads.sorted.flagstat.txt", sample = samples),
        expand("{sample}/{sample}_metaT.reads.sorted.bam", sample = samples),
        expand("{sample}/{sample}_metaT.reads.sorted.bam.bai", sample = samples),
        expand("{sample}/{sample}_metaT.reads.sorted.flagstat.txt", sample = samples),
        expand('{sample}/coverm/{sample}_coverage.out', sample = samples),
