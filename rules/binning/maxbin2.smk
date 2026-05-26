rule maxbin2:
    input:
        fasta = "{sample}/all_prokaryotic_seqs.fa",
        depth_file = "{sample}/contig_depth.txt"
    output:
        done = '{sample}/maxbin2.done',
        outlog = '{sample}/maxbin2/maxbin2.log'
    params:
        outdir = '{sample}/maxbin2',
        threads = config["maxbin2"]["threads"],
        min_contig_length = config["binning"]["min_contig_length"]
    conda: "../../envs/maxbin2_env.yml"
    benchmark: os.path.join("{sample}/benchmarks/maxbin2.txt")
    log: os.path.join("{sample}/logs/maxbin2.txt")
    shell:
        """
        mkdir -p {params.outdir}

	run_MaxBin.pl -contig {input.fasta} \
        -thread {params.threads} \
        -abund {input.depth_file} \
        -min_contig_length {params.min_contig_length} \
        -out {params.outdir}/maxbin2

        touch {output.done}
        """

rule maxbin2_contig_to_bin:
    input:
        done = "{sample}/maxbin2.done"
    output:
        contig_to_bin="{sample}/maxbin2/contig_to_bin.tsv",
    params:
        bin_dir = "{sample}/maxbin2"
    shell:
       """
       ls {params.bin_dir}/*.fasta | \
       xargs -I{{}} bash -c 'paste <(yes "{{}}" | \
       head -n $(grep -c "^>" {{}}) | \
       sed -e "s:{params.bin_dir}/::g") \
       <(grep "^>" {{}} | \
       sed -e "s/>//g") <(yes "maxbin2" | \
       head -n $(grep -c "^>" {{}}))' | \
       sed -e 's/\.fasta//g' > {output.contig_to_bin}
       """
