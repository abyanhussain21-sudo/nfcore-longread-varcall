/*
 * BCFTOOLS_FILTER — quality threshold filter.
 *
 * Drops records below `params.min_qual` QUAL or `params.min_dp` INFO/DP.
 * The actual filter expression is built from those params in
 * conf/modules.config so users can override on the CLI without forking
 * the module. This is the nf-core idiom for tunable filters.
 */
process BCFTOOLS_FILTER {
    tag    "${meta.id}.${meta.vartype}"
    label  'process_low'

    conda     'bioconda::bcftools=1.20'
    container 'quay.io/biocontainers/bcftools:1.20--h8b25389_0'

    input:
    tuple val(meta), path(vcf), path(tbi)

    output:
    tuple val(meta), path("*.vcf.gz")    , emit: vcf
    tuple val(meta), path("*.vcf.gz.tbi"), emit: tbi
    path  "versions.yml"                 , emit: versions

    script:
    def args = task.ext.args ?: "--include 'QUAL>=${params.min_qual} && INFO/DP>=${params.min_dp}' --output-type z"
    def prefix = task.ext.prefix ?: "${meta.id}.${meta.vartype}.filtered"
    """
    bcftools filter \\
        $args \\
        --threads $task.cpus \\
        --output ${prefix}.vcf.gz \\
        $vcf

    bcftools index --tbi --threads $task.cpus ${prefix}.vcf.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$( bcftools --version | head -n1 | sed 's/^bcftools //' )
    END_VERSIONS
    """
}
