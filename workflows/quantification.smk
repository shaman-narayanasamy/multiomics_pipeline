import os
import pandas as pd

tmp_dir = os.environ.get("tmp_dir", config['tmp_dir'])

## Define input directories
mt_reads_dir = config["input_dir"]["mt_assembly_input"]
mg_reads_dir = config["input_dir"]["mg_assembly_input"]

## Define output directory
output_dir = os.path.join(config['output_dir'], "quantification")

# Read the samples table
samples = pd.read_table(config["data_table"], sep="\t", comment="#", dtype={"sample_alias": str})
samples.set_index("sample_alias", drop=False, inplace=True)

# Function to map samples to omics types
def create_omics_mapping(samples_df):
    return {
        str(row["sample_alias"]): (
            ["metagenomics", "metatranscriptomics"] if row["omics"] == "both" else [row["omics"]]
        )
        for _, row in samples_df.iterrows()
    }

# Create mapping
omics_mapping = create_omics_mapping(samples)

# Extract catalogues
catalogues = list(config["quantification"]["catalogues"].keys())

# Debugging output
print("Omics mapping:", omics_mapping)
print("Catalogues:", catalogues)

workdir:
    output_dir

# Include relevant rules
include: '../rules/quantification/salmon/indexing.smk'
include: '../rules/quantification/salmon/pseudoalignment.smk'

# Check if any catalogue has a BED file and include the rule if needed
if any("bed" in config["quantification"]["catalogues"][c] for c in catalogues):
    include: '../rules/quantification/get_gene_alignments.smk'

# Collect all outputs for Salmon quantification
salmon_quant_outputs = []

for sample, otypes in omics_mapping.items():
    for omics in otypes:
        for catalogue in catalogues:
            salmon_quant_outputs.append(f"coverage/{catalogue}/{omics}/{sample}/salmon/quant.sf")

# Define the all rule
rule all:
    input:
        salmon_quant_outputs
