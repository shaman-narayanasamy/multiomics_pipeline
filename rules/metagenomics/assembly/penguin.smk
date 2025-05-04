rule penguin_assembly:
    input:
        filtered_mg_paired_read_1 = os.path.join(mg_reads_dir, "{sample}/{sample}_R1.processed.fastq.gz"),
        filtered_mg_paired_read_2 = os.path.join(mg_reads_dir, "{sample}/{sample}_R2.processed.fastq.gz")
    output:
        assembly_fasta="{sample}/penguin_assembly/final.contigs.fa",
    resources: 
        cpus_per_task=24,
        runtime=2880
    threads: 24 
    conda: "../../../envs/plass_env.yml"
    benchmark: os.path.join(output_dir, "{sample}/benchmarks/penguin.txt")
    log: os.path.join(output_dir, "{sample}/logs/penguin.txt")
    shell:
       """
       mkdir -p {wildcards.sample}/penguin_assembly/tmp

       penguin guided_nuclassemble \
               {input.filtered_mg_paired_read_1} \
               {input.filtered_mg_paired_read_2} \
               {output.assembly_fasta} {wildcards.sample}/penguin_assembly/tmp \
               --threads {threads}

       rm -rf {wildcards.sample}/penguin_assembly/tmp
       """

rule rename_contigs:
    input:
        assembly_fasta="{sample}/penguin_assembly/final.contigs.fa",
    output:
        assembly_fasta="{sample}/penguin_assembly/{sample}.penguin_contigs.fa",
    shell:
        """
        sample_id="{wildcards.sample}"
        
	awk -v id="${{sample_id}}" '/^>/ {{print ">" id "_contig_" substr($1, 2); next}} 1' \
        {input.assembly_fasta} > {output.assembly_fasta}
        """

