/*
 * SNIFFLES — structural-variant calling for long reads.
 *
 * Sniffles2 is the de-facto SV caller for HiFi/ONT. It writes a VCF
 * of insertions, deletions, inversions, duplications, and translocations.
 * --reference is required for INS sequence reconstruction in modern
 * Sniffles2 builds.
 */
process SNIFFLES {
    tag    "${meta.id}"
    label  'process_medium'

    conda     'bioconda::sniffles=2.4 bioconda::tabix=1.11'
    container 'quay.io/biocontainers/sniffles:2.4--pyhdfd78af_0'

    input:
    tuple val(meta), path(bam), path(bai)
    tuple val(meta2), path(reference), path(fai)

    output:
    tuple val(meta), path("*.vcf.gz")    , emit: vcf
    tuple val(meta), path("*.vcf.gz.tbi"), emit: tbi
    tuple val(meta), path("*.snf")       , optional:true, emit: snf
    path  "versions.yml"                 , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    sniffles \\
        $args \\
        --threads $task.cpus \\
        --reference $reference \\
        --input $bam \\
        --vcf ${prefix}.sniffles.vcf.gz \\
        --snf ${prefix}.sniffles.snf

    # Sniffles writes a .vcf.gz that may not be tabix-indexed yet.
    if [ ! -f ${prefix}.sniffles.vcf.gz.tbi ]; then
        tabix -p vcf ${prefix}.sniffles.vcf.gz
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sniffles: \$( sniffles --version 2>&1 | sed 's/^.*Version //; s/ .*\$//' )
    END_VERSIONS
    """
}
