rule bedtools_gene_coverage:
    input:
        bed = lambda wildcards: config["catalogues"][wildcards.catalogue]["bed"],
        bam = '{catalogue}/alignments/{omics}/{sample}.{omics}.reads.sorted.bam',
    output:
        "{catalogue}/gene_coverage/{omics}/{sample}_{omics}.tsv"
    threads: 8
    conda: "../../envs/bedtools_env.yml"
    benchmark: "{catalogue}/gene_coverage/benchmarks/{omics}_{sample}.txt"
    log: "{catalogue}/gene_coverage/logs/{omics}_{sample}.log"
    shell:
        """
        mkdir -p {wildcards.catalogue}/gene_coverage/{wildcards.omics}

        bedtools coverage -a {input.bed} -b {input.bam} > {output}
        """

#        | awk 'BEGIN {{
#            OFS="\\t";
#            print "contig", "start", "end", "gene", "strand", "read_count", "covered_bases", "length", "mean_coverage"
#        }}
#        {{
#            len = $3 - $2;
#            print $1, $2, $3, $4, $6, $7, $8, len, $8 / len
#        }}' > {output}
