rule vamb:
    input:
        fasta = "{sample}/all_prokaryotic_seqs.fa",
        bam = "{sample}/{sample}_metaG.reads.sorted.bam",
        bai = "{sample}/{sample}_metaG.reads.sorted.bam.bai"
    output:
        outdir = directory('{sample}/vamb'),
        done = '{sample}/vamb.done'
    params:
        threads = config["vamb"]["threads"],
        min_contig_length = config["binning"]["min_contig_length"]
    container: "/ibex/user/naras0c/VAMB/vamb.sif"
    benchmark: os.path.join("{sample}/benchmarks/vamb.txt")
    log: os.path.join("{sample}/logs/vamb.txt")
    shell:
        """
        rm -rf {output.outdir}

        vamb --outdir {output.outdir} \
        -p {params.threads} \
        --minfasta 10 \
        --fasta {input.fasta} \
        --bamfiles {input.bam} \
        -i 10 \
        -m {params.min_contig_length}

        touch {output.done}
        """

rule vamb_contig_to_bin:
    input:
        bin_dir = "{sample}/vamb"
    output:
        contig_to_bin="{sample}/vamb/contig_to_bin.tsv",
    shadow: "shallow"
    shell:
        """
        ls {input.bin_dir}/bins/*.fna | \
        xargs -I{{}} bash -c 'paste <(yes "{{}}" | \
        head -n $(grep -c "^>" {{}}) | \
        sed -e "s:{input.bin_dir}/bins/::g") \
        <(grep "^>" {{}} | \
        sed -e "s/>//g") <(yes "vamb" | \
        head -n $(grep -c "^>" {{}}))' | \
        sed -e 's/\.fna//g' > /tmp/tmp_file.tsv

	paste <(cut -f1 /tmp/tmp_file.tsv) \
        <(cut -f2 /tmp/tmp_file.tsv | cut -f1 -d ' ') \
        <(cut -f3 /tmp/tmp_file.tsv) > {output.contig_to_bin}
        """
