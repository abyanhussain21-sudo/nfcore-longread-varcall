/*
 * MOSDEPTH — fast per-region depth-of-coverage.
 *
 * For long-read variant calling we care about uniformity of HiFi
 * coverage across the target region (here MHC). Mosdepth's per-base
 * output is huge for a mammalian genome, so we use --no-per-base and
 * bin to 1 kb windows (ext.args in modules.config).
 *
 * MultiQC has a dedicated mosdepth module so the .summary.txt and
 * .regions.bed.gz outputs both feed the report.
 */
process MOSDEPTH {
    tag    "${meta.id}"
    label  'process_medium'

    conda     'bioconda::mosdepth=0.3.8'
    container 'quay.io/biocontainers/mosdepth:0.3.8--hd299d5a_0'

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("*.global.dist.txt") , emit: global_dist
    tuple val(meta), path("*.summary.txt")     , emit: summary
    tuple val(meta), path("*.regions.bed.gz")  , optional:true, emit: regions
    tuple val(meta), path("*.regions.bed.gz.csi"), optional:true, emit: regions_csi
    path  "versions.yml"                       , emit: versions

    script:
    def args = task.ext.args ?: '--no-per-base --by 1000'
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mosdepth \\
        $args \\
        --threads $task.cpus \\
        $prefix \\
        $bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mosdepth: \$( mosdepth --version | sed 's/^mosdepth //' )
    END_VERSIONS
    """
}
