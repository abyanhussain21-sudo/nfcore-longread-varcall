#!/usr/bin/env python3
"""
check_samplesheet.py — validate the nfcore-longread-varcall samplesheet.

The samplesheet is a CSV with header `sample_id,fastq,reference`. This
script checks:

  1. Header is exactly `sample_id,fastq,reference` (whitespace tolerant).
  2. `sample_id` values are unique and contain only [A-Za-z0-9._-].
  3. `fastq` paths exist, are readable, and end in `.fastq` / `.fastq.gz`
     / `.fq` / `.fq.gz`.
  4. `reference` paths exist, are readable, and end in `.fa` / `.fasta`
     / `.fa.gz` / `.fasta.gz`.

On success it writes a normalised copy to `--output` (CRLF stripped,
trailing whitespace trimmed). On failure it exits with status 1 and a
specific error message — no traceback for end users.

This is the same pattern nf-core uses (see nf-core/sarek/bin/check_samplesheet.py)
and means we surface "row 4: fastq file not found" instead of a Python
KeyError 200 frames deep into Nextflow.
"""

from __future__ import annotations

import argparse
import csv
import re
import sys
from pathlib import Path

EXPECTED_HEADER = ["sample_id", "fastq", "reference"]
SAMPLE_ID_RE = re.compile(r"^[A-Za-z0-9._-]+$")
FASTQ_SUFFIXES = (".fastq", ".fastq.gz", ".fq", ".fq.gz")
FASTA_SUFFIXES = (".fa", ".fasta", ".fa.gz", ".fasta.gz")


def die(msg: str) -> None:
    print(f"[check_samplesheet.py] ERROR: {msg}", file=sys.stderr)
    sys.exit(1)


def has_suffix(p: str, suffixes: tuple[str, ...]) -> bool:
    p_lower = p.lower()
    return any(p_lower.endswith(s) for s in suffixes)


def parse_args() -> argparse.Namespace:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--input", required=True, type=Path, help="Path to samplesheet CSV.")
    ap.add_argument("--output", required=True, type=Path, help="Where to write the validated CSV.")
    ap.add_argument(
        "--basedir",
        type=Path,
        default=Path.cwd(),
        help="Base directory used to resolve relative file paths in the samplesheet."
        " Defaults to the current working directory.",
    )
    return ap.parse_args()


def resolve(p: str, basedir: Path) -> Path:
    """Resolve a path string against basedir if it isn't absolute."""
    pp = Path(p)
    return pp if pp.is_absolute() else (basedir / pp)


def validate(in_path: Path, out_path: Path, basedir: Path) -> None:
    if not in_path.is_file():
        die(f"samplesheet not found: {in_path}")

    with in_path.open(newline="") as fh:
        reader = csv.reader(fh)
        try:
            header = [c.strip() for c in next(reader)]
        except StopIteration:
            die("samplesheet is empty")

        if header != EXPECTED_HEADER:
            die(
                f"header must be {','.join(EXPECTED_HEADER)} — got {','.join(header)}"
            )

        rows = []
        seen_ids: set[str] = set()
        for lineno, raw in enumerate(reader, start=2):
            if not raw or all(not c.strip() for c in raw):
                continue  # skip blank lines

            if len(raw) != len(EXPECTED_HEADER):
                die(f"row {lineno}: expected {len(EXPECTED_HEADER)} columns, got {len(raw)}")

            sample_id, fastq, reference = (c.strip() for c in raw)

            if not SAMPLE_ID_RE.match(sample_id):
                die(
                    f"row {lineno}: sample_id '{sample_id}' must match {SAMPLE_ID_RE.pattern}"
                )
            if sample_id in seen_ids:
                die(f"row {lineno}: duplicate sample_id '{sample_id}'")
            seen_ids.add(sample_id)

            if not has_suffix(fastq, FASTQ_SUFFIXES):
                die(f"row {lineno}: fastq '{fastq}' must end in one of {FASTQ_SUFFIXES}")
            fastq_resolved = resolve(fastq, basedir)
            if not fastq_resolved.is_file():
                die(f"row {lineno}: fastq file not found: {fastq_resolved}")

            if not has_suffix(reference, FASTA_SUFFIXES):
                die(
                    f"row {lineno}: reference '{reference}' must end in one of {FASTA_SUFFIXES}"
                )
            ref_resolved = resolve(reference, basedir)
            if not ref_resolved.is_file():
                die(f"row {lineno}: reference file not found: {ref_resolved}")

            # Re-emit absolute paths in the validated CSV so downstream
            # Nextflow `file()` calls don't have to re-resolve.
            rows.append([sample_id, str(fastq_resolved.resolve()), str(ref_resolved.resolve())])

        if not rows:
            die("samplesheet has a header but no data rows")

    with out_path.open("w", newline="") as fh:
        writer = csv.writer(fh)
        writer.writerow(EXPECTED_HEADER)
        writer.writerows(rows)

    print(
        f"[check_samplesheet.py] OK: validated {len(rows)} sample(s) -> {out_path}",
        file=sys.stderr,
    )


def main() -> None:
    args = parse_args()
    validate(args.input, args.output, args.basedir)


if __name__ == "__main__":
    main()
