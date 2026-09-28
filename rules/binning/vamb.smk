rule vamb:
    input:
        fasta = "{sample}/all_prokaryotic_seqs.fa",
        bam = "{sample}/{sample}_metaG.reads.sorted.bam",
        bai = "{sample}/{sample}_metaG.reads.sorted.bam.bai"
    output:
        done = '{sample}/vamb.done'
    params:
        outdir = '{sample}/vamb',
        bamdir = '{sample}/vamb_bams',
        threads = config["vamb"]["threads"],
        min_contig_length = config["binning"]["min_contig_length"]
    conda: "../../envs/vamb_env.yml"
    container: "/ibex/user/naras0c/VAMB/vamb.sif"
    benchmark: os.path.join("{sample}/benchmarks/vamb.txt")
    log: os.path.join("{sample}/logs/vamb.txt")
    shell:
        """
        rm -rf {params.outdir}
        rm -rf {params.bamdir}
        mkdir -p {params.bamdir}
        ln -sf ../$(basename {input.bam}) {params.bamdir}/$(basename {input.bam})
        ln -sf ../$(basename {input.bai}) {params.bamdir}/$(basename {input.bai})

        vamb bin default \
        --outdir {params.outdir} \
        -p {params.threads} \
        --minfasta 200000 \
        --fasta {input.fasta} \
        --bamdir {params.bamdir} \
        -m {params.min_contig_length}

        touch {output.done}
        """

rule vamb_contig_to_bin:
    input:
        done = "{sample}/vamb.done"
    output:
        contig_to_bin="{sample}/vamb/contig_to_bin.tsv",
    params:
        bin_dir = "{sample}/vamb"
    shadow: "shallow"
    shell:
        """
        ls {params.bin_dir}/bins/*.fna | \
        xargs -I{{}} bash -c 'paste <(yes "{{}}" | \
        head -n $(grep -c "^>" {{}}) | \
        sed -e "s:{params.bin_dir}/bins/::g") \
        <(grep "^>" {{}} | \
        sed -e "s/>//g") <(yes "vamb" | \
        head -n $(grep -c "^>" {{}}))' | \
        sed -e 's/\.fna//g' > /tmp/tmp_file.tsv

	paste <(cut -f1 /tmp/tmp_file.tsv) \
        <(cut -f2 /tmp/tmp_file.tsv | cut -f1 -d ' ') \
        <(cut -f3 /tmp/tmp_file.tsv) > {output.contig_to_bin}
        """
