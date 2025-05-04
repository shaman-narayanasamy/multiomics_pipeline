rule megahit:
    input:
        filtered_paired_read_1 = os.path.join(input_dir, "{sample}/{sample}_R1.processed.filtered.fastq.gz"),
        filtered_paired_read_2 = os.path.join(input_dir, "{sample}/{sample}_R2.processed.filtered.fastq.gz"),
        filtered_unpaired_read = os.path.join(input_dir, "{sample}/{sample}_SE.processed.filtered.fastq.gz")
    output:
        assembly_fasta="{sample}/megahit_assembly/final.contigs.fa",
    resources: 
        cpus_per_task=24,
        runtime=2880
    threads: 24 
    conda: "../../../envs/megahit_env.yml"
    benchmark: os.path.join(output_dir, "{sample}/benchmarks/assembly.txt")
    log: os.path.join(output_dir, "{sample}/logs/assembly.txt")
    shell:
       """
       rm -rf {wildcards.sample}/megahit_assembly

       megahit -1 {input.filtered_paired_read_1} -2 {input.filtered_paired_read_2} \
       -r {input.filtered_unpaired_read} \
       -o {wildcards.sample}/megahit_assembly \
       -t {threads}
       """ 

rule rename_megahit_contigs:
    input:
        assembly_fasta="{sample}/megahit_assembly/final.contigs.fa",
    output:
        assembly_fasta="{sample}/megahit_assembly/{sample}.megahit_contigs.fa",
    shell:
        """
        sample_id="{wildcards.sample}"
        
	awk -v id="${{sample_id}}" '/^>/ {{print ">" id "_contig_" substr($1, 2); next}} 1' \
        {input.assembly_fasta} > {output.assembly_fasta}
        """

