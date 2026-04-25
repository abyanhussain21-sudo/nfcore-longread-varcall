# Usage

## Quick start

```bash
nextflow run abyanhussain21-sudo/nfcore-longread-varcall \
    --input samplesheet.csv \
    --reference /path/to/reference.fa \
    --outdir results \
    -profile docker
```

## Samplesheet

A comma-separated CSV with three required columns:

| Column | Description |
|--------|-------------|
| `sample_id` | Unique identifier. Must match `[A-Za-z0-9._-]+`. |
| `fastq` | Path to a PacBio HiFi FASTQ. `.fastq`, `.fq`, `.fastq.gz`, `.fq.gz` accepted. |
| `reference` | Path to the reference FASTA the sample should be aligned against. `.fa`, `.fasta`, optionally gzipped. |

Example:

```csv
sample_id,fastq,reference
CHILL_BULL_01,data/chill_bull_01.hifi.fastq.gz,reference/btau_arsucd1.2.fa
CHILL_BULL_02,data/chill_bull_02.hifi.fastq.gz,reference/btau_arsucd1.2.fa
```

Paths can be absolute or relative to the launch directory. Relative paths in the samplesheet are resolved against `projectDir` by `bin/check_samplesheet.py`.

## Profiles

Compose profiles with a comma. The first profile picks compute-environment behaviour; the second picks the container backend.

| Profile | Purpose |
|---------|---------|
| `test` | Tiny synthetic dataset, full pipeline in <5 min. |
| `test_full` | Full-size cloud test (placeholder). |
| `docker` | Run every process in the appropriate container via Docker. |
| `singularity` | Same, via Singularity. |
| `conda` | Fallback when containers aren't available. See "Conda profile caveats on macOS" below. |
| `debug` | Verbose logging, no work-dir cleanup. |

Recommended combinations:

```bash
# Smoke test on a laptop with Docker
nextflow run . -profile test,docker

# Real run on an HPC node with Singularity
nextflow run . --input samplesheet.csv --reference ref.fa -profile singularity

# Real run on a workstation with Docker
nextflow run . --input samplesheet.csv --reference ref.fa -profile docker
```

## Stage toggles

| Flag | Behaviour |
|------|-----------|
| `--skip_snv` | Skip DeepVariant. |
| `--skip_sv` | Skip Sniffles2. |
| `--skip_qc` | Skip FastQC + NanoPlot. |
| `--skip_multiqc` | Skip the final MultiQC report. |

## Filtering thresholds

| Param | Default | Effect |
|-------|---------|--------|
| `--min_qual` | 20 | Minimum QUAL retained by `bcftools filter`. |
| `--min_dp` | 10 | Minimum INFO/DP retained. |

## Resource caps

| Param | Default |
|-------|---------|
| `--max_cpus` | 16 |
| `--max_memory` | `64.GB` |
| `--max_time` | `24.h` |

These are clamps, not requests — the `check_max()` helper in `nextflow.config` ensures no single process asks for more than these limits.

## Resume

Nextflow caches every process. If a run fails or is interrupted:

```bash
nextflow run . -resume
```

Successful tasks are skipped; only failed/missing ones rerun.

## Conda profile caveats on macOS

The canonical execution paths for this pipeline are `-profile docker` and `-profile singularity`. On Linux + Docker (which is what CI runs on every push), the full pipeline including DeepVariant and Sniffles2 runs to completion.

`-profile conda` works on macOS for the QC, alignment, and reporting stages but has three known limitations that have nothing to do with the pipeline code:

1. **DeepVariant** — there is no working bioconda recipe for macOS; DeepVariant only ships as a Docker image with bundled model checkpoints. Use `--skip_snv` if you must run conda on macOS, or switch to `-profile docker`.
2. **Sniffles2** — the bioconda build hits a `TypeError: cannot pickle '_thread.RLock'` on macOS due to an upstream multiprocessing issue. The same recipe runs fine on Linux (which is what CI uses). Use `--skip_sv` to bypass on macOS conda, or use `-profile docker`.
3. **NanoPlot** — the bioconda recipe currently resolves a Python 3.14 environment that is incompatible with `kaleido`'s plotly scope import. Use `--skip_qc` to bypass on macOS conda, or use `-profile docker`. (FastQC is unaffected, so this only impacts NanoPlot's HiFi-specific QC.)

These are upstream packaging issues, not pipeline bugs. They do not affect Linux runs or container-based runs on any OS. The CI workflow at `.github/workflows/ci.yml` runs the full pipeline including all three stages on Linux + Docker on every push, which is the canonical proof that the pipeline works.

## Outputs

See [output.md](output.md) for the directory layout and what each file contains.
