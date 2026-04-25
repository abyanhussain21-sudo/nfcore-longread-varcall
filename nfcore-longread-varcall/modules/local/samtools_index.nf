/*
 * SAMTOOLS_INDEX — write a .bai for a sorted BAM.
 *
 * Required by DeepVariant, Sniffles2, mosdepth, and basically every
 * downstream tool that does random-access lookups. Cheap; runs in process_low.
 */
process SAMTOOLS_INDEX {
    tag    "${meta.id}"
    label  'process_low'

    conda     'bioconda::samtools=1.20'
    container 'quay.io/biocontainers/samtools:1.20--h50ea8bc_0'

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.bai"), emit: bai
    path  "versions.yml"          , emit: versions

    script:
    """
    samtools index -@ $task.cpus $bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$( samtools --version | head -n1 | awk '{print \$2}' )
    END_VERSIONS
    """
}
