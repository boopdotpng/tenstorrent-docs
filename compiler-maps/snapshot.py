#!/usr/bin/env python3
"""Record source scope and Git blob identities without copying source into docs."""
import argparse
import json
import subprocess
from pathlib import Path


def git(root, *args):
    return subprocess.check_output(["git", "-C", str(root), *args], text=True).strip()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--workspace", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--llvm", type=Path, default=Path.home() / "builds/llvm-project")
    parser.add_argument("--output", type=Path, default=Path(__file__).resolve().parent / "inventory")
    args = parser.parse_args()
    repos = {
        "tinygrad": (args.workspace / "tinygrad", ""),
        "mlir": (args.llvm, "mlir"),
        "iree": (args.workspace / "iree", ""),
        "tt-mlir": (args.workspace / "tt-mlir", ""),
        "pytorch": (args.workspace / "pytorch", ""),
        "tinycorp-meetings": (args.workspace / "tinycorp-meetings", "last-week-in-tinycorp"),
        "tt-lang-llvm": (args.workspace / "tt-lang/third-party/llvm-project", "mlir"),
    }
    args.output.mkdir(parents=True, exist_ok=True)
    manifest = {}
    for name, (root, scope) in repos.items():
        revision = git(root, "rev-parse", "HEAD")
        # ls-tree records HEAD, not the index or untracked files. Dirty status is
        # included separately so readers cannot mistake this for a worktree hash.
        records = git(root, "ls-tree", "-r", revision, "--", scope or ".").splitlines()
        rows = []
        for record in records:
            metadata, path = record.split("\t", 1)
            mode, kind, oid = metadata.split()
            rows.append((path, kind, mode, oid))
        with (args.output / f"{name}.tsv").open("w") as out:
            out.write("path\tkind\tmode\tgit_object\n")
            for row in rows:
                out.write("\t".join(row) + "\n")
        manifest[name] = {
            "checkout": str(root.resolve()),
            "scope": scope or ".",
            "head": revision,
            "head_date": git(root, "show", "-s", "--format=%cI", "HEAD"),
            "origin": git(root, "remote", "get-url", "origin"),
            "shallow": git(root, "rev-parse", "--is-shallow-repository") == "true",
            "status": git(root, "status", "--short"),
            "entries": len(rows),
        }
    (args.output / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    for name, info in manifest.items():
        print(f"{name}: {info['head'][:12]}, {info['entries']} entries, dirty={bool(info['status'])}")


if __name__ == "__main__":
    main()
