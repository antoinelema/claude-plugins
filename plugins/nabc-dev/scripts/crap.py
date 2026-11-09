#!/usr/bin/env python3
"""CRAP report for a nabc-dev project.

CRAP = CC² × (1 − coverage)³ + CC (Alberto Savoia, popularised by Robert C. Martin).

Reads the `crap` section of `.claude/nabc.json`, runs each source command to
produce a coverage report, merges the reports and prints the worst entries
first. Two report formats:

- `clover`  : PHPUnit Clover XML. PHPUnit already computes `complexity` and
              `crap` per method; coverage is the share of the method's
              statements that were hit.
- `crapper` : `.metrics/crap.edn` written by github.com/unclebob/crapper
              (TypeScript, JavaScript, Python, Go, Java, Rust, Clojure).

Exit codes: 0 under the threshold, 2 when an entry is above it, 1 on a
configuration error. Python standard library only.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import xml.etree.ElementTree as ET
from dataclasses import asdict, dataclass
from pathlib import Path

DEFAULT_THRESHOLD = 30.0
EDN_ENTRY = re.compile(
    r'\{:name "((?:[^"\\]|\\.)*)", :namespace "((?:[^"\\]|\\.)*)", '
    r":complexity (\d+), :coverage ([\d.]+|nil), :crap ([\d.]+|nil)\}"
)


@dataclass
class Entry:
    source: str
    namespace: str
    name: str
    complexity: int
    coverage: float | None
    crap: float | None
    file: str | None


def crap_score(complexity: int, coverage_pct: float) -> float:
    uncovered = 1.0 - coverage_pct / 100.0
    return complexity * complexity * uncovered**3 + complexity


def coverage_needed(complexity: int, threshold: float) -> float | None:
    """Minimum coverage (%) bringing the score to the threshold, None if unreachable.

    At 100 % coverage CRAP equals CC: above the threshold, only splitting helps.
    """
    if complexity > threshold:
        return None
    if crap_score(complexity, 0.0) <= threshold:
        return 0.0
    uncovered = ((threshold - complexity) / (complexity * complexity)) ** (1 / 3)
    return 100.0 * (1.0 - uncovered)


def project_path(raw: str, root: Path) -> str:
    """Report paths may come from a container (/var/www/html/app/...).

    Keep the shortest suffix that exists under the project root.
    """
    path = Path(raw)
    if not path.is_absolute():
        return raw
    try:
        return str(path.relative_to(root))
    except ValueError:
        pass
    parts = path.parts[1:]
    for start in range(len(parts)):
        candidate = Path(*parts[start:])
        if (root / candidate).exists():
            return str(candidate)
    return raw


def parse_clover(report: Path, root: Path, source: str) -> list[Entry]:
    entries: list[Entry] = []
    for file_node in ET.parse(report).getroot().iter("file"):
        path = project_path(file_node.get("name", ""), root)
        classes = [c.get("name", "") for c in file_node.findall("class")]
        namespace = classes[0] if classes else path
        lines = [line for line in file_node.findall("line")]
        methods = [line for line in lines if line.get("type") == "method"]
        starts = [int(m.get("num", 0)) for m in methods]
        for index, method in enumerate(methods):
            start = starts[index]
            end = starts[index + 1] if index + 1 < len(starts) else float("inf")
            statements = [
                line
                for line in lines
                if line.get("type") == "stmt" and start <= int(line.get("num", 0)) < end
            ]
            if statements:
                hit = sum(1 for s in statements if int(s.get("count", 0)) > 0)
                coverage = 100.0 * hit / len(statements)
            else:
                coverage = 100.0 if int(method.get("count", 0)) > 0 else 0.0
            entries.append(
                Entry(
                    source=source,
                    namespace=namespace,
                    name=method.get("name", "?"),
                    complexity=int(method.get("complexity", 1)),
                    coverage=round(coverage, 1),
                    crap=float(method.get("crap", 0)),
                    file=path,
                )
            )
    return entries


def parse_crapper(report: Path, source: str) -> list[Entry]:
    def number(text: str) -> float | None:
        return None if text == "nil" else float(text)

    return [
        Entry(
            source=source,
            namespace=match.group(2),
            name=match.group(1),
            complexity=int(match.group(3)),
            coverage=number(match.group(4)),
            crap=number(match.group(5)),
            file=None,
        )
        for match in EDN_ENTRY.finditer(report.read_text(encoding="utf-8"))
    ]


def git(root: Path, *args: str) -> str:
    result = subprocess.run(
        ["git", "-C", str(root), *args], capture_output=True, text=True, check=False
    )
    return result.stdout.strip() if result.returncode == 0 else ""


def changed_files(root: Path, base: str | None, config: dict) -> set[str]:
    if not base:
        branches = config.get("git", {}).get("protected_branches") or ["main"]
        base = git(root, "merge-base", "HEAD", branches[0]) or "HEAD"
    files = git(root, "diff", "--name-only", base).splitlines()
    files += git(root, "ls-files", "-o", "--exclude-standard").splitlines()
    return {f for f in files if f}


def is_changed(entry: Entry, files: set[str]) -> bool:
    if entry.file is not None:
        return entry.file in files
    # crapper namespaces are dotted module paths (resources.js.Pages.Foo[.Class])
    for path in files:
        module = re.sub(r"\.[^./]+$", "", path).replace("/", ".")
        if entry.namespace == module or entry.namespace.startswith(module + "."):
            return True
    return False


def run_source(source: dict, root: Path) -> str | None:
    command = source.get("command", "")
    if not command:
        return None
    result = subprocess.run(
        command, shell=True, cwd=root, capture_output=True, text=True, check=False
    )
    if result.returncode != 0:
        tail = "\n".join((result.stdout + result.stderr).splitlines()[-15:])
        return f"commande en échec (code {result.returncode}) :\n{tail}"
    return None


def load_source(source: dict, root: Path) -> list[Entry]:
    label = source.get("label") or source.get("format", "?")
    report = root / source.get("report", "")
    if not report.is_file():
        raise FileNotFoundError(f"[{label}] rapport absent : {report}")
    if source.get("format") == "clover":
        return parse_clover(report, root, label)
    if source.get("format") == "crapper":
        return parse_crapper(report, label)
    raise ValueError(f"[{label}] format inconnu : {source.get('format')}")


def advice(entry: Entry, threshold: float) -> str:
    needed = coverage_needed(entry.complexity, threshold)
    if needed is None:
        return f"découper (CC {entry.complexity} > {threshold:g})"
    return f"couvrir ≥ {needed:.0f} %"


def sort_key(entry: Entry) -> tuple:
    return (entry.crap is None, -(entry.crap or 0), -entry.complexity, entry.namespace, entry.name)


def format_report(entries: list[Entry], total: int, threshold: float, top: int) -> str:
    over = [e for e in entries if e.crap is not None and e.crap > threshold]
    lines = [
        f"CRAP — seuil {threshold:g} — {len(entries)} entrées analysées sur {total}, "
        f"{len(over)} au-dessus du seuil",
        "",
        f"{'CRAP':>8} {'CC':>4} {'Cov%':>6}  {'Action':<24} Entrée",
    ]
    for entry in entries[:top]:
        crap = "N/A" if entry.crap is None else f"{entry.crap:.1f}"
        coverage = "N/A" if entry.coverage is None else f"{entry.coverage:.1f}"
        action = advice(entry, threshold) if entry.crap is not None and entry.crap > threshold else ""
        where = f"  ({entry.file})" if entry.file else ""
        lines.append(
            f"{crap:>8} {entry.complexity:>4} {coverage:>6}  {action:<24} "
            f"[{entry.source}] {entry.namespace}::{entry.name}{where}"
        )
    if len(entries) > top:
        lines.append(f"… {len(entries) - top} autres dans .metrics/crap.json")
    return "\n".join(lines)


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Rapport CRAP du projet (nabc.json → crap)")
    parser.add_argument("--root", default=".", help="racine du projet")
    parser.add_argument("--config", help="nabc.json à utiliser (défaut : <racine>/.claude/nabc.json)")
    parser.add_argument("--no-run", action="store_true", help="relire les rapports existants")
    parser.add_argument("--changed", nargs="?", const="", default=None, metavar="BASE",
                        help="seulement les fichiers modifiés depuis BASE (défaut : merge-base)")
    parser.add_argument("--threshold", type=float, help="remplace crap.threshold")
    parser.add_argument("--top", type=int, default=20)
    args = parser.parse_args(argv)

    root = Path(git(Path(args.root), "rev-parse", "--show-toplevel") or args.root).resolve()
    config_path = Path(args.config).resolve() if args.config else root / ".claude" / "nabc.json"
    if not config_path.is_file():
        print(f"Pas de {config_path} : projet non configuré pour nabc-dev.", file=sys.stderr)
        return 1
    config = json.loads(config_path.read_text(encoding="utf-8"))
    crap_config = config.get("crap") or {}
    sources = crap_config.get("sources") or []
    if not sources:
        print("CRAP non configuré : aucune source dans nabc.json → crap.sources.", file=sys.stderr)
        return 1
    threshold = args.threshold if args.threshold is not None else float(
        crap_config.get("threshold", DEFAULT_THRESHOLD)
    )

    (root / ".metrics").mkdir(exist_ok=True)
    entries: list[Entry] = []
    for source in sources:
        label = source.get("label") or source.get("format", "?")
        if not args.no_run:
            failure = run_source(source, root)
            if failure:
                print(f"[{label}] {failure}\n", file=sys.stderr)
        try:
            entries += load_source(source, root)
        except (FileNotFoundError, ValueError, ET.ParseError) as error:
            print(f"{error}", file=sys.stderr)

    entries.sort(key=sort_key)
    (root / ".metrics" / "crap.json").write_text(
        json.dumps({"threshold": threshold, "entries": [asdict(e) for e in entries]},
                   ensure_ascii=False, indent=1),
        encoding="utf-8",
    )

    selected = entries
    if args.changed is not None:
        files = changed_files(root, args.changed or None, config)
        selected = [e for e in entries if is_changed(e, files)]

    print(format_report(selected, len(entries), threshold, args.top))
    over = any(e.crap is not None and e.crap > threshold for e in selected)
    return 2 if over else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
