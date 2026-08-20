#!/usr/bin/env python3
"""
Confronta due cartelle (la repo git e una sua export storica) e produce
un report markdown riassuntivo per fare l'analisi insieme.

Uso:
    python3 confronta_export.py /percorso/repo /percorso/export [-o report.md]

Le categorie del report:
  - identici     stesso contenuto
  - diversi      presenti in entrambi ma con contenuto differente (con diff)
  - solo repo    aggiunti dopo l'export (o robaccia locale)
  - solo export  modifiche tue mai committate / file rimossi dalla repo
"""

import argparse
import difflib
import hashlib
import os
import time

# cartelle/file da ignorare su entrambi i lati (configurabile con -e)
DEFAULT_EXCLUDES = {".git", "build", ".idea", ".config", "node_modules", ".DS_Store"}


def sha256(path, chunk=1 << 16):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while True:
            data = f.read(chunk)
            if not data:
                break
            h.update(data)
    return h.digest()


def scan_tree(root, excludes):
    """Ritorna {percorso_relativo: (percorso_assoluto, size, mtime)} dei file sotto root."""
    files = {}
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in excludes]
        for name in filenames:
            if name in excludes:
                continue
            rel = os.path.relpath(os.path.join(dirpath, name), root)
            try:
                st = os.stat(os.path.join(dirpath, name))
                files[rel] = (os.path.join(dirpath, name), st.st_size, st.st_mtime)
            except OSError:
                files[rel] = (os.path.join(dirpath, name), -1, -1.0)
    return files


def is_binary(path):
    with open(path, "rb") as f:
        return b"\0" in f.read(8192)


def diff_excerpt(path_repo, path_export, rel, max_lines):
    """Diff unificato (testo) tra i due file, troncato a max_lines. None se binario/non leggibile."""
    try:
        if is_binary(path_repo) or is_binary(path_export):
            return None
        with open(path_repo, encoding="utf-8", errors="replace") as f:
            lines_repo = f.readlines()
        with open(path_export, encoding="utf-8", errors="replace") as f:
            lines_export = f.readlines()
    except OSError:
        return None
    diff = list(difflib.unified_diff(
        lines_repo, lines_export,
        fromfile=f"repo/{rel}", tofile=f"export/{rel}", n=1))
    if len(diff) > max_lines:
        diff = diff[:max_lines] + [f"... [troncato: altre {len(diff) - max_lines} righe di diff]\n"]
    return "".join(diff)


def fmt_size(n):
    if n < 0:
        return "?"
    for unit in ("B", "KB", "MB", "GB"):
        if n < 1024:
            return f"{n:.0f} {unit}" if unit == "B" else f"{n:.1f} {unit}"
        n /= 1024
    return f"{n:.1f} TB"


def fmt_ts(ts):
    return time.strftime("%d/%m/%Y %H:%M", time.localtime(ts)) if ts > 0 else "?"


