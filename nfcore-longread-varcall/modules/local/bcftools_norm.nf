/*
 * BCFTOOLS_NORM — normalise a VCF.
 *
 * Normalisation matters because:
 *   - DeepVariant emits multi-allelic records; downstream tools often
 *     expect biallelic split-out form.
 *   - left-aligning indels is a prerequisite for any reproducible
 *     allele-frequency or annotation work.
 *
 * The meta map carries `vartype` ('snv'|'sv') so the same module is
 * reused for both DeepVariant and Sniffles2 outputs and the publishDir
 * rule in modules.config can route them correctly.
 */
process BCFTOOLS_NORM {
    tag    "${meta.id}.${meta.vartype}"
    label  'process_low'

    conda     'bioconda::bcftools=1.20'
    container 'quay.io/biocontainers/bcftools:1.20--h8b25389_0'

    input:
    tuple val(meta), path(vcf), path(tbi)
    tuple val(meta2), path(reference), path(fai)

    output:
    tuple val(meta), path("*.vcf.gz")    , emit: vcf
    tuple val(meta), path("*.vcf.gz.tbi"), emit: tbi
    path  "versions.yml"                 , emit: versions

    script:
    def args = task.ext.args ?: '--multiallelics -any --output-type z'
    def prefix = task.ext.prefix ?: "${meta.id}.${meta.vartype}.norm"
    """
    bcftools norm \\
        $args \\
        --fasta-ref $reference \\
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
