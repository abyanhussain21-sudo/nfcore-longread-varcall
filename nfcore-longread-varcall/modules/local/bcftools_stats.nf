/*
 * BCFTOOLS_STATS — summary statistics for a VCF.
 *
 * Output is a `*.stats.txt` consumed natively by MultiQC.
 */
process BCFTOOLS_STATS {
    tag    "${meta.id}.${meta.vartype}"
    label  'process_low'

    conda     'bioconda::bcftools=1.20'
    container 'quay.io/biocontainers/bcftools:1.20--h8b25389_0'

    input:
    tuple val(meta), path(vcf), path(tbi)

    output:
    tuple val(meta), path("*.stats.txt"), emit: stats
    path  "versions.yml"                , emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}.${meta.vartype}"
    """
    bcftools stats --threads $task.cpus $vcf > ${prefix}.stats.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$( bcftools --version | head -n1 | sed 's/^bcftools //' )
    END_VERSIONS
    """
}