def main():
    ap = argparse.ArgumentParser(description="Confronto repo git vs export, con report markdown.")
    ap.add_argument("repo", help="cartella della repo git (es. /workspace)")
    ap.add_argument("export", help="cartella export da confrontare")
    ap.add_argument("-o", "--output", default="confronto_report.md", help="file di report")
    ap.add_argument("-e", "--exclude",
                    default=",".join(sorted(DEFAULT_EXCLUDES)),
                    help="esclusioni separata da virgola (default: %(default)s)")
    ap.add_argument("--diff-lines", type=int, default=30,
                    help="max righe di diff per file nel report (default: %(default)s)")
    ap.add_argument("--tracked", action="store_true",
                    help="considera solo i file tracciati da git nella repo (ignora materiale locale)")
    args = ap.parse_args()

    excludes = {e.strip() for e in args.exclude.split(",") if e.strip()}

    repo = scan_tree(args.repo, excludes)
    expo = scan_tree(args.export, excludes)

    if args.tracked:
        import subprocess
        ls = subprocess.run(["git", "-C", args.repo, "ls-files", "-z"],
                            capture_output=True, check=True).stdout
        tracked = {p.decode() for p in ls.split(b"\0") if p}
        repo = {rel: info for rel, info in repo.items() if rel in tracked}

    common = sorted(set(repo) & set(expo))
    only_repo = sorted(set(repo) - set(expo))
    only_expo = sorted(set(expo) - set(repo))

    identical, different, unreadable = [], [], []
    for rel in common:
        try:
            same = sha256(repo[rel][0]) == sha256(expo[rel][0])
        except OSError:
            unreadable.append(rel)
            continue
        (identical if same else different).append(rel)

    # datazione dell'export: i file con la mtime piu' recente dicono quando e' stato fatto
    piu_recenti = sorted(expo.items(), key=lambda kv: kv[1][2], reverse=True)[:10]

    out = []
    out.append("# Confronto Repo vs Export\n")
    out.append(f"- generato il: {time.strftime('%d/%m/%Y %H:%M')}")
    out.append(f"- repo: `{os.path.abspath(args.repo)}`")
    out.append(f"- export: `{os.path.abspath(args.export)}`")
    out.append(f"- esclusioni: {', '.join(sorted(excludes))}\n")

    out.append("## Sintesi\n")
    out.append("| categoria | numero |")
    out.append("|---|---|")
    out.append(f"| identici | {len(identical)} |")
    out.append(f"| **diversi** | **{len(different)}** |")
    out.append(f"| **solo export** (modifiche tue / file rimossi) | **{len(only_expo)}** |")
    out.append(f"| solo repo (aggiunti dopo / robaccia locale) | {len(only_repo)} |")
    if unreadable:
        out.append(f"| non leggibili | {len(unreadable)} |")
    out.append("")

    out.append("## Datazione export (per mtime dei file)\n")
    if piu_recenti and piu_recenti[0][1][2] > 0:
        out.append("I 10 file piu' recenti nell'export (indicano quando e' stato creato/modificato):\n")
        for rel, (_, size, mtime) in piu_recenti:
            out.append(f"- {fmt_ts(mtime)} — `{rel}` ({fmt_size(size)})")
        out.append("")

    if only_expo:
        out.append(f"\n## Solo nell'export ({len(only_expo)})\n")
        out.append("File che esistono solo nell'export: tue modifiche mai committate o file rimossi dalla repo.\n")
        for rel in only_expo:
            _, size, mtime = expo[rel]
            out.append(f"- `{rel}` ({fmt_size(size)}, {fmt_ts(mtime)})")

    if only_repo:
        out.append(f"\n## Solo nella repo ({len(only_repo)})\n")
        out.append("File che esistono solo nella repo attuale: aggiunti dopo l'export o robaccia locale.\n")
        for rel in only_repo:
            _, size, _ = repo[rel]
            out.append(f"- `{rel}` ({fmt_size(size)})")

    if different:
        out.append(f"\n## File diversi ({len(different)})\n")
        for rel in different:
            _, size_r, _ = repo[rel]
            _, size_e, mtime_e = expo[rel]
            out.append(f"### `{rel}`\n")
            out.append(f"- repo: {fmt_size(size_r)} | export: {fmt_size(size_e)} (mtime {fmt_ts(mtime_e)})")
            diff = diff_excerpt(repo[rel][0], expo[rel][0], rel, args.diff_lines)
            if diff:
                out.append("```diff")
                out.append(diff.rstrip("\n"))
                out.append("```")
            else:
                out.append("- (file binario o non leggibile: nessun diff testuale)")
            out.append("")

    if unreadable:
        out.append(f"\n## Non leggibili ({len(unreadable)})\n")
        for rel in unreadable:
            out.append(f"- `{rel}`")

    with open(args.output, "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")

    print(f"Report scritto in: {os.path.abspath(args.output)}")
    print(f"  identici:     {len(identical)}")
    print(f"  diversi:      {len(different)}")
    print(f"  solo export:  {len(only_expo)}")
    print(f"  solo repo:    {len(only_repo)}")


if __name__ == "__main__":
    main()
