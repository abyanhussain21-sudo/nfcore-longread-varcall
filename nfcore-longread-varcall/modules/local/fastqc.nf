/*
 * FASTQC — generic per-base/per-read QC.
 *
 * Less informative for HiFi than NanoPlot (FastQC's adapter checks were
 * built for short reads), but still useful for a sanity check of base
 * quality distributions, and MultiQC consumes FastQC reports natively.
 *
 * Inputs : tuple (meta, FASTQ)
 * Outputs: tuple (meta, fastqc.zip + fastqc.html)
 */
process FASTQC {
    tag    "${meta.id}"
    label  'process_low'

    conda     'bioconda::fastqc=0.12.1'
    container 'quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.html"), emit: html
    tuple val(meta), path("*.zip") , emit: zip
    path  "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    // Rename the fastq so the FastQC report keeps the sample id rather
    // than a UUID-flavoured staged filename — purely cosmetic but it
    // makes the MultiQC report readable.
    def renamed = "${meta.id}.fastq.gz"
    """
    [ -f $renamed ] || ln -sf $reads $renamed

    fastqc \\
        $args \\
        --threads $task.cpus \\
        $renamed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastqc: \$( fastqc --version | sed 's/^FastQC v//' )
    END_VERSIONS
    """
}
