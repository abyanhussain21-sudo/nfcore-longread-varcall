/*
 * NANOPLOT — read-length / quality QC for long reads.
 *
 * NanoPlot is the canonical QC tool for ONT/PacBio reads. It produces a
 * stats text file plus PNG/HTML plots that MultiQC can consume directly.
 *
 * Inputs : tuple (meta, FASTQ)
 * Outputs: tuple (meta, NanoStats.txt) + arbitrary plot files
 */
process NANOPLOT {
    tag    "${meta.id}"
    label  'process_low'

    conda     'bioconda::nanoplot=1.42.0'
    container 'quay.io/biocontainers/nanoplot:1.42.0--pyhdfd78af_0'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.html")                , emit: html
    tuple val(meta), path("*.png")    , optional:true, emit: png
    tuple val(meta), path("*.txt")                 , emit: txt
    tuple val(meta), path("*.log")    , optional:true, emit: log
    path  "versions.yml"                           , emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    NanoPlot \\
        $args \\
        --threads $task.cpus \\
        --fastq $reads \\
        --prefix ${meta.id}.

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nanoplot: \$(NanoPlot --version 2>&1 | sed 's/^.*NanoPlot //; s/ .*\$//')
    END_VERSIONS
    """
}
