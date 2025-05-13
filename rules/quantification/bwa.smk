rule bwa_index_assembly:
    input:
        fasta = lambda wildcards: config["catalogues"][wildcards.catalogue]["fasta"]
    output:
        index_done = touch("{catalogue}/indexes/bwa_index.done"),
        fasta = "{catalogue}/indexes/sequences.fa",
        fasta_amb="{catalogue}/indexes/sequences.fa.amb",
        fasta_bwt="{catalogue}/indexes/sequences.fa.bwt",
        fasta_pac="{catalogue}/indexes/sequences.fa.pac",
        fasta_ann="{catalogue}/indexes/sequences.fa.ann",
        fasta_sa="{catalogue}/indexes/sequences.fa.sa"
    resources:
        mem_mb = 100000
    threads: 6
    conda: "bwa_env"
    benchmark: "{catalogue}/indexes/benchmarks/bwa_indexing.txt"
    log: "{catalogue}/indexes/logs/bwa_indexing.txt"
    shell:
        """
        ln -fs {input.fasta} {wildcards.catalogue}/indexes/sequences.fa

        bwa index {wildcards.catalogue}/indexes/sequences.fa
        """

def get_inputs(wildcards):
    if wildcards.omics == "metatranscriptomics":
        suffix = "processed.filtered.fastq.gz"
        reads_dir = mt_reads_dir
    else:
        suffix = "processed.fastq.gz"
        reads_dir = mg_reads_dir

    return {
        "r_1": f"{reads_dir}/{wildcards.sample}/{wildcards.sample}_R1.{suffix}",
        "r_2": f"{reads_dir}/{wildcards.sample}/{wildcards.sample}_R2.{suffix}",
        "r_se": f"{reads_dir}/{wildcards.sample}/{wildcards.sample}_SE.{suffix}",
        "fasta": f"{wildcards.catalogue}/indexes/sequences.fa",
        "fasta_amb": f"{wildcards.catalogue}/indexes/sequences.fa.amb",
        "fasta_bwt": f"{wildcards.catalogue}/indexes/sequences.fa.bwt",
        "fasta_pac": f"{wildcards.catalogue}/indexes/sequences.fa.pac",
        "fasta_ann": f"{wildcards.catalogue}/indexes/sequences.fa.ann",
        "fasta_sa": f"{wildcards.catalogue}/indexes/sequences.fa.sa"
    }

print("valid_sample_omics =", valid_sample_omics)

rule bwa_mapping_catalogue:
    input:
        r_1 = lambda wildcards: get_inputs(wildcards)["r_1"],
        r_2 = lambda wildcards: get_inputs(wildcards)["r_2"],
        r_se = lambda wildcards: get_inputs(wildcards)["r_se"],
        fasta = lambda wildcards: get_inputs(wildcards)["fasta"],
        fasta_amb = lambda wildcards: get_inputs(wildcards)["fasta_amb"],
        fasta_bwt = lambda wildcards: get_inputs(wildcards)["fasta_bwt"],
        fasta_pac = lambda wildcards: get_inputs(wildcards)["fasta_pac"],
        fasta_ann = lambda wildcards: get_inputs(wildcards)["fasta_ann"],
        fasta_sa = lambda wildcards: get_inputs(wildcards)["fasta_sa"],
    output:
        '{catalogue}/alignments/{omics}/{sample}.{omics}.reads.sorted.bam',
    params: 
        prefix = "{catalogue}/alignments/{omics}/{sample}.{omics}.reads",
        memory = 250
    resources:
        memory = 250
    threads: 24 
    conda: "bwa_env"
    benchmark: "{catalogue}/alignments/{omics}/benchmarks/{sample}.bwa_mapping.txt"
    log: "{catalogue}/alignments/{omics}/logs/{sample}.bwa_mapping.txt"
    shell:
        """

        SAMHEADER="@RG\\tID:{wildcards.sample}\\tSM:MG"

        PREFIX={params.prefix}
        
        MEM_PER_CORE=$(({params.memory}/{threads}))
        
        mkdir -p $(dirname $PREFIX.merged.bam)

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
        '{catalogue}/alignments/{omics}/{sample}.{omics}.reads.sorted.bam'
    output:
        '{catalogue}/alignments/{omics}/{sample}.{omics}.reads.sorted.bam.bai'
    conda: "bwa_env"
    benchmark: "{catalogue}/alignments/{omics}/benchmarks/{sample}.index_bam.txt"
    log: "{catalogue}/alignments/{omics}/logs/{sample}.index_bam.txt"
    shell:
        """
        samtools index {input} > {log} 2>&1
        """

rule flagstat_assembly_bam:
    input:
        '{catalogue}/alignments/{omics}/{sample}.{omics}.reads.sorted.bam'
    output:
        '{catalogue}/flagstats/{omics}/{sample}.{omics}.reads.sorted.flagstat.txt'
    conda: "bwa_env"
    benchmark: "{catalogue}/flagstats/{omics}/benchmarks/{sample}.flagstat.txt"
    log: "{catalogue}/flagstats/{omics}/logs/{sample}.flagstat.txt"
    shell:
        """
        samtools flagstat {input} > {output}
        """
