rule magscot_contig_to_bin:
    input:
        contig_to_bin_concoct="{sample}/concoct/contig_to_bin.tsv",
        contig_to_bin_maxbin2="{sample}/maxbin2/contig_to_bin.tsv",
        contig_to_bin_metabat2="{sample}/metabat2/contig_to_bin.tsv",
        contig_to_bin_semibin="{sample}/semibin/contig_to_bin.tsv",
        contig_to_bin_vamb="{sample}/vamb/contig_to_bin.tsv",
        contig_to_bin_semibin_multi="semibin_multi_sample/contigs_to_bins/{sample}_contig_to_bin.tsv"
    output:
        contig_to_bin="{sample}/contig_to_bin.tsv",
    shadow: "shallow"
    shell:
       """
       cat {input} > {output.contig_to_bin} 
       """
