def get_crass_inputs(wildcards):
    result = []
    for sample, omics_list in omics_mapping.items():
        #print(f"Sample: {sample} | Omics list: {omics_list}")
        for omics in omics_list:
            #print(f"  - Omics: {omics}")
            result.append(f"{sample}/crass_reads_out/{omics}/{wildcards.filetype}.fa")
    return result

rule concatenate_crass_files:
    input:
        get_crass_inputs
    output:
        "aggregated_crass/{filetype}.fa"
    shell:
        "cat {input} > {output}"

rule mmseqs2_cluster:
    input:
        concatenated_fasta = "aggregated_crass/{filetype}.fa"
    output:
        "mmseqs/{filetype}_cluster.tsv",
        "mmseqs/{filetype}_rep_seq.fasta",
        "mmseqs/{filetype}_all_seqs.fasta"
    params: 
        min_seq_id = config["cluster_ani"]["mmseqs2"]["min_ani"],
        min_cov = config["cluster_ani"]["mmseqs2"]["min_cov"],
        cov_mode = config["cluster_ani"]["mmseqs2"]["cov_mode"],
        alignment_mode = config["cluster_ani"]["mmseqs2"]["alignment_mode"],
        cluster_mode = config["cluster_ani"]["mmseqs2"]["cluster_mode"],
        max_seqs = config["cluster_ani"]["mmseqs2"]["max_seqs"]
    resources:
        cpus_per_task = 24,
        mem = "120GB",
        runtime = 7200
    conda: "mmseqs2_env"
    benchmark: "benchmarks/mmseqs/cluster_{filetype}.txt"
    log: "logs/mmseqs/crass_cluster_{filetype}.txt"
    shell:
        """
        mmseqs easy-cluster {input.concatenated_fasta} mmseqs/{wildcards.filetype} {tmp_dir} \
            --min-seq-id {params.min_seq_id} \
            --cov-mode {params.cov_mode} \
            -c {params.min_cov} \
            --alignment-mode {params.alignment_mode} \
            --threads {resources.cpus_per_task} \
            --cluster-mode {params.cluster_mode} \
            --max-seqs {params.max_seqs}
        """
