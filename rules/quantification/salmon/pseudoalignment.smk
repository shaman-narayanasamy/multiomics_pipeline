rule salmon_quant:
    input:
        index = "salmon/{catalogue}/index",
        r1 = "%s/{sample}/{sample}_R1.processed.filtered.fastq.gz" % input_dir,
        r2 = "%s/{sample}/{sample}_R2.processed.filtered.fastq.gz" % input_dir
    output:
        quant_dir = directory("salmon/{catalogue}/{sample}/quant.sf")
    params:
        lib_type = "A",  # Automatic detection of library type. Adjust as necessary.
        min_assigned_frags = config['salmon']['min_assigned_frags']
    threads: 14     # Adjust based on available resources
    conda: 
        "../../../../envs/salmon_env.yml"
    container:
        "https://depot.galaxyproject.org/singularity/salmon:1.8.0--h7e5ed60_1"
    benchmark: "salmon/{catalogue}/{sample}/benchmarks/salmon_quant.txt"
    log: "salmon/{catalogue}/{sample}/log/salmon_quant.log"
    shell:
        """
        salmon quant -i {input.index} -l {params.lib_type} \
                     -1 {input.r1} -2 {input.r2} \
                     -p {threads} \
                     -o {output.quant_dir} \
                     --minAssignedFrags 1
        """
