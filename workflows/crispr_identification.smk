import subprocess
import pandas as pd

tmp_dir = os.environ.get("tmp_dir", config['tmp_dir'])

## Input input directory
mt_reads_dir = config["input_dir"]["mt_assembly_input"]
mg_reads_dir = config["input_dir"]["mg_assembly_input"]
coassembly_dir = config["input_dir"]["coassembly_contig_input"]
phage_dirs = config["input_dir"]["crispr_link_input"]

## Define output directory
output_dir = os.path.join(config['output_dir'],  "crispr_identification")

# Read the samples table
samples = pd.read_table(
    config["data_table"], sep="\t", comment="#", dtype={"sample_alias": str}
).set_index("sample_alias", drop=False)

# Define a function to process omics types
def create_omics_mapping(samples_df):
    """
    Creates a mapping of sample aliases to their omics types.
    Returns a dictionary with sample aliases as keys and a list of omics types as values.
    """
    return {
        str(row["sample_alias"]): (
            ["metagenomics", "metatranscriptomics"] if row["omics"] == "both" else [row["omics"]]
        )
        for _, row in samples_df.iterrows()
    }

# Create the mapping
omics_mapping = create_omics_mapping(samples)

# Debugging output
print("Omics mapping:", omics_mapping)

workdir:
    output_dir

include:
    '../rules/crispr_identification/crass.smk'

include:
    '../rules/crispr_identification/spacepharer.smk'

include:
    '../rules/crispr_identification/crisprcasfinder.smk'


# Pre-compute the outputs
all_outputs = []

# Metagenomics-only samples
for sample, otypes in omics_mapping.items():
    if "metagenomics" in otypes:
        all_outputs.append(f"{sample}/crass_reads_out/metagenomics/crass.crispr")
        all_outputs.append(f"{sample}/crass_contigs_out/crass.crispr")

# Metatranscriptomics-only samples
for sample, otypes in omics_mapping.items():
    if "metatranscriptomics" in otypes:
        all_outputs.append(f"{sample}/crass_reads_out/metatranscriptomics/crass.crispr")
        all_outputs.append(f"{sample}/crass_contigs_out/crass.crispr")

# Both omics samples
for sample, otypes in omics_mapping.items():
    if "both" in otypes:
        all_outputs.append(f"{sample}/crass_reads_out/metagenomics/crass.crispr")
        all_outputs.append(f"{sample}/crass_reads_out/metatranscriptomics/crass.crispr")
        all_outputs.append(f"{sample}/crass_contigs_out/crass.crispr")

# Define the all rule
rule all:
    input:
        all_outputs,
        "spacers_rep_seq.fasta",
        "repeats_rep_seq.fasta",
        "flanks_rep_seq.fasta"
