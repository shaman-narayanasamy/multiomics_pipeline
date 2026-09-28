SORTMERNA_CONFIG = config["sortmerna"]
SORTMERNA_DB_PATH = SORTMERNA_CONFIG["db_path"]
SORTMERNA_FILTER_LENGTH = SORTMERNA_CONFIG["filter_length"]
SORTMERNA_FILTER_HUMAN = SORTMERNA_CONFIG.get("filter_human", True)
SORTMERNA_DEFAULT_RRNA_REFS = [
    "rfam-5.8s-database-id98.fasta",
    "silva-arc-16s-id95.fasta",
    "silva-bac-16s-id90.fasta",
    "silva-euk-18s-id95.fasta",
    "rfam-5s-database-id98.fasta",
    "silva-arc-23s-id98.fasta",
    "silva-bac-23s-id98.fasta",
    "silva-euk-28s-id98.fasta",
]
SORTMERNA_RRNA_REFS = [
    ref if os.path.isabs(ref) else os.path.join(SORTMERNA_DB_PATH, ref)
    for ref in SORTMERNA_CONFIG.get("rrna_refs", SORTMERNA_DEFAULT_RRNA_REFS)
]
SORTMERNA_HUMAN_FILTERED_REFS = [
    os.path.join(SORTMERNA_DB_PATH, f"hg38_genome-minlength_{SORTMERNA_FILTER_LENGTH}.fasta"),
    os.path.join(SORTMERNA_DB_PATH, f"hg38_mrna-minlength_{SORTMERNA_FILTER_LENGTH}.fasta"),
]
SORTMERNA_INDEX_REFS = SORTMERNA_RRNA_REFS + (
    SORTMERNA_HUMAN_FILTERED_REFS if SORTMERNA_FILTER_HUMAN else []
)
SORTMERNA_INDEX_REF_ARGS = " ".join(f"--ref {ref}" for ref in SORTMERNA_INDEX_REFS)

if SORTMERNA_FILTER_HUMAN:
    ## Sortmerna cannot handle sequences shorter than 19 bp, need to filter them out
    rule sortmerna_prepare_sequences:
        input:
            human_genome_fasta_path=SORTMERNA_CONFIG["human_genome_fasta_path"],
            human_mrna_fasta_path=SORTMERNA_CONFIG["human_mrna_fasta_path"]
        output:
            human_genome_fasta_filtered=SORTMERNA_HUMAN_FILTERED_REFS[0],
            human_mrna_fasta_filtered=SORTMERNA_HUMAN_FILTERED_REFS[1]
        params:
            filter_length=SORTMERNA_FILTER_LENGTH,
        resources:
            cpus_per_task=4,
            runtime=2880
        conda: "../../../envs/pullseq_env.yml"
        benchmark: "benchmarks/pullseq_filter_length.txt"
        log: "logs/pullseq_filter_length.txt"
        shell:
            """
            pullseq -i {input.human_genome_fasta_path} -m {params.filter_length} > {output.human_genome_fasta_filtered}

            pullseq -i {input.human_mrna_fasta_path} -m {params.filter_length} > {output.human_mrna_fasta_filtered}
            """

## This rule is only in place just in case the databases were not indexed
rule sortmerna_index_database:
    input:
        refs=SORTMERNA_INDEX_REFS
    output:
        index_path=directory(os.path.join(SORTMERNA_DB_PATH, "idx")),
        donefile=os.path.join(SORTMERNA_DB_PATH, "indices.done")
    params: 
        db_path=SORTMERNA_DB_PATH,
        ref_args=SORTMERNA_INDEX_REF_ARGS,
    resources:
        cpus_per_task=12,
        runtime=4320
    conda: "../../../envs/sortmerna_env.yml"
    log: "logs/sortmerna_index_database.txt"
    shell: 
        """
        sortmerna \
            --workdir {params.db_path} \
            --index 1 \
            --threads {resources.cpus_per_task} \
            {params.ref_args} &> {log}

        touch {output.donefile}
	"""
