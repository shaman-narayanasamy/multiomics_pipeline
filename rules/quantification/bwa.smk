rule bwa_index_assembly:
    input:
        fasta = lambda wildcards: config["quantification"]["catalogues"][wildcards.catalogue]["fasta"]
    output:
        "{catalogue}/sequences.fa",
        "{catalogue}/sequences.fa.amb",
        "{catalogue}/sequences.fa.bwt",
        "{catalogue}/sequences.fa.pac",
        "{catalogue}/sequences.fa.ann",
        "{catalogue}/sequences.fa.sa"
    resources:
        mem_mb = 100000
    threads: 6
    conda: "bwa_env"
    benchmark: os.path.join(output_dir, "{catalogue}/benchmarks/bwa_indexing.txt")
    log: os.path.join(output_dir, "{catalogue}/logs/bwa_indexing.txt")
    shell:
        """
        ln -fs {input.fasta} {wildcards.catalogue}/sequences.fa

        bwa index {wildcards.catalogue}/sequences.fa
        """

rule bwa_mapping_catalogue:
    input:
        r_1 = lambda wildcards: f"{mg_reads_dir}/{wildcards.sample}/{wildcards.sample}_R1.processed.fastq.gz" if wildcards.omics == "metagenomics"
            else f"{mt_reads_dir}/{wildcards.sample}/{wildcards.sample}_R1.processed.fastq.gz",
        r_2 = lambda wildcards: f"{mg_reads_dir}/{wildcards.sample}/{wildcards.sample}_R2.processed.fastq.gz" if wildcards.omics == "metagenomics"
            else f"{mt_reads_dir}/{wildcards.sample}/{wildcards.sample}_R2.processed.fastq.gz",
        r_se = lambda wildcards: f"{mg_reads_dir}/{wildcards.sample}/{wildcards.sample}_SE.processed.fastq.gz" if wildcards.omics == "metagenomics"
        else f"{mt_reads_dir}/{wildcards.sample}/{wildcards.sample}_SE.processed.fastq.gz",

        fasta = "{catalogue}/sequences.fa",
        fasta_amb="{catalogue}/sequences.fa.amb",
        fasta_bwt="{catalogue}/sequences.fa.bwt",
        fasta_pac="{catalogue}/sequences.fa.pac",
        fasta_ann="{catalogue}/sequences.fa.ann",
        fasta_sa="{catalogue}/sequences.fa.sa"
    output:
        'alignments/{catalogue}/{omics}/{sample}.{omics}.reads.sorted.bam',
    params: 
        prefix = "alignments/{catalogue}/{omics}/{sample}/{sample}.reads",
        memory = 250
    resources:
        memory = 250
    threads: 24 
    conda: "bwa_env"
    benchmark: os.path.join(output_dir, "alignments/{catalogue}/{omics}/benchmarks/{sample}.bwa_mapping.txt")
    log: os.path.join(output_dir, "alignments/{catalogue}/{omics}/logs/{sample}.bwa_mapping.txt")
    shell:
        """
        SAMHEADER="@RG\\tID:{wildcards.sample}\\tSM:MG"

        PREFIX={params.prefix}
        
        MEM_PER_CORE=$(({params.memory}/{threads}))

        # merge paired and se
        samtools merge --threads {threads} -f $PREFIX.merged.bam \
         <(bwa mem -v 1 -t {threads} -M -R \"$SAMHEADER\" {input.fasta} {input.r_1} {input.r_2} 2>> {log}| \
         samtools view --threads {threads} -bS -) \
         <(bwa mem -v 1 -t {threads} -M -R \"$SAMHEADER\" {input.fasta} {input.r_se} 2>> {log}| \
         samtools view --threads {threads} -bS -) 2>> {log}

        # sort
        samtools sort --threads {threads} -m ${{MEM_PER_CORE}}G $PREFIX.merged.bam > $PREFIX.sorted.bam 2>> {log}
        rm $PREFIX.merged.bam
        """

rule index_assembly_bam:
    input:
        'alignments/{catalogue}/{omics}/{sample}.{omics}.reads.sorted.bam'
    output:
        'alignments/{catalogue}/{omics}/{sample}.{omics}.reads.sorted.bam.bai'
    conda: "bwa_env"
    benchmark: os.path.join(output_dir, "alignments/{catalogue}/{omics}/benchmarks/{sample}.index_bam.txt")
    log: os.path.join(output_dir, "alignments/{catalogue}/{omics}/logs/{sample}.index_bam.txt")
    shell:
        """
        samtools index {input} > {log} 2>&1
        """

rule flagstat_assembly_bam:
    input:
        'alignments/{catalogue}/{omics}/{sample}.{omics}.reads.sorted.bam'
    output:
        'flagstats/{catalogue}/{omics}/{sample}.{omics}.reads.sorted.flagstat.txt'
    conda: "bwa_env"
    benchmark: os.path.join(output_dir, "flagstats/{catalogue}/{omics}/benchmarks/{sample}.flagstat.txt")
    log: os.path.join(output_dir, "flagstat/{catalogue}/{omics}/logs/{sample}.flagstat.txt")
    shell:
        """
        samtools flagstat {input} > {output}
        """
