# Codex Handoff 2026-05-26: PRJEB79569 Binning Lessons

Purpose: preserve the reusable multiomics pipeline lessons learned while running
PRJEB79569 through binning, refinement, dRep dereplication, and downstream
annotation from the project repository.

This handoff is pipeline-specific. Project-specific launchers, logs, output
paths, and MAG inventory live in `phage_uv_ecology_analysis`.

## Current State

- Branch: `feature/prjeb79569-assemblies`.
- The PRJEB79569 project completed the multiomics MAG workflow through
  binning/refinement/dRep and downstream annotation.
- The pipeline repository currently has local uncommitted rule/env changes from
  the successful run. Review and commit those separately from this handoff.
- The previous handoff, `docs/codex_handoff_2026-05-12.md`, remains useful for
  preprocessing/assembly context. This handoff supersedes it for binning and
  dereplication lessons.

Validation evidence from the project run:

- 12 biological samples completed through binning/refinement.
- dRep completed successfully.
- 348 dereplicated MAG FASTAs were produced.
- Downstream Bakta annotation completed in the project repository for all 348
  dereplicated MAGs.

## Fixes Learned From PRJEB79569

- VAMB needed a VAMB 5-compatible command shape:
  `vamb bin default`, `--bamdir`, and current bin output parsing.
- `envs/vamb_env.yml` needed Python 3.10 for the current VAMB package.
- Hardcoded `prefix:` entries in conda env YAMLs should be removed; they make
  Snakemake-managed environments non-portable across clusters/users.
- dRep currently requires `pandas<3` because it still calls the removed
  `delim_whitespace` argument.
- MAGScoT requires `r-digest`; without it, `MAGScoT.R` fails at runtime.
- DeepMicroClass binning rules should reference the repo env file path, not a
  bare environment name.
- Several binning rules were more robust when broad `directory()` outputs were
  replaced by explicit done markers plus concrete output files.
- SemiBin multi-sample contig-to-bin extraction should not have multiple sample
  jobs decompressing shared `output/bins/*` files concurrently; that race caused
  failed downstream bin extraction.

## Future Hardening

- Move shell-heavy contig-to-bin extraction logic into tested helper scripts.
  This would reduce quoting issues, wildcard mistakes, and repeated shell
  patterns across MetaBAT2, MaxBin2, SemiBin, VAMB, and MAGScoT outputs.
- Add a tiny fixture-based dry-run or test workflow for the binning rule graph.
  It should cover rule target expansion, done-marker dependencies, and
  contig-to-bin output contracts.
- Add environment validation notes or CI checks for fragile bioinformatics
  package pins: VAMB, dRep, MAGScoT, DeepMicroClass, SemiBin.
- Prefer explicit done markers and concrete expected files over broad
  `directory()` dependencies when a downstream rule only needs a completion
  signal or specific file pattern.
- Keep project-specific paths, launcher resource choices, and HPC account/QOS
  values out of this repository. Those belong in the analysis/project repo.

## Suggested Follow-Up Issues

If converting this handoff into GitHub issues later, use these focused issues:

1. Harden binning rule output contracts and contig-to-bin generation.
2. Add fixture or dry-run CI coverage for binning and annotation workflows.
3. Review and pin fragile tool environments for VAMB, dRep, MAGScoT,
   DeepMicroClass, and SemiBin.

## Review Before Committing Rule Changes

Before committing the local rule/env changes from the PRJEB79569 run, verify:

```sh
git diff --stat
bash -n <any touched shell launchers or scripts>
snakemake --dry-run --snakefile workflows/binning.smk --configfile <project-config>
```

Then commit rule/env changes separately from documentation so the operational
fixes remain easy to review.
