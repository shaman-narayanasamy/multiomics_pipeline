rule salmon_index_catalogue:
    input:
        catalogue = lambda wildcards: config["quantification"]["catalogues"][wildcards.catalogue]["fasta"]
    output:
        index_dir=directory("coverage/salmon/{catalogue}/index"),
        fixed_fasta="coverage/salmon/{catalogue}/fixed.fasta"
    threads: 14
    conda: 
        "salmon_env"
    container:
        "https://depot.galaxyproject.org/singularity/salmon:1.8.0--h7e5ed60_1"
    benchmark: "coverage/salmon/{catalogue}/benchmark/index.txt"
    log: "coverage/salmon/{catalogue}/log/index.log"
    shell:
        """
        mkdir -p {output.index_dir}

        cat {input.catalogue} | sed -e 's/ //g' | \
        sed -e 's/|/_/g' > {output.fixed_fasta}

        salmon index -t {output.fixed_fasta} \
        -i {output.index_dir} --gencode -p {threads} --keepDuplicates
        """
