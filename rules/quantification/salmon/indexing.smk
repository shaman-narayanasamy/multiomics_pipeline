rule salmon_index_catalogue:
    input:
        catalogue="{catalogue}/concatenated_catalogue.fa"
    output:
        index_dir=directory("salmon/{catalogue}/index"),
        fixed_fasta="salmon/{catalogue}/fixed.fasta"
    threads: 14
    conda: 
        "../../../../envs/salmon_env.yml"
    container:
        "https://depot.galaxyproject.org/singularity/salmon:1.8.0--h7e5ed60_1"
    benchmark: "salmon/{catalogue}/benchmark/index.txt"
    log: "salmon/{catalogue}/log/index.log"
    shell:
        """
        mkdir -p {output.index_dir}

        cat {input.catalogue} | sed -e 's/ //g' | \
        sed -e 's/|/_/g' > {output.fixed_fasta}

        salmon index -t {output.fixed_fasta} \
        -i {output.index_dir} --gencode -p {threads}
        """
