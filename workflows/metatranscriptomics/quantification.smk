import os
import subprocess
import yaml
import pandas as pd

PWD = os.getcwd()

# Definition of environmental variables: paths for the source codes, among others
CONFIG = os.environ.get("CONFIG", "%s/config/config.yml" % PWD)
# Default to the processing the directory where all bins from all experimental conditions were dereplicated. This can be adjusted in the snakemake command, if required

configfile: CONFIG

# Load the bins config
with open(config["bins_config"], "r") as file:
    bins_config = yaml.safe_load(file)

tmp_dir = os.environ.get("tmp_dir", config['tmp_dir'])

## Define input directory
input_dir = config["input_dir"].get("mt_quantification_input", config["input_dir"]["mt_assembly_input"])

## Define output directory
output_dir = os.path.join(config["output_dir"], "metatranscriptomics", "quantification")

## Define input files
def config_bool(value):
    if isinstance(value, bool):
        return value
    return str(value).lower() in {"1", "true", "yes", "y"}


MT_CONFIG = config.get("metatranscriptomics", {})
COMBINE_MT_REPLICATES = config_bool(MT_CONFIG.get("combine_replicates", False))
MT_REPLICATE_GROUP_COLUMN = MT_CONFIG.get("replicate_group_column", "biological_sample_alias")

if COMBINE_MT_REPLICATES:
    sample_table = pd.read_csv(config["data_table"], sep="\t", comment="#", dtype={"sample_alias": str})
    sample_table = sample_table.dropna(subset=["MT_R1", "MT_R2"])
    if MT_REPLICATE_GROUP_COLUMN not in sample_table.columns:
        raise ValueError(
            f"metatranscriptomics.combine_replicates requires column {MT_REPLICATE_GROUP_COLUMN!r}"
        )
    sample_lane_list = sorted(sample_table[MT_REPLICATE_GROUP_COLUMN].dropna().astype(str).unique())
    input_dir = (
        input_dir
        if os.path.basename(os.path.normpath(input_dir)) == "combined"
        else os.path.join(input_dir, "combined")
    )
    MT_QUANTIFICATION_INPUT_LAYOUT = "sample_dir"
else:
    sample_table = pd.read_csv(config["mt_data_table"], sep="\t", comment="#")
    samples = sample_table["sample"].tolist()
    lanes = sample_table["lane"].tolist()
    sample_lane_list = [f"{sample}_{lane}" for sample, lane in zip(samples, lanes)]
    MT_QUANTIFICATION_INPUT_LAYOUT = "flat"


def mt_quant_read(sample, read):
    if MT_QUANTIFICATION_INPUT_LAYOUT == "sample_dir":
        return os.path.join(
            input_dir,
            sample,
            f"{sample}_{read}.processed.filtered.fastq.gz",
        )
    return os.path.join(input_dir, f"{sample}_{read}.processed.filtered.fastq.gz")

workdir:
    output_dir

## All workflow
include:
    '../../rules/metatranscriptomics/quantification/salmon/all/indexing.smk'

include:
    '../../rules/metatranscriptomics/quantification/salmon/all/pseudoalignment.smk'

include:
    '../../rules/metatranscriptomics/quantification/map_ids.smk'

## Isolated bin workflow

rule all:
    input:
        "all_bin_transcripts.ffn",
        "salmon/index/all_transcripts",
        "bin2bakta_id_mappings.tsv",
        expand("salmon/all/{sample_lane}_quant", sample_lane = sample_lane_list)
