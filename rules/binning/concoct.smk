rule concoct_cut_contigs:
    input:
        fasta = "{sample}/all_prokaryotic_seqs.fa",
        bam = "{sample}/{sample}_metaG.reads.sorted.bam",
        bai = "{sample}/{sample}_metaG.reads.sorted.bam.bai"
    output:
        split_contigs_fasta = "{sample}/concoct/split_contigs_len-%s.fa" % config["concoct"]["contig_split_length"],
        split_contigs_bed = "{sample}/concoct/split_contigs_len-%s.bed" % config["concoct"]["contig_split_length"]
    params:
        contig_split_length = config["concoct"]["contig_split_length"]
    conda: "../../envs/concoct_env.yml"
    shadow: "shallow"
    benchmark: os.path.join("{sample}/benchmarks/concoct_cut_contigs.txt")
    log: os.path.join("{sample}/logs/concoct_cut_contigs.txt")
    shell:
        """
        cut_up_fasta.py {input.fasta} -c {params.contig_split_length} -o 0 --merge_last -b {output.split_contigs_bed} > {output.split_contigs_fasta}
        """

rule concoct_coverage_table:
    input:
        split_contigs_bed = "{sample}/concoct/split_contigs_len-%s.bed" % config["concoct"]["contig_split_length"],
        bam = "{sample}/{sample}_metaG.reads.sorted.bam",
        bai = "{sample}/{sample}_metaG.reads.sorted.bam.bai"
    output:
        coverage_table = "{sample}/concoct/split_contigs_len-%s_coverage_table.tsv" % config["concoct"]["contig_split_length"]
    params:
        contig_split_length = config["concoct"]["contig_split_length"]
    conda: "../../envs/concoct_env.yml"
    shadow: "shallow"
    benchmark: os.path.join("{sample}/benchmarks/concoct_coverage_table.txt")
    log: os.path.join("{sample}/logs/concoct_coverage_table.txt")
    shell:
        """
        concoct_coverage_table.py {input.split_contigs_bed} {input.bam} > {output.coverage_table}
        """

rule concoct:
    input:
        split_contigs_fasta = "{sample}/concoct/split_contigs_len-%s.fa" % config["concoct"]["contig_split_length"],
        coverage_table = "{sample}/concoct/split_contigs_len-%s_coverage_table.tsv" % config["concoct"]["contig_split_length"]
    output:
        clustering_result = "{sample}/concoct/results_clustering_gt%s.csv" % config["binning"]["min_contig_length"]
    params:
        threads = config["concoct"]["threads"],
        contig_min_length = config["binning"]["min_contig_length"]
    conda: "../../envs/concoct_env.yml"
    shadow: "shallow"
    benchmark: os.path.join("{sample}/benchmarks/concoct.txt")
    log: os.path.join("{sample}/logs/concoct.txt")
    shell:
        """
        concoct --composition_file {input.split_contigs_fasta} -l {params.contig_min_length} \
        --coverage_file {input.coverage_table} -t {params.threads} -b {wildcards.sample}/concoct/results
        """
        #--coverage_file {input.coverage_table} -t {params.threads} -b {wildcards.sample}/concoct/results

rule concoct_merge_clusters:
    input:
        clustering_result = "{sample}/concoct/results_clustering_gt%s.csv" % config["binning"]["min_contig_length"],
	fasta = "{sample}/all_prokaryotic_seqs.fa"
    output:
        merged_table = "{sample}/concoct/bins/clustering_merged.csv",
        bin_dir = directory("{sample}/concoct/bins")
    conda: "../../envs/concoct_env.yml"
    shadow: "shallow"
    benchmark: os.path.join("{sample}/benchmarks/concoct_merge_clusters.txt")
    log: os.path.join("{sample}/logs/concoct_merge_clusters.txt")
    shell:
        """
        merge_cutup_clustering.py {input.clustering_result} > {output.merged_table}
        mkdir -p {output.bin_dir}
        extract_fasta_bins.py {input.fasta} {output.merged_table} --output_path {output.bin_dir}
        """

rule concoct_contig_to_bin:
    input:
        merged_table = "{sample}/concoct/bins/clustering_merged.csv",
    output:
        contig_to_bin="{sample}/concoct/contig_to_bin.tsv",
    shadow: "shallow"
    shell:
        """
        paste <(cat {input.merged_table} | cut -f2 -d ',') \
        <(cat {input.merged_table} | cut -f1 -d ',') | \
        awk '{{print $0 "\tconcoct"}}' | tail -n +2 |  sort > {output.contig_to_bin}
        """
