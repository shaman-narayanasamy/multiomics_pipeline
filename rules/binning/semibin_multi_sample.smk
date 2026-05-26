## Semibin needs to have each fasta file with a unique name regardless of its location
rule soft_link_unique:
    input:
        fasta = "{sample}/all_prokaryotic_seqs.fa"
    output:
        fasta = '{sample}/{sample}.fa',
    shell:
        """ 
        ln -s all_prokaryotic_seqs.fa {output.fasta}
        """

rule semibin_multi_sample_concatenate_contigs:
    input:
        expand("{sample}/{sample}.fa", sample = samples.index)
    output:
        fasta = 'semibin_multi_sample/concatenated.fa',
    params:
        outdir = 'semibin_multi_sample'
    conda: "../../envs/semibin2_env.yml"
    benchmark: "semibin_multi_sample/benchmarks/concatenate_contigs.txt"
    log: "semibin_multi_sample/logs/concatenate_contigs.txt"
    shell:
        """ 
        SemiBin2 concatenate_fasta -i {input} -o {params.outdir} \
        --compression none
        """

rule semibin_multi_sample_split_contigs:
    input:
        fasta = 'semibin_multi_sample/concatenated.fa',
    output:
        split_fasta_dir = directory('semibin_multi_sample/split_contigs_dir'),
    params:
        outdir = 'semibin_multi_sample'
    conda: "../../envs/semibin2_env.yml"
    benchmark: "semibin_multi_sample/benchmarks/split_contigs.txt"
    shell:
        """ 
        SemiBin2 split_contigs -i {input} -o {output}
        """

rule semibin_multi_sample_get_abundance:
    input:
        r_1=lambda wildcards: samples.at[(wildcards.sample), "R1"],
        r_2=lambda wildcards: samples.at[(wildcards.sample), "R2"],
        split_fasta_dir = 'semibin_multi_sample/split_contigs_dir',
    output:
        abundance_file = "semibin_multi_sample/abundance/sample_{sample}.txt"
    conda: "../../envs/strobealign_env.yml"
    params:
        threads = 24
    benchmark: "semibin_multi_sample/benchmarks/{sample}/get_abundance.txt"
    shell:
        """
        mkdir -p semibin_multi_sample/abundance
        
        strobealign --aemb {input.split_fasta_dir}/split_contigs.fna.gz {input.r_1} {input.r_2} -R {params.threads} > {output.abundance_file}
        """

rule semibin_multi_sample:
    input:
        fasta = 'semibin_multi_sample/concatenated.fa',
        abundance_files = expand("semibin_multi_sample/abundance/sample_{sample}.txt", sample = samples.index)
    output:
        done = 'semibin_multi_sample/binning.done'
    params:
        outdir = 'semibin_multi_sample/output',
        tmpdir = config["tmp_dir"],
        threads = config["semibin_multi_sample"]["threads"],
        min_contig_length = config["binning"]["min_contig_length"],
        abundance_dir = "semibin_multi_sample/abundance"
    conda: "../../envs/semibin2_env.yml"
    benchmark: "semibin_multi_sample/benchmarks/semibin2.txt"
    log: "semibin_multi_sample/logs/semibin2.txt"
    shell:
       """
       mkdir -p {params.outdir}
       
       SemiBin2 multi_easy_bin \
       --tmpdir {params.tmpdir} \
       --engine auto \
       -m {params.min_contig_length} \
       -i {input.fasta} \
       -a {params.abundance_dir}/*.txt \
       -o {params.outdir} \
       -t {params.threads}

       touch {output.done}
       """

rule semibin_multi_sample_contig_to_bin:
    input:
        fasta = "{sample}/all_prokaryotic_seqs.fa",
        done = 'semibin_multi_sample/binning.done'
    output:
        contig_to_bin="semibin_multi_sample/contigs_to_bins/{sample}_contig_to_bin.tsv"
    params:
        bin_dir = 'semibin_multi_sample/output'
    shell:
        """
        mkdir -p semibin_multi_sample/contigs_to_bins

        paste <(grep "^>" {params.bin_dir}/bins/{wildcards.sample}_SemiBin_*.fa | \
        sed -e 's:{params.bin_dir}/bins/::g' -e 's/\.fa:>/\t/g') \
        <(yes "semibin_multi_sample" | \
        head -n $(cat {params.bin_dir}/bins/{wildcards.sample}_SemiBin_*.fa | grep -c "^>")) > \
        {output.contig_to_bin}
        """
