/*
 * SAMTOOLS_FLAGSTAT — alignment summary stats (mapped %, supplementary, etc.).
 *
 * Output is plain text and consumed natively by MultiQC.
 */
process SAMTOOLS_FLAGSTAT {
    tag    "${meta.id}"
    label  'process_low'

    conda     'bioconda::samtools=1.20'
    container 'quay.io/biocontainers/samtools:1.20--h50ea8bc_0'

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("*.flagstat"), emit: flagstat
    path  "versions.yml"               , emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    samtools flagstat \\
        --threads $task.cpus \\
        $bam > ${prefix}.flagstat

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$( samtools --version | head -n1 | awk '{print \$2}' )
    END_VERSIONS
    """
}
