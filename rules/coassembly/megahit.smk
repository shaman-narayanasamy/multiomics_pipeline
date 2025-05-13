rule get_mt_assembly:
    output:
        mt_contigs = "{sample}/{sample}.mt_contigs.fa"
    params:
        mt_contigs = os.path.join(mt_contigs_dir, "{sample}/megahit_assembly/final.contigs.fa")
    shell:
        """
        ln -s $(realpath {params.mt_contigs}) $(realpath {output})
        """

rule megahit:
    input:
        filtered_mg_paired_read_1 = os.path.join(mg_reads_dir, "{sample}/{sample}_R1.processed.fastq.gz"),
        filtered_mg_paired_read_2 = os.path.join(mg_reads_dir, "{sample}/{sample}_R2.processed.fastq.gz"),
        filtered_mg_unpaired_read = os.path.join(mg_reads_dir, "{sample}/{sample}_SE.processed.fastq.gz"),
        filtered_mt_paired_read_1 = os.path.join(mt_reads_dir, "{sample}/{sample}_R1.processed.filtered.fastq.gz"),
        filtered_mt_paired_read_2 = os.path.join(mt_reads_dir, "{sample}/{sample}_R2.processed.filtered.fastq.gz"),
        filtered_mt_unpaired_read = os.path.join(mt_reads_dir, "{sample}/{sample}_SE.processed.filtered.fastq.gz"),
        mt_contigs = "{sample}/{sample}.mt_contigs.fa"
    output:
        assembly_fasta="{sample}/megahit_assembly/final.contigs.fa",
    resources: 
        cpus_per_task=24,
        runtime=2880
    threads: 24 
    conda: "../../envs/megahit_env.yml"
    benchmark: os.path.join(output_dir, "{sample}/benchmarks/megahit.txt")
    log: os.path.join(output_dir, "{sample}/logs/megahit.txt")
    shell:
       """
       rm -rf {wildcards.sample}/megahit_assembly

       megahit -1 {input.filtered_mg_paired_read_1},{input.filtered_mt_paired_read_1} \
               -2 {input.filtered_mg_paired_read_2},{input.filtered_mt_paired_read_2} \
               -r {input.filtered_mg_unpaired_read},{input.filtered_mt_unpaired_read},{input.mt_contigs} \
               -o {wildcards.sample}/megahit_assembly \
               -t {threads} \
               --continue
       """ 

rule rename_contigs:
    input:
        coassembly_fasta="{sample}/megahit_assembly/final.contigs.fa",
    output:
        coassembly_fasta="{sample}/{sample}.coassembly_contigs.fa",
    shell:
        """
        sample_id="{wildcards.sample}"
        
	awk -v id="${{sample_id}}" '/^>/ {{print ">" id "_contig_" substr($1, 2); next}} 1' \
        {input.coassembly_fasta} > {output.coassembly_fasta}
        """

