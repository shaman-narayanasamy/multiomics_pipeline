#!/usr/bin/env python3
"""Stage one read file from ENA or a local path for Snakemake rules."""

from __future__ import annotations

import argparse
import hashlib
import os
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from urllib.parse import urlparse


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", required=True, help="Source URL or local path.")
    parser.add_argument("--output", required=True, help="Destination FASTQ path.")
    parser.add_argument(
        "--md5",
        nargs="?",
        const="",
        default="",
        help="Optional expected MD5 checksum.",
    )
    parser.add_argument(
        "--downloader",
        choices=("curl", "wget"),
        default="curl",
        help="Downloader to use for http(s)/ftp sources.",
    )
    parser.add_argument("--retries", type=int, default=3, help="Download retry count.")
    parser.add_argument(
        "--retry-delay-seconds",
        type=int,
        default=0,
        help="Seconds to wait between download attempts.",
    )
    return parser.parse_args()


def is_remote(source: str) -> bool:
    return urlparse(source).scheme in {"http", "https", "ftp"}


def normalise_ena_url(source: str) -> str:
    if source.startswith("ftp.sra.ebi.ac.uk/") or source.startswith("ftp.ebi.ac.uk/"):
        return f"https://{source}"
    return source


def md5sum(path: Path) -> str:
    digest = hashlib.md5()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def copy_local(source: str, destination: Path) -> None:
    source_path = Path(source)
    if not source_path.exists():
        raise FileNotFoundError(f"Local source does not exist: {source}")
    shutil.copy2(source_path, destination)


def download_remote(
    source: str,
    destination: Path,
    downloader: str,
    retries: int,
    retry_delay_seconds: int,
) -> None:
    source = normalise_ena_url(source)
    attempts = max(1, retries)
    for attempt in range(1, attempts + 1):
        if attempt > 1:
            destination.unlink(missing_ok=True)
            if retry_delay_seconds > 0:
                print(
                    f"INFO: retrying {source} in {retry_delay_seconds} seconds "
                    f"(attempt {attempt}/{attempts})",
                    file=sys.stderr,
                )
                time.sleep(retry_delay_seconds)

        if downloader == "curl":
            command = [
                "curl",
                "--fail",
                "--location",
                "--retry",
                "0",
                "--output",
                str(destination),
                source,
            ]
        else:
            command = [
                "wget",
                "--tries",
                "1",
                "--continue",
                "--output-document",
                str(destination),
                source,
            ]

        try:
            subprocess.run(command, check=True)
            return
        except subprocess.CalledProcessError:
            if attempt == attempts:
                raise


def main() -> int:
    args = parse_args()
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)

    with tempfile.NamedTemporaryFile(
        prefix=f".{output.name}.", suffix=".tmp", dir=output.parent, delete=False
    ) as handle:
        tmp_path = Path(handle.name)

    try:
        if is_remote(normalise_ena_url(args.source)):
            download_remote(
                args.source,
                tmp_path,
                args.downloader,
                args.retries,
                args.retry_delay_seconds,
            )
        else:
            copy_local(args.source, tmp_path)

        if args.md5:
            observed = md5sum(tmp_path)
            expected = args.md5.lower()
            if observed.lower() != expected:
                raise ValueError(
                    f"MD5 mismatch for {args.source}: expected {expected}, observed {observed}"
                )

        os.replace(tmp_path, output)
    except Exception as exc:
        tmp_path.unlink(missing_ok=True)
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
