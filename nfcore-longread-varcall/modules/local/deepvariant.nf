/*
 * DEEPVARIANT — small-variant calling with the PACBIO model.
 *
 * NOTE on container choice:
 *   Every other module in this pipeline uses a Quay.io BioContainer.
 *   DeepVariant is the lone exception: it ships only as Google's own
 *   `google/deepvariant` Docker image, with bundled model checkpoints
 *   (the BioConda package omits the models). nf-core/sarek does the same.
 *   This is documented in CITATIONS.md and in the README's caveats.
 *
 * model_type=PACBIO is mandatory for HiFi reads — the WGS model is
 * trained on Illumina and produces dramatically worse calls on HiFi.
 */
process DEEPVARIANT {
    tag    "${meta.id}"
    label  'process_high'

    // No conda recipe — DeepVariant ships only as a Docker image. Running
    // -profile conda will fail this process; use -profile docker or
    // -profile singularity, or pass --skip_snv on the test run.
    conda     'bioconda::deepvariant=1.6.1'
    container 'docker.io/google/deepvariant:1.6.1'

    input:
    tuple val(meta), path(bam), path(bai)
    tuple val(meta2), path(reference), path(fai)

    output:
    tuple val(meta), path("*.vcf.gz")       , emit: vcf
    tuple val(meta), path("*.vcf.gz.tbi")   , emit: tbi
    tuple val(meta), path("*.g.vcf.gz")     , optional:true, emit: gvcf
    tuple val(meta), path("*.html")         , optional:true, emit: report
    path  "versions.yml"                    , emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def model  = params.deepvariant_model_type ?: 'PACBIO'
    """
    /opt/deepvariant/bin/run_deepvariant \\
        --model_type=${model} \\
        --ref=${reference} \\
        --reads=${bam} \\
        --output_vcf=${prefix}.deepvariant.vcf.gz \\
        --output_gvcf=${prefix}.deepvariant.g.vcf.gz \\
        --num_shards=${task.cpus} \\
        --intermediate_results_dir=tmp

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        deepvariant: \$( /opt/deepvariant/bin/run_deepvariant --version 2>&1 | sed 's/^.*version //; s/ .*\$//' )
    END_VERSIONS
    """
}
