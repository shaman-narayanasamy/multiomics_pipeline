rule crisprcasfinder:
    input:
        assembly = os.path.join(coassembly_dir, "{sample}/megahit_assembly/final.contigs.fa")
    output:
        output = directory("{sample}/crisprcasfinder/rawCas.fna")
    params: 
        executor = config["crisprcasfinder"]["executor_script_path"],
        threads = config["crisprcasfinder"]["threads"],
    benchmark: "{sample}/crisprcasfinder/benchmarks/{sample}.txt"
    log: "{sample}/crisprcasfinder/logs/{sample}.txt"
    shell:
       """
       {params.executor} {input.assembly} {output} {params.threads}
       """
