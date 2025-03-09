import subprocess
import pandas as pd

tmp_dir = os.environ.get("tmp_dir", config['tmp_dir'])

## Input input directory
mt_reads_dir = config["input_dir"]["mt_assembly_input"]
mg_reads_dir = config["input_dir"]["mg_assembly_input"]

## Define output directory
output_dir = os.path.join(config['output_dir'],  "quantification")

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

# Construct a list of catalogues from the config file
catalogues = list(config["quantification"]["catalogues"].keys())

# Debugging output
print("Omics mapping:", omics_mapping)
print("Catalogues:", catalogues)

workdir:
    output_dir

include:
    '../rules/quantification/coverm.smk'

include:
    '../rules/quantification/bwa.smk'

if "bed" in config["quantification"]["catalogues"][catalogue]: 
    include: '../rules/quantification/get_gene_alignments.smk'

# Pre-compute the outputs
all_outputs = []

all_coverm_inputs = []
subset_bam_outputs = []

for sample, otypes in omics_mapping.items():
    for omics in otypes:
        for catalogue in catalogues:
            # Always include standard BAM
            all_coverm_inputs.append(f"alignments/{catalogue}/{omics}/{sample}.{omics}.reads.sorted.bam")

            # Only add gene-level BAM if the catalogue has a BED file
            if "bed" in config["quantification"]["catalogues"][catalogue]:
                gene_bam = f"alignments/{catalogue}/{omics}/{sample}.{omics}.genes.reads.sorted.bam"
                all_coverm_inputs.append(gene_bam)
                subset_bam_outputs.append(gene_bam)

# Define the all rule
rule all:
    input:
        all_coverm_inputs,  # Will automatically include subset_bam outputs when needed
        expand("coverage/{catalogue}/{omics}/coverm", catalogue = catalogues, omics = ["metagenomics", "metatranscriptomics"])
