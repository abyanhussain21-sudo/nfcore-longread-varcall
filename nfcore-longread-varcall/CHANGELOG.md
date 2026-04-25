# Changelog

All notable changes to `nfcore-longread-varcall` are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] — 2026-04-26

Initial public release.

### Added

- Nextflow DSL2 pipeline for variant calling from PacBio HiFi long reads.
- Subworkflows: `INPUT_CHECK`, `QC`, `ALIGNMENT`, `VARIANT_CALLING`, `REPORTING`.
- Modules: `nanoplot`, `fastqc`, `minimap2_align`, `samtools_sort`, `samtools_index`, `samtools_flagstat`, `mosdepth`, `deepvariant`, `sniffles`, `bcftools_norm`, `bcftools_filter`, `bcftools_stats`, `multiqc`.
- Profiles: `test`, `test_full`, `docker`, `singularity`, `conda`, `debug`.
- `nf-schema`-validated parameter schema (`nextflow_schema.json`).
- Synthetic test fixture: 100 kb reference, 1,000 simulated HiFi reads, 5 planted SNVs + one 500 bp deletion + one 50 bp insertion. Truth manifest (`PLANTED_VARIANTS.tsv`) matches the FASTA byte-for-byte.
- Python samplesheet validator (`bin/check_samplesheet.py`) with friendly error messages.
- GitHub Actions CI: nf-core lint + end-to-end test-profile run on push and pull request.
- Docs: `docs/usage.md`, `docs/output.md`, `docs/parameters.md`.
- Stage toggles: `--skip_snv`, `--skip_sv`, `--skip_qc`, `--skip_multiqc`.

### Verified locally

- `nextflow run . -profile test,conda --skip_snv --skip_sv --skip_qc` completes end-to-end on macOS with INPUT_CHECK, FAIDX, MINIMAP2_ALIGN, SAMTOOLS_SORT/INDEX/FLAGSTAT, MOSDEPTH, and MULTIQC producing the expected outputs.
- The full pipeline (including DeepVariant, Sniffles2, and NanoPlot) is exercised on every push by CI on Linux + Docker — see `.github/workflows/ci.yml`.

### Known limitations

- Test fixture is a smoke test, not a recall benchmark. Genome-in-a-Bottle benchmarking is on the roadmap.
- Pipeline is hosted on a personal GitHub account, not under the nf-core organisation. Some `nf-core lint` warnings are expected and documented in `.nf-core.yml`.
- DeepVariant container is Google's official image (the lone non-BioContainer in the pipeline) because the BioConda package ships without model checkpoints.
- `-profile conda` on macOS has three upstream packaging issues affecting DeepVariant, Sniffles2, and NanoPlot. Documented in `docs/usage.md`. None affect Linux or container-based runs.
