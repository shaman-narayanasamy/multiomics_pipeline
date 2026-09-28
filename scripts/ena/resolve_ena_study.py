#!/usr/bin/env python3
"""Resolve ENA run metadata into a multiomics_pipeline sample sheet."""

from __future__ import annotations

import argparse
import csv
import sys
from pathlib import Path
from urllib.parse import urlencode
from urllib.request import urlopen


ENA_PORTAL_URL = "https://www.ebi.ac.uk/ena/portal/api/filereport"

FIELDS = [
    "run_accession",
    "sample_accession",
    "secondary_sample_accession",
    "experiment_accession",
    "study_accession",
    "secondary_study_accession",
    "sample_alias",
    "experiment_alias",
    "library_strategy",
    "library_source",
    "library_selection",
    "library_layout",
    "instrument_platform",
    "instrument_model",
    "fastq_ftp",
    "fastq_md5",
    "fastq_bytes",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("study_accession", help="ENA project or study accession.")
    parser.add_argument("output", help="Output TSV sample sheet path.")
    parser.add_argument(
        "--metadata",
        help="Optional study metadata TSV with sample_alias/sample_accession/run_accession plus condition, phase, cycle, analysis_group.",
    )
    parser.add_argument(
        "--omics",
        choices=("MG", "MT", "both", "auto"),
        default="auto",
        help=(
            "Populate metagenomic columns, metatranscriptomic columns, both columns, "
            "or infer columns from ENA library_source."
        ),
    )
    parser.add_argument(
        "--sample-alias-mode",
        choices=("run", "ena"),
        default="run",
        help=(
            "Use unique run-level sample_alias values, or preserve ENA sample_alias values. "
            "Run mode is recommended because multiple ENA runs can share one biological alias."
        ),
    )
    parser.add_argument(
        "--require-library-strategy",
        action="append",
        default=[],
        help="Only emit runs matching this ENA library_strategy. Can be provided more than once.",
    )
    return parser.parse_args()


def split_metadata_values(value: str) -> list[str]:
    return [item.strip() for item in value.split(";") if item.strip()]


def read_optional_metadata(path: str | None) -> dict[str, dict[str, str]]:
    if not path:
        return {}
    metadata_path = Path(path)
    if not metadata_path.exists():
        print(f"WARNING: optional metadata file not found: {path}", file=sys.stderr)
        return {}
    metadata: dict[str, dict[str, str]] = {}
    with metadata_path.open(newline="") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        for row in reader:
            for key in (
                "sample_alias",
                "sample_id",
                "sample_title",
                "sample_accession",
                "secondary_sample_accession",
                "ena_sample_accession",
                "ena_secondary_sample_accession",
                "run_accession",
                "amplicon_run_accession",
                "metagenome_run_accession",
                "metatranscriptome_run_accessions",
            ):
                for value in split_metadata_values(row.get(key, "")):
                    metadata[value] = row
    return metadata


def fetch_ena_rows(study_accession: str) -> list[dict[str, str]]:
    query = urlencode(
        {
            "accession": study_accession,
            "result": "read_run",
            "fields": ",".join(FIELDS),
            "format": "tsv",
            "download": "true",
        }
    )
    with urlopen(f"{ENA_PORTAL_URL}?{query}") as response:
        text = response.read().decode("utf-8")
    return list(csv.DictReader(text.splitlines(), delimiter="\t"))


def split_pair(value: str) -> tuple[str, str]:
    parts = [item for item in value.split(";") if item]
    if len(parts) != 2:
        raise ValueError(f"Expected paired FASTQ entries, observed {len(parts)}: {value}")
    return parts[0], parts[1]


def metadata_for(row: dict[str, str], metadata: dict[str, dict[str, str]]) -> dict[str, str]:
    for key in ("run_accession", "sample_accession", "secondary_sample_accession", "sample_alias"):
        value = row.get(key, "")
        if value in metadata:
            return metadata[value]
    return {}


def main() -> int:
    args = parse_args()
    metadata = read_optional_metadata(args.metadata)
    rows = fetch_ena_rows(args.study_accession)
    allowed_library_strategies = {item.upper() for item in args.require_library_strategy}

    output_columns = [
        "sample_alias",
        "biological_sample_alias",
        "omics",
        "omics_replicate",
        "condition",
        "phase",
        "cycle",
        "analysis_group",
        "MG_R1",
        "MG_R2",
        "MT_R1",
        "MT_R2",
        "MG_R1_md5",
        "MG_R2_md5",
        "MT_R1_md5",
        "MT_R2_md5",
        "run_accession",
        "sample_accession",
        "study_accession",
        "secondary_study_accession",
        "library_strategy",
        "library_source",
        "library_selection",
        "instrument_model",
        "fastq_bytes",
    ]

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=output_columns, delimiter="\t")
        writer.writeheader()
        replicate_counts: dict[tuple[str, str], int] = {}
        for row in rows:
            if row.get("library_layout") != "PAIRED":
                print(f"Skipping non-paired run {row.get('run_accession')}", file=sys.stderr)
                continue
            library_strategy = row.get("library_strategy", "").upper()
            if allowed_library_strategies and library_strategy not in allowed_library_strategies:
                print(
                    f"Skipping run {row.get('run_accession')} with library_strategy={library_strategy}",
                    file=sys.stderr,
                )
                continue
            if library_strategy not in {"WGS", "RNA-SEQ", "TRANSCRIPTOMIC"}:
                print(
                    f"WARNING: run {row.get('run_accession')} has library_strategy={library_strategy}; "
                    "confirm this is suitable for MG/MT preprocessing before using it for rMAG recovery.",
                    file=sys.stderr,
                )
            read_1, read_2 = split_pair(row.get("fastq_ftp", ""))
            md5_1, md5_2 = split_pair(row.get("fastq_md5", ""))
            extra = metadata_for(row, metadata)
            biological_sample_alias = (
                extra.get("sample_title")
                or extra.get("sample_alias")
                or extra.get("sample_id")
                or row.get("sample_alias")
                or row.get("run_accession")
            )
            if args.sample_alias_mode == "run":
                omics_label = infer_omics_label(row)
                sample_alias = f"{biological_sample_alias}__{omics_label}__{row.get('run_accession')}"
            else:
                sample_alias = biological_sample_alias
            omics_label = infer_omics_label(row)
            replicate_key = (biological_sample_alias, omics_label)
            replicate_counts[replicate_key] = replicate_counts.get(replicate_key, 0) + 1

            out = {column: "" for column in output_columns}
            out.update(
                {
                    "sample_alias": sample_alias,
                    "biological_sample_alias": biological_sample_alias,
                    "omics": omics_label,
                    "omics_replicate": str(replicate_counts[replicate_key]),
                    "condition": extra.get("condition", ""),
                    "phase": extra.get("phase", ""),
                    "cycle": extra.get("cycle", ""),
                    "analysis_group": extra.get("analysis_group", ""),
                    "run_accession": row.get("run_accession", ""),
                    "sample_accession": row.get("sample_accession", ""),
                    "study_accession": row.get("study_accession", ""),
                    "secondary_study_accession": row.get("secondary_study_accession", ""),
                    "library_strategy": row.get("library_strategy", ""),
                    "library_source": row.get("library_source", ""),
                    "library_selection": row.get("library_selection", ""),
                    "instrument_model": row.get("instrument_model", ""),
                    "fastq_bytes": row.get("fastq_bytes", ""),
                }
            )

            fill_mg, fill_mt = columns_to_fill(args.omics, row)
            if fill_mg:
                out.update(
                    {
                        "MG_R1": read_1,
                        "MG_R2": read_2,
                        "MG_R1_md5": md5_1,
                        "MG_R2_md5": md5_2,
                    }
                )
            if fill_mt:
                out.update(
                    {
                        "MT_R1": read_1,
                        "MT_R2": read_2,
                        "MT_R1_md5": md5_1,
                        "MT_R2_md5": md5_2,
                    }
                )

            writer.writerow(out)

    return 0


def infer_omics_label(row: dict[str, str]) -> str:
    library_source = row.get("library_source", "").upper()
    if library_source == "METATRANSCRIPTOMIC":
        return "MT"
    if library_source == "METAGENOMIC":
        return "MG"
    return row.get("library_strategy", "run").lower()


def columns_to_fill(omics: str, row: dict[str, str]) -> tuple[bool, bool]:
    if omics == "MG":
        return True, False
    if omics == "MT":
        return False, True
    if omics == "both":
        return True, True

    library_strategy = row.get("library_strategy", "").upper()
    library_source = row.get("library_source", "").upper()
    if library_strategy != "WGS":
        return False, False
    if library_source == "METAGENOMIC":
        return True, False
    if library_source == "METATRANSCRIPTOMIC":
        return False, True
    return False, False


if __name__ == "__main__":
    raise SystemExit(main())
