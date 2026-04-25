# Parameters

Authoritative source: [`nextflow_schema.json`](../nextflow_schema.json). This page is a human-readable summary; the JSON schema is what `nf-schema` actually validates against.

To regenerate this page from the schema:

```bash
nf-core schema docs --output docs/parameters.md
```

## Input / output

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `--input` | path | _required_ | Path to samplesheet CSV (`sample_id,fastq,reference`). |
| `--outdir` | path | `./results` | Where results are written. |
| `--reference` | path | `null` | Optional global reference FASTA. Per-sample references in the samplesheet take precedence. |
| `--publish_dir_mode` | enum | `copy` | One of `symlink`, `rellink`, `link`, `copy`, `copyNoFollow`, `move`. |

## Stage toggles

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `--skip_snv` | bool | `false` | Skip DeepVariant. |
| `--skip_sv` | bool | `false` | Skip Sniffles2. |
| `--skip_qc` | bool | `false` | Skip FastQC + NanoPlot. |
| `--skip_multiqc` | bool | `false` | Skip the final MultiQC report. |

## Variant filtering

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `--min_qual` | int | `20` | Minimum QUAL retained by `bcftools filter`. |
| `--min_dp` | int | `10` | Minimum INFO/DP retained. |

## DeepVariant

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `--deepvariant_model_type` | enum | `PACBIO` | One of `PACBIO`, `WGS`, `WES`, `ONT_R104`, `HYBRID_PACBIO_ILLUMINA`. |

## Resource caps

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `--max_cpus` | int | `16` | Maximum CPUs requested by any single process. |
| `--max_memory` | string | `64.GB` | Maximum memory. |
| `--max_time` | string | `24.h` | Maximum wall-time. |

## MultiQC

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `--multiqc_config` | path | `assets/multiqc_config.yml` | Custom MultiQC YAML. |
| `--multiqc_title` | string | `null` | Custom MultiQC report title. |

## Generic

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `--help` | bool | `false` | Print the help message and exit. |
| `--version` | bool | `false` | Print the version and exit. |
| `--validate_params` | bool | `true` | Run `nf-schema` parameter validation at launch. |
| `--monochrome_logs` | bool | `false` | Disable ANSI colours in logs. |
