SAMPLE = [line.strip() for line in open("sample.txt")]

rule all:
    input:
        "SRR26841613/SRR2641613.sra",
        "SRR26841613_1.fastq",
        "SRR26841613_2.fastq",
        "SRR26841613_1_fastqc.html",
        "SRR26841613_1_fastqc.zip",
        "SRR26841613_2_fastqc.html",
        "SRR26841613_2_fastqc.zip",
        "SRR26841613_1_val_1.fq",
        "SRR26841613_2_val_2.fq",
        "SRR26841613_1_val_1.html",
        "SRR26841613_1_val_1.zip",
        "SRR26841613_2_val_2.html",
        "SRR26841613_2_val_2.zip",
        "spades/contigs.fasta",
        "quast_assembly/report.html",
        "annotation/cds.fna",
        "annotation/protein.faa",
        "annotation/genome.gbk",
        "annotation/rna.fna",
        "annotation/pseudogene_summary.tsv",
        "abricate_resfinder.tab",
        "abricate_vfdb.tab",
        "abricate_ncbi.tab",
        "abricate_summary.tab",
        "mp1_db.nsq",
        "self_blast.txt"

rule sra_download:
    input:
        SAMPLE
    output:
        "SRR26841613/SRR2641613.sra"
    shell:
        "prefetch SRR26841613"

rule sra2fq:
    input: 
        "SRR26841613/SRR26841613.sra"
    output:
        "SRR26841613_1.fastq",
        "SRR26841613_2.fastq"
    shell:
        "fasterq-dump {input} --split-files"

rule pri_qc:
    input:
        "SRR26841613_1.fastq",
        "SRR26841613_2.fastq"
    output:
        "SRR26841613_1_fastqc.html",
        "SRR26841613_1_fastqc.zip",
        "SRR26841613_2_fastqc.html",
        "SRR26841613_2_fastqc.zip"
    shell:
        "fastqc {input} -o ."

rule trimming:
    input:
        "SRR26841613_1.fastq",
        "SRR26841613_2.fastq"
    output:
        "SRR26841613_1_val_1.fq",
        "SRR26841613_2_val_2.fq"
    shell:
        "trim_galore --paired -j 4 {input[0]} {input[1]}"

rule fin_qc:
    input:
        "SRR26841613_1_val_1.fq",
        "SRR26841613_2_val_2.fq"
    output:
        "SRR26841613_1_val_1.html",
        "SRR26841613_1_val_1.zip",
        "SRR26841613_2_val_2.html",
        "SRR26841613_2_val_2.zip"
    shell:
        "fastqc {input} -o ."

rule de_novo_assembly:
    input:
        "SRR26841613_1_val_1.fq",
        "SRR26841613_2_val_2.fq"
    output:
        "spades/contigs.fasta"
    shell:
        "spades.py -1 {input[0]} -2 {input[1]} -o spades -t 8 -m 14 --careful"

rule assembly_qc:
    input:
        "spades/contigs.fasta"
    output:
        "quast_assembly/report.html"
    shell:
        "quast.py -t -o quast_assembly {input}"

rule annotation:
    input:
        "spades/contigs.fasta"
    output:
        "annotation/cds.fna",
        "annotation/protein.faa",
        "annotation/genome.gbk",
        "annotation/rna.fna",
        "annotation/pseudogene_summary.tsv"
    shell:
        "dfast --genome {input} --out annotation --organism 'Escherichia Coli MP1' --strain MP1"

rule abricate_all:
    input:
        "spades/contigs.fasta"
    output:
        resfinder="abricate_resfinder.tab",
        vfdb="abricate_vfdb.tab",
        ncbi="abricate_ncbi.tab",
        summary="abricate_summary.tab"
    shell:
        """
        abricate --db resfinder {input} > {output.resfinder}
        abricate --db vfdb {input} > {output.vfdb}
        abricate --db ncbi {input} > {output.ncbi}
        abricate --summary {output.resfinder} {output.vfdb} {output.ncbi} > {output.summary}
        """

rule blast:
    input:
        "spades/contigs.fasta"
    output:
        "mp1_db.nsq"
    shell:
        "makeblastdb -in {input} --dbtype nucl -out mp1_db"

rule blast_hits:
    input:
        cds="annotation/cds.fnn",
        db="mp1_db"
    output:
        "self_blast.txt"
    shell:
        "blastn -query {input} -db {db} -output {output} -max_target_Seqs 10 -outfmt 6"


    
        
        
