rule bwa_index_assembly:
    input:
        #fasta = lambda wildcards: config["catalogues"]["non_redundant_representative_contigs"]["fasta"]
        fasta = lambda wildcards: config["catalogues"][wildcards.catalogue]["fasta"]
        #fasta = lambda wildcards: config["quantification"]["catalogues"][wildcards.catalogue.split("/")[0]]["fasta"]
    output:
        index_done = touch("indexes/{catalogue}/bwa_index.done"),
        fasta = "indexes/{catalogue}/sequences.fa",
        fasta_amb="indexes/{catalogue}/sequences.fa.amb",
        fasta_bwt="indexes/{catalogue}/sequences.fa.bwt",
        fasta_pac="indexes/{catalogue}/sequences.fa.pac",
        fasta_ann="indexes/{catalogue}/sequences.fa.ann",
        fasta_sa="indexes/{catalogue}/sequences.fa.sa"
    resources:
        mem_mb = 100000
    threads: 6
    conda: "bwa_env"
    benchmark: os.path.join(output_dir, "{catalogue}/benchmarks/bwa_indexing.txt")
    log: os.path.join(output_dir, "{catalogue}/logs/bwa_indexing.txt")
    shell:
        """
        ln -fs {input.fasta} indexes/{wildcards.catalogue}/sequences.fa

        bwa index indexes/{wildcards.catalogue}/sequences.fa
        """

#def get_inputs(wildcards):
#    reads_dir = mt_reads_dir if wildcards.omics == "metatranscriptomics" else mg_reads_dir
#    return {
#        "r_1": f"{reads_dir}/{wildcards.sample}/{wildcards.sample}_R1.processed.filtered.fastq.gz",
#        "r_2": f"{reads_dir}/{wildcards.sample}/{wildcards.sample}_R2.processed.filtered.fastq.gz",
#        "r_se": f"{reads_dir}/{wildcards.sample}/{wildcards.sample}_SE.processed.filtered.fastq.gz",
#        "fasta": f"indexes/{wildcards.catalogue}/sequences.fa",
#        "fasta_amb": f"indexes/{wildcards.catalogue}/sequences.fa.amb",
#        "fasta_bwt": f"indexes/{wildcards.catalogue}/sequences.fa.bwt",
#        "fasta_pac": f"indexes/{wildcards.catalogue}/sequences.fa.pac",
#        "fasta_ann": f"indexes/{wildcards.catalogue}/sequences.fa.ann",
#        "fasta_sa": f"indexes/{wildcards.catalogue}/sequences.fa.sa"
#    }

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
        "fasta": f"indexes/{wildcards.catalogue}/sequences.fa",
        "fasta_amb": f"indexes/{wildcards.catalogue}/sequences.fa.amb",
        "fasta_bwt": f"indexes/{wildcards.catalogue}/sequences.fa.bwt",
        "fasta_pac": f"indexes/{wildcards.catalogue}/sequences.fa.pac",
        "fasta_ann": f"indexes/{wildcards.catalogue}/sequences.fa.ann",
        "fasta_sa": f"indexes/{wildcards.catalogue}/sequences.fa.sa"
    }

print("valid_sample_omics =", valid_sample_omics)

#rule bwa_mapping_catalogue:
#    input:
#        r_1 = lambda wildcards: f"{mg_reads_dir}/{wildcards.sample}/{wildcards.sample}_R1.processed.fastq.gz" if wildcards.omics == "metagenomics"
#            else f"{mt_reads_dir}/{wildcards.sample}/{wildcards.sample}_R1.processed.filtered.fastq.gz",
#
#        r_2 = lambda wildcards: f"{mg_reads_dir}/{wildcards.sample}/{wildcards.sample}_R2.processed.fastq.gz" if wildcards.omics == "metagenomics"
#            else f"{mt_reads_dir}/{wildcards.sample}/{wildcards.sample}_R2.processed.filtered.fastq.gz",
#
#        r_se = lambda wildcards: f"{mg_reads_dir}/{wildcards.sample}/{wildcards.sample}_SE.processed.fastq.gz" if wildcards.omics == "metagenomics"
#            else f"{mt_reads_dir}/{wildcards.sample}/{wildcards.sample}_SE.processed.filtered.fastq.gz",
#        fasta = "indexes/{catalogue}/sequences.fa",
#        fasta_amb="indexes/{catalogue}/sequences.fa.amb",
#        fasta_bwt="indexes/{catalogue}/sequences.fa.bwt",
#        fasta_pac="indexes/{catalogue}/sequences.fa.pac",
#        fasta_ann="indexes/{catalogue}/sequences.fa.ann",
#        fasta_sa="indexes/{catalogue}/sequences.fa.sa"


print(get_inputs)

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
        prefix = "{catalogue}/alignments/{omics}/{sample}/{omics}.{sample}.reads",
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
        '{catalogue}/alignments/{omics}/{sample}.{omics}.reads.sorted.bam'
    output:
        '{catalogue}/alignments/{omics}/{sample}.{omics}.reads.sorted.bam.bai'
    conda: "bwa_env"
    benchmark: os.path.join(output_dir, "alignments/{catalogue}/{omics}/benchmarks/{sample}.index_bam.txt")
    log: os.path.join(output_dir, "alignments/{catalogue}/{omics}/logs/{sample}.index_bam.txt")
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
    benchmark: os.path.join(output_dir, "flagstats/{catalogue}/{omics}/benchmarks/{sample}.flagstat.txt")
    log: os.path.join(output_dir, "flagstat/{catalogue}/{omics}/logs/{sample}.flagstat.txt")
    shell:
        """
        samtools flagstat {input} > {output}
        """
