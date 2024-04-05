rule bwa_mg_mapping_on_assembly:
    input:
        r_1 = os.path.join(mg_reads_dir, "{sample}/{sample}_R1.processed.fastq.gz"),
        r_2 = os.path.join(mg_reads_dir, "{sample}/{sample}_R2.processed.fastq.gz"),
        r_se = os.path.join(mg_reads_dir, "{sample}/{sample}_SE.processed.fastq.gz"),
        assembly="{sample}/{sample}.coassembly_contigs.fa",
        assembly_amb="{sample}/{sample}.coassembly_contigs.fa.amb",
        assembly_bwt="{sample}/{sample}.coassembly_contigs.fa.bwt",
        assembly_pac="{sample}/{sample}.coassembly_contigs.fa.pac",
        assembly_ann="{sample}/{sample}.coassembly_contigs.fa.ann",
        assembly_sa="{sample}/{sample}.coassembly_contigs.fa.sa"
    output:
        '{sample}/{sample}_metaG.reads.sorted.bam'
    params: 
        prefix = "{sample}/{sample}_metaG.reads",
        memory = 250
    resources:
        memory = 250
    threads: 24 
    conda: "../../envs/bwa_env.yml"
    benchmark: os.path.join(output_dir, "{sample}/benchmarks/bwa_mapping.txt")
    log: os.path.join(output_dir, "{sample}/logs/bwa_mapping.txt")
    shell:
        """
        SAMHEADER="@RG\\tID:{wildcards.sample}\\tSM:metaG"

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

rule index_mg_bam:
    input:
        '{sample}/{sample}_metaG.reads.sorted.bam'
    output:
        '{sample}/{sample}_metaG.reads.sorted.bam.bai'
    conda: "../../envs/bwa_env.yml"
    benchmark: os.path.join(output_dir, "{sample}/benchmarks/index_bam.txt")
    log: os.path.join(output_dir, "{sample}/logs/index_bam.txt")
    shell:
        """
        samtools index {input} > {log} 2>&1
        """

rule flagstat_mg_bam:
    input:
        '{sample}/{sample}_metaG.reads.sorted.bam'
    output:
        '{sample}/{sample}_metaG.reads.sorted.flagstat.txt'
    conda: "../../envs/bwa_env.yml"
    benchmark: os.path.join(output_dir, "{sample}/benchmarks/flagstat.txt")
    log: os.path.join(output_dir, "{sample}/logs/flagstat.txt")
    shell:
        """
        samtools flagstat {input} > {output}
        """
