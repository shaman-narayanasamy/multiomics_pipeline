rule get_mt_assembly:
    output:
        mt_contigs = "{sample}/{sample}.mt_contigs.fa"
    params:
        mt_contigs = lambda wildcards: coassembly_mt_contigs(wildcards.sample)
    shell:
        """
        ln -s $(realpath {params.mt_contigs}) $(realpath {output})
        """

rule megahit:
    input:
        filtered_mg_paired_read_1 = lambda wildcards: coassembly_mg_read(wildcards.sample, "R1"),
        filtered_mg_paired_read_2 = lambda wildcards: coassembly_mg_read(wildcards.sample, "R2"),
        filtered_mg_unpaired_read = lambda wildcards: coassembly_mg_read(wildcards.sample, "SE"),
        filtered_mt_paired_read_1 = lambda wildcards: coassembly_mt_read(wildcards.sample, "R1"),
        filtered_mt_paired_read_2 = lambda wildcards: coassembly_mt_read(wildcards.sample, "R2"),
        filtered_mt_unpaired_read = lambda wildcards: coassembly_mt_read(wildcards.sample, "SE"),
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
