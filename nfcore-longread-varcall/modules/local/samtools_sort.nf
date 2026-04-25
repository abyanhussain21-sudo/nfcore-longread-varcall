/*
 * SAMTOOLS_SORT — coordinate-sort a BAM.
 *
 * Split out from MINIMAP2_ALIGN because:
 *   (1) restart granularity — re-running sort doesn't re-run alignment
 *   (2) makes it trivial to swap minimap2 for another aligner later
 *   (3) matches nf-core/modules layout one-to-one
 */
process SAMTOOLS_SORT {
    tag    "${meta.id}"
    label  'process_medium'

    conda     'bioconda::samtools=1.20'
    container 'quay.io/biocontainers/samtools:1.20--h50ea8bc_0'

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.sorted.bam"), emit: bam
    path  "versions.yml"                 , emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}.sorted"
    """
    samtools sort \\
        -@ $task.cpus \\
        -o ${prefix}.bam \\
        -T ${prefix} \\
        $bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$( samtools --version | head -n1 | awk '{print \$2}' )
    END_VERSIONS
    """
}
