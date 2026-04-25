/*
 * MULTIQC — aggregate QC report.
 *
 * Consumes outputs from FastQC, NanoPlot, samtools flagstat, mosdepth,
 * bcftools stats, and Sniffles2 in a single HTML report. Configured
 * via assets/multiqc_config.yml.
 */
process MULTIQC {
    label  'process_low'

    conda     'bioconda::multiqc=1.23'
    container 'quay.io/biocontainers/multiqc:1.23--pyhdfd78af_0'

    input:
    path  multiqc_files, stageAs: "?/*"
    path(multiqc_config)

    output:
    path "*multiqc_report.html"        , emit: report
    path "*_data"                      , emit: data
    path "*_plots"     , optional:true , emit: plots
    path "versions.yml"                , emit: versions

    script:
    def args = task.ext.args ?: ''
    def config = multiqc_config ? "--config $multiqc_config" : ''
    """
    multiqc \\
        --force \\
        $config \\
        $args \\
        .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: \$( multiqc --version | sed 's/^multiqc, version //' )
    END_VERSIONS
    """
}
