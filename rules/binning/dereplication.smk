rule drep_collect_all_bins:
    input:
        sample_bins = expand("{sample}/magscot_bins", sample = samples.index)
    output:
        bins = "bin_paths.txt"
    threads: 1
    benchmark: "benchmarks/collect_all_bins.txt"
    log: "logs/collect_all_bins.txt"
    shell:
        """
        find {input} -type f | grep ".fasta$" > {output.bins}
        """

rule drep_dereplication:
    input:
        bins = "bin_paths.txt"
    output:
        output_dir = directory("dereplication")
    threads: 36
    conda: "../../envs/drep_env.yml"
    benchmark: "benchmarks/drep_derepliction.txt"
    log: "logs/drep.txt"
    shell: 
        """
        dRep dereplicate \
        {output.output_dir} \
        -p {threads} \
        -comp {config[drep][completeness]} \
        -con {config[drep][contamination]} \
        -strW {config[drep][strain_heterogeneity_weight]} \
        --P_ani {config[drep][P_ani]} \
        --S_ani {config[drep][S_ani]} \
        --run_tertiary_clustering -centW 0 \
        -g {input.bins}
        """

