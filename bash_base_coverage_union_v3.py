#!/usr/bin/env python3
"""Strict union of kcov/ShellSpec Cobertura source-line reports.

The first report is the canonical full instrumentation baseline. All further
full reports must have precisely the same file and measurable-line sets. The
last N reports may be marked supplemental, e.g., a kcov PTY probe; supplemental
reports may omit whole files, but every present file must have exactly the
baseline's measurable-line set. This prevents a subset report from falsely
failing full-versus-full validation without relaxing source-line identity.

All reports must be generated against the same source bytes. Cobertura XML
alone cannot prove that; invoke this on reports collected in one source-locked
run (as done by verify-final-coverage-v3.sh).
"""

import argparse
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

TARGETS = (
    "alias.sh", "argument.sh", "array.sh", "constant.sh", "document.sh",
    "out.sh", "process.sh", "reflection.sh", "string.sh", "tool.sh",
)


def load_cobertura(path):
    path = Path(path)
    if not path.is_file():
        raise ValueError(f"Not found: {path}")
    try:
        root = ET.parse(path).getroot()
    except ET.ParseError as exc:
        raise ValueError(f"Invalid Cobertura XML {path}: {exc}") from exc
    if root.tag != "coverage":
        raise ValueError(f"Not a Cobertura coverage root in {path}")

    files = {}
    for cls in root.iter("class"):
        name = Path(cls.get("filename") or "").name
        if name not in TARGETS:
            continue
        hits_for_file = files.setdefault(name, {})
        for line in cls.iter("line"):
            try:
                number = int(line.get("number", ""))
                hits = int(line.get("hits", ""))
            except ValueError as exc:
                raise ValueError(f"Malformed line entry in {path}: {name}: {exc}") from exc
            if number <= 0 or hits < 0:
                raise ValueError(f"Negative hit count or invalid line in {path}: {name}:{number}")
            hits_for_file[number] = max(hits_for_file.get(number, 0), hits)

    if not files:
        raise ValueError(f"No target src/*.sh classes in {path}")
    if not any(hits > 0 for lines in files.values() for hits in lines.values()):
        raise ValueError(f"Zero production-source hits in {path}")
    return files


def collect_differences(baseline, reports, supplemental_last):
    differences = []
    cutoff = len(reports) - supplemental_last
    for i, (name, report) in enumerate(reports[1:], start=1):
        supplemental = i >= cutoff
        present = set(report)
        expected = set(baseline)
        extra_files = sorted(present - expected)
        missing_files = sorted(expected - present) if not supplemental else []
        if extra_files or missing_files:
            differences.append((name, f"files extra={extra_files} missing={missing_files}"))
        for filename in sorted(expected & present):
            extra = sorted(set(report[filename]) - set(baseline[filename]))
            absent = sorted(set(baseline[filename]) - set(report[filename]))
            if extra or absent:
                differences.append((name, f"{filename}: extra lines={extra}, absent lines={absent}"))
    return differences


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-dir", type=Path, help="Current src directory, for snippets and file validation")
    parser.add_argument("--strict-line-sets", action="store_true", help="Reject mismatched full reports or supplemental subsets")
    parser.add_argument("--supplemental-last", type=int, default=0, metavar="N",
                        help="Allow last N reports (such as PTY) to omit whole src files")
    parser.add_argument("--require-100", action="store_true", help="Fail unless validated union hits every baseline line")
    parser.add_argument("reports", nargs="+", help="Full reports first, then optional supplemental reports")
    args = parser.parse_args(argv)

    if len(args.reports) < 2:
        parser.error("Provide at least two reports")
    if args.supplemental_last < 0 or args.supplemental_last >= len(args.reports):
        parser.error("--supplemental-last must be 0..N-1, leaving at least one full baseline")
    if args.supplemental_last and not (args.strict_line_sets or args.require_100):
        parser.error("--supplemental-last requires --strict-line-sets or --require-100")
    if len({str(Path(p).resolve()) for p in args.reports}) != len(args.reports):
        parser.error("Duplicate report path")

    source_lines = {}
    if args.source_dir:
        if not args.source_dir.is_dir():
            parser.error(f"Not a directory: {args.source_dir}")
        # Fail closed if the library gains a new source file.
        actual_files = {p.name for p in args.source_dir.glob("*.sh")}
        if actual_files != set(TARGETS):
            parser.error(f"Unexpected src inventory: extra={sorted(actual_files - set(TARGETS))}, "
                         f"missing={sorted(set(TARGETS) - actual_files)}")
        source_lines = {name: (args.source_dir / name).read_text(encoding="utf-8").splitlines()
                      for name in TARGETS}

    try:
        reports = [(path, load_cobertura(path)) for path in args.reports]
    except ValueError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2

    baseline = reports[0][1]
    if set(baseline) != set(TARGETS):
        print(f"ERROR: Full baseline must contain all 10 src files; "
              f"missing={sorted(set(TARGETS) - set(baseline))}", file=sys.stderr)
        return 2
    if source_lines:
        for filename, hit_map in baseline.items():
            out_of_range = [n for n in hit_map if n > len(source_lines[filename])]
            if out_of_range:
                print(f"ERROR: Baseline lines outside current {filename}: {sorted(out_of_range)}", file=sys.stderr)
                return 2

    problems = collect_differences(baseline, reports, args.supplemental_last)
    full_count = len(reports) - args.supplemental_last
    print("Coverage sources (first is the full baseline):")
    for i, (path, report) in enumerate(reports):
        total = sum(len(lines) for lines in report.values())
        covered = sum(sum(hits > 0 for hits in lines.values()) for lines in report.values())
        kind = "full" if i < full_count else "supplemental"
        print(f"  [{kind}] {path}: {covered}/{total} entries in {len(report)} src files")

    hits = {
        filename: {n for n in lines if any(report.get(filename, {}).get(n, 0) > 0 for _, report in reports)}
        for filename, lines in baseline.items()
    }
    total = sum(map(len, baseline.values()))
    covered = sum(map(len, hits.values()))
    print("\nUnion (diagnostic):")
    for filename in TARGETS:
        missing = sorted(set(baseline[filename]) - hits[filename])
        print(f"  {filename:16} {len(hits[filename]):3}/{len(baseline[filename]):3} "
              f"({100 * len(hits[filename]) / len(baseline[filename]):6.2f}%)"
              + (f" missing={missing}" if missing else ""))
        if source_lines:
            for n in missing:
                print(f"    L{n:>4}: {source_lines[filename][n - 1].strip()}")

    missing_count = total - covered
    print(f"\nDIAGNOSTIC UNION: {covered}/{total} ({100 * covered / total:.2f}%), missing {missing_count}")
    if problems:
        print("MEASURABLE_LINE_SETS=FAIL")
        for path, reason in problems:
            print(f"  MISMATCH in {path}: {reason}")
    else:
        print(f"MEASURABLE_LINE_SETS=PASS full_reports={full_count} "
              f"supplemental_reports={args.supplemental_last}")
    print("Note: Cobertura cannot attest the source revision; collect all reports in a source-locked run.")

    if problems and (args.strict_line_sets or args.require_100):
        print("COVERAGE_GATE=FAIL_REPORT_VALIDATION")
        return 3
    if args.require_100:
        if missing_count:
            print(f"COVERAGE_GATE=FAIL_MISSING_{missing_count}")
            return 4
        print("COVERAGE_GATE=PASS_100_PERCENT")
    return 0


if __name__ == "__main__":
    sys.exit(main())
