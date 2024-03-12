rule sortmerna_rrna_paired:
    input:
        paired_read_1 = "{sample}/{sample}_R1.processed.fastq.gz",
        paired_read_2 = "{sample}/{sample}_R2.processed.fastq.gz",
        index_donefile=os.path.join(config['sortmerna']['db_path'], "indices.done")
    output:
        filtered_paired_read_1 = "{sample}/{sample}_R1.processed.rrna_removed.fastq.gz",
        filtered_paired_read_2 = "{sample}/{sample}_R2.processed.rrna_removed.fastq.gz",
        filtered_unpaired_read_1 = temp("{sample}/{sample}_unpaired_R1.processed.rrna_removed.fastq.gz"),
        filtered_unpaired_read_2 = temp("{sample}/{sample}_unpaired_R2.processed.rrna_removed.fastq.gz")
    params: 
        db_path=config['sortmerna']['db_path'],
        out_prefix_paired = "{sample}/{sample}_tmp_paired.unfiltered", # output prefix for paired reads
        tmp_dir = config["tmp_dir"]
    resources:
        cpus_per_task=24,
        time=4320,
    conda: "../../../envs/sortmerna_env.yml"
    benchmark: "{sample}/benchmarks/preprocessing_filtering_paired.txt"
    log: "{sample}/logs/preprocessing_filtering_paired.txt"
    shell: 
        """ 
        # Remove directory because sortmerna will block the analysis
        rm -rf {params.tmp_dir}/{wildcards.sample}/paired

        # Run SortMeRNA for paired-end reads
        sortmerna \
                  --workdir {params.tmp_dir}/{wildcards.sample}/paired \
                  --ref {params.db_path}/rfam-5.8s-database-id98.fasta \
                  --ref {params.db_path}/silva-arc-16s-id95.fasta \
                  --ref {params.db_path}/silva-bac-16s-id90.fasta \
                  --ref {params.db_path}/silva-euk-18s-id95.fasta \
                  --ref {params.db_path}/rfam-5s-database-id98.fasta \
                  --ref {params.db_path}/silva-arc-23s-id98.fasta \
                  --ref {params.db_path}/silva-bac-23s-id98.fasta \
                  --ref {params.db_path}/silva-euk-28s-id98.fasta \
                  --idx-dir {params.db_path}/idx \
                  --reads {input.paired_read_1} \
                  --reads {input.paired_read_2} \
                  --threads {resources.cpus_per_task} \
                  --other {params.tmp_dir}/{params.out_prefix_paired} \
                  --fastx \
                  --out2 \
                  --zip-out yes \
                  --sout

            mv {params.tmp_dir}/{params.out_prefix_paired}_paired_fwd.fq.gz {output.filtered_paired_read_1}
            mv {params.tmp_dir}/{params.out_prefix_paired}_paired_rev.fq.gz {output.filtered_paired_read_2}
            mv {params.tmp_dir}/{params.out_prefix_paired}_singleton_fwd.fq.gz {output.filtered_unpaired_read_1}
            mv {params.tmp_dir}/{params.out_prefix_paired}_singleton_rev.fq.gz {output.filtered_unpaired_read_2}
        """

rule sortmerna_rrna_single:
    input:
        unpaired_read = "{sample}/{sample}_SE.processed.fastq.gz",
        filtered_unpaired_read_1 = "{sample}/{sample}_unpaired_R1.processed.rrna_removed.fastq.gz",
        filtered_unpaired_read_2 = "{sample}/{sample}_unpaired_R2.processed.rrna_removed.fastq.gz",
        index_donefile=os.path.join(config['sortmerna']['db_path'], "indices.done")
    output:
        filtered_unpaired_read = "{sample}/{sample}_SE.processed.rrna_removed.fastq.gz",
    params: 
        db_path=config['sortmerna']['db_path'],
        out_prefix_unpaired = "{sample}/{sample}_SE.non_rrna", # output prefix for unpaired reads
        tmp_dir = config["tmp_dir"]
    resources:
        cpus_per_task=12,
        runtime=2880,
    conda: "../../../envs/sortmerna_env.yml"
    benchmark: "{sample}/benchmarks/preprocessing_filtering_single.txt"
    log: "{sample}/logs/preprocessing_filtering_single.txt"
    shell: 
        """
        # Remove directory because sortmerna will block the analysis
        rm -rf {params.tmp_dir}/{wildcards.sample}/single

        # Check if file is empty
        if [[ -s {input.unpaired_read} ]]; then
            # Run SortMeRNA for unpaired reads
            sortmerna \
                      --workdir {params.tmp_dir}/{wildcards.sample}/single \
                      --ref {params.db_path}/rfam-5.8s-database-id98.fasta \
                      --ref {params.db_path}/silva-arc-16s-id95.fasta \
                      --ref {params.db_path}/silva-bac-16s-id90.fasta \
                      --ref {params.db_path}/silva-euk-18s-id95.fasta \
                      --ref {params.db_path}/rfam-5s-database-id98.fasta \
                      --ref {params.db_path}/silva-arc-23s-id98.fasta \
                      --ref {params.db_path}/silva-bac-23s-id98.fasta \
                      --ref {params.db_path}/silva-euk-28s-id98.fasta \
                      --idx-dir {params.db_path}/idx \
                      --reads {input.unpaired_read} \
                      --threads {resources.cpus_per_task} \
                      --other {params.tmp_dir}/{params.out_prefix_unpaired} \
                      --zip-out yes \
                      --fastx

            zcat {params.tmp_dir}/{params.out_prefix_unpaired}.fq.gz \
                 {input.filtered_unpaired_read_1} \
                 {input.filtered_unpaired_read_2} | gzip > \
                 {output.filtered_unpaired_read}
        else
            touch {output.filtered_unpaired_read}
        fi
        """
        
rule rename_filtered_reads:
    input:
        filtered_paired_read_1 = "{sample}/{sample}_R1.processed.rrna_removed.fastq.gz",
        filtered_paired_read_2 = "{sample}/{sample}_R2.processed.rrna_removed.fastq.gz",
        filtered_unpaired_read = "{sample}/{sample}_SE.processed.rrna_removed.fastq.gz",
    output:
        renamed_paired_read_1 = "{sample}/{sample}_R1.processed.filtered.fastq.gz",
        renamed_paired_read_2 = "{sample}/{sample}_R2.processed.filtered.fastq.gz",
        renamed_unpaired_read = "{sample}/{sample}_SE.processed.filtered.fastq.gz",
    shell:
        """
        # Create soft link (as a way to rename the files)
        ln -s $(realpath {input.filtered_paired_read_1}) $(realpath {output.renamed_paired_read_1})
        ln -s $(realpath {input.filtered_paired_read_2}) $(realpath {output.renamed_paired_read_2})

        # Create soft link as a way to rename the files 
        ln -s $(realpath {input.filtered_unpaired_read}) $(realpath {output.renamed_unpaired_read})
        """

