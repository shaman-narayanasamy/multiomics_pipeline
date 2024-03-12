## Sortmerna cannot handle sequences shorter than 19 bp, need to filter them out
rule sortmerna_prepare_sequences:
    input:
        human_genome_fasta_path=config['sortmerna']['human_genome_fasta_path'],
        human_mrna_fasta_path=config['sortmerna']['human_mrna_fasta_path']
    output:
        human_genome_fasta_filtered = os.path.join(config['sortmerna']['db_path'], f"hg38_genome-minlength_{config['sortmerna']['filter_length']}.fasta"),
        human_mrna_fasta_filtered = os.path.join(config['sortmerna']['db_path'], f"hg38_mrna-minlength_{config['sortmerna']['filter_length']}.fasta")
    params: 
        filter_length=config['sortmerna']['filter_length'],
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
        db_path=config['sortmerna']['db_path'],
        human_genome_fasta_filtered = os.path.join(config['sortmerna']['db_path'], f"hg38_genome-minlength_{config['sortmerna']['filter_length']}.fasta"),
        human_mrna_fasta_filtered = os.path.join(config['sortmerna']['db_path'], f"hg38_mrna-minlength_{config['sortmerna']['filter_length']}.fasta")
    output:
        index_path=directory(os.path.join(config['sortmerna']['db_path'], "idx")),
        donefile=os.path.join(config['sortmerna']['db_path'], "indices.done")
    params: 
        db_path=config['sortmerna']['db_path'],
    resources:
        cpus_per_task=12,
        runtime=4320
    conda: "../../../envs/sortmerna_env.yml"
    benchmark: "benchmarks/sortmerna_index_database.txt"
    log: "logs/sortmerna_index_database.txt"
    shell: 
        """
        sortmerna \
            --workdir {params.db_path} \
            --index 1 \
            --threads {resources.cpus_per_task} \
            --ref {params.db_path}/rfam-5.8s-database-id98.fasta \
            --ref {params.db_path}/silva-arc-16s-id95.fasta \
            --ref {params.db_path}/silva-bac-16s-id90.fasta \
            --ref {params.db_path}/silva-euk-18s-id95.fasta \
            --ref {params.db_path}/rfam-5s-database-id98.fasta \
            --ref {params.db_path}/silva-arc-23s-id98.fasta \
            --ref {params.db_path}/silva-bac-23s-id98.fasta \
            --ref {params.db_path}/silva-euk-28s-id98.fasta \
            --ref {params.db_path}/silva-euk-28s-id98.fasta \
            --ref {input.human_genome_fasta_filtered} \
            --ref {input.human_mrna_fasta_filtered} &> {log}

        touch {output.donefile}
	"""

