rule bwa_index_assembly:
    input:
        fasta = "{sample}/megahit_assembly/final.contigs.fa"
    output:
        "{sample}/megahit_assembly/final.contigs.fa.amb",
        "{sample}/megahit_assembly/final.contigs.fa.bwt",
        "{sample}/megahit_assembly/final.contigs.fa.pac",
        "{sample}/megahit_assembly/final.contigs.fa.ann",
        "{sample}/megahit_assembly/final.contigs.fa.sa"
    resources:
        mem_mb = 100000
    threads: 6
    conda: "../../../envs/bwa_env.yml"
    benchmark: os.path.join(output_dir, "{sample}/benchmarks/bwa_indexing.txt")
    log: os.path.join(output_dir, "{sample}/logs/bwa_indexing.txt")
    shell:
        """
        bwa index {input.fasta}
        """

rule bwa_mapping_on_assembly:
    input:
        r_1 = os.path.join(input_dir, "{sample}/{sample}_R1.processed.filtered.fastq.gz"),
        r_2 = os.path.join(input_dir, "{sample}/{sample}_R2.processed.filtered.fastq.gz"),
        r_se = os.path.join(input_dir, "{sample}/{sample}_SE.processed.filtered.fastq.gz"),
        assembly="{sample}/megahit_assembly/final.contigs.fa",
        assembly_amb="{sample}/megahit_assembly/final.contigs.fa.amb",
        assembly_bwt="{sample}/megahit_assembly/final.contigs.fa.bwt",
        assembly_pac="{sample}/megahit_assembly/final.contigs.fa.pac",
        assembly_ann="{sample}/megahit_assembly/final.contigs.fa.ann",
        assembly_sa="{sample}/megahit_assembly/final.contigs.fa.sa"
    output:
        '{sample}/{sample}_metaT.reads.sorted.bam'
    params: 
        prefix = "{sample}/{sample}_metaT.reads",
        memory = 250
    resources:
        memory = 250
    threads: 24 
    conda: "../../../envs/bwa_env.yml"
    benchmark: os.path.join(output_dir, "{sample}/benchmarks/bwa_mapping.txt")
    log: os.path.join(output_dir, "{sample}/logs/bwa_mapping.txt")
    shell:
        """
        SAMHEADER="@RG\\tID:{wildcards.sample}\\tSM:metaT"

        PREFIX={params.prefix}

        MEM_PER_CORE=$(({params.memory}/{threads}))

        # merge paired and se
        samtools merge --threads {threads} -f $PREFIX.merged.bam \
         <(bwa mem -v 1 -t {threads} -M -R \"$SAMHEADER\" {input.assembly} {input.r_1} {input.r_2} 2>> {log}| \
         samtools view --threads {threads} -bS -) \
         <(bwa mem -v 1 -t {threads} -M -R \"$SAMHEADER\" {input.assembly} {input.r_se} 2>> {log}| \
         samtools view --threads {threads} -bS -) 2>> {log}

        # sort
        samtools sort --threads {threads} -m ${{MEM_PER_CORE}}G $PREFIX.merged.bam > $PREFIX.sorted.bam 2>> {log}
        rm $PREFIX.merged.bam
        """

rule index_assembly_bam:
    input:
        '{sample}/{sample}_metaT.reads.sorted.bam'
    output:
        '{sample}/{sample}_metaT.reads.sorted.bai'
    conda: "../../../envs/bwa_env.yml"
    benchmark: os.path.join(output_dir, "{sample}/benchmarks/index_bam.txt")
    log: os.path.join(output_dir, "{sample}/logs/index_bam.txt")
    shell:
        """
        samtools index {input} > {log} 2>&1
        """

rule flagstat_assembly_bam:
    input:
        '{sample}/{sample}_metaT.reads.sorted.bam'
    output:
        '{sample}/{sample}_metaT.reads.sorted.flagstat.txt'
    conda: "../../../envs/bwa_env.yml"
    benchmark: os.path.join(output_dir, "{sample}/benchmarks/flagstat.txt")
    log: os.path.join(output_dir, "{sample}/logs/flagstat.txt")
    shell:
        """
        samtools flagstat {input} > {output}
        """
