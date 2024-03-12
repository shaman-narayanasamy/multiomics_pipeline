rule crass_reads:    
    input:
        filtered_mg_paired_read_1 = os.path.join(mg_reads_dir, "{sample}/{sample}_R1.processed.fastq.gz"),
        filtered_mg_paired_read_2 = os.path.join(mg_reads_dir, "{sample}/{sample}_R2.processed.fastq.gz"),
        filtered_mg_unpaired_read = os.path.join(mg_reads_dir, "{sample}/{sample}_SE.processed.fastq.gz"),
        filtered_mt_paired_read_1 = os.path.join(mt_reads_dir, "{sample}/{sample}_R1.processed.fastq.gz"),
        filtered_mt_paired_read_2 = os.path.join(mt_reads_dir, "{sample}/{sample}_R2.processed.fastq.gz"),
        filtered_mt_unpaired_read = os.path.join(mt_reads_dir, "{sample}/{sample}_SE.processed.fastq.gz"),
    output:
        outdir = directory("{sample}/crass_reads_out"),
        outfile = "{sample}/crass_reads_out/crass.crispr"
    conda: "../../envs/crass_env.yml"
    benchmark: "{sample}/benchmarks/crass_reads.txt"
    log: "{sample}/logs/crass_reads.txt"
    shell:
        """
        crass -o {output.outdir} {input}
        """

rule crass_contigs:    
    input:
        assembly = os.path.join(coassembly_dir, "{sample}/megahit_assembly/final.contigs.fa")
    output:
        outdir = directory("{sample}/crass_contigs_out"),
        outfile = "{sample}/crass_contigs_out/crass.crispr"
    conda: "../../envs/crass_env.yml"
    benchmark: "{sample}/benchmarks/crass_contigs.txt"
    log: "{sample}/logs/crass_contigs.txt"
    shell:
        """
        crass -o {output.outdir} {input}
        """

rule extract_crispr_information:
     input:
        crass_contigs = "{sample}/crass_contigs_out/crass.crispr",
        crass_reads = "{sample}/crass_reads_out/crass.crispr"
     output:
        crass_merged = "{sample}/crass.crispr",
        crass_spacers = "{sample}/spacers.fa",
        crass_repeats = "{sample}/repeats.fa",
        crass_flanks = "{sample}/flanks.fa"
     conda: "../../envs/crass_env.yml"
     benchmark: "{sample}/benchmarks/crass_contigs.txt"
     log: "{sample}/logs/crass_contigs.txt"
     shell:
         """
         crisprtools merge -s -o {output.crass_merged} {input}
         crisprtools extract -w {wildcards.sample} -sspacers.fa -drepeats.fa -fflanks.fa {output.crass_merged}  
         """
