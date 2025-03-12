rule salmon_quant:
    input:
        index_dir="coverage/salmon/{catalogue}/index",
        r1 = lambda wildcards: f"{mg_reads_dir}/{wildcards.sample}/{wildcards.sample}_R1.processed.fastq.gz"
            if wildcards.omics == "metagenomics"
            else f"{mt_reads_dir}/{wildcards.sample}/{wildcards.sample}_R1.processed.fastq.gz",
        r2 = lambda wildcards: f"{mg_reads_dir}/{wildcards.sample}/{wildcards.sample}_R2.processed.fastq.gz"
            if wildcards.omics == "metagenomics"
            else f"{mt_reads_dir}/{wildcards.sample}/{wildcards.sample}_R2.processed.fastq.gz",
    output:
        quant_out = directory("coverage/salmon/{catalogue}/{omics}/{sample}/quant.sf")
    params:
        lib_type = "A",  # Automatic detection of library type. Adjust as necessary.
        min_assigned_frags = config['salmon']['min_assigned_frags'],
        quant_outdir = "coverage/salmon/{catalogue}/{omics}/{sample}"
    threads: 14     # Adjust based on available resources
    conda: 
        "salmon_env"
    container:
        "https://depot.galaxyproject.org/singularity/salmon:1.8.0--h7e5ed60_1"
    benchmark: "coverage/salmon/{catalogue}/{omics}/{sample}/benchmarks/salmon_quant.txt"
    log: "coverage/salmon/{catalogue}/{omics}/{sample}/log/salmon_quant.log"
    shell:
        """
        salmon quant -i {input.index_dir} -l {params.lib_type} \
                     -1 {input.r1} -2 {input.r2} \
                     -p {threads} \
                     -o {params.quant_outdir} \
                     --minAssignedFrags 1
        """
