# Contributing to `nfcore-longread-varcall`

Thanks for considering a contribution. This is a personal portfolio pipeline rather than an nf-core community pipeline, but the same conventions apply.

## Quick rules

1. **One process per file** under `modules/local/`.
2. Channel I/O is `tuple val(meta), path(file)` — never bare paths.
3. Resource requests live in `conf/base.config` via process labels (`process_low`, `process_medium`, `process_high`). Don't hard-code `cpus`/`memory` inside a module.
4. Tool flags live in `conf/modules.config` via `ext.args` so users can override without forking the module.
5. Pin tool versions in container directives. No `:latest`.
6. Add a top-of-file comment to every new file explaining what it does and why.
7. Update `CITATIONS.md` when you add a new tool.
8. Update `nextflow_schema.json` when you add a new parameter.

## Testing

Before opening a pull request:

```bash
# Lint
nf-core lint .

# End-to-end smoke test
nextflow run . -profile test,docker

# Format
pre-commit run --all-files
```

CI will run the same three checks on push and on pull requests against `main`.

## Reporting bugs

Open a GitHub issue. Please include:

- Nextflow version (`nextflow -version`)
- Full command line you ran
- The relevant section of `.nextflow.log`
- Whether `-profile test,docker` reproduces the issue

## Adding a new tool

1. Add a module under `modules/local/<tool>.nf` matching the conventions of the existing modules.
2. Wire it into the relevant subworkflow under `subworkflows/local/`.
3. Add a `withName: <TOOL>` block to `conf/modules.config` for `publishDir` and `ext.args`.
4. Add a row to `CITATIONS.md`.
5. Pin the container tag.
