#!/usr/bin/env python3
"""Index direct PatternMatcher constructions and rewrite drivers without importing tinygrad."""
import argparse
import ast
import collections
import os
import pathlib
import subprocess
from urllib.parse import quote

script = pathlib.Path(__file__).resolve()
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--tinygrad-path", type=pathlib.Path, default=script.parents[3] / "tinygrad",
                    help="tinygrad repository root (default: sibling of boop-docs)")
parser.add_argument("--output", type=pathlib.Path, default=script.with_name("matcher-inventory.md"),
                    help="output Markdown file (default: alongside this generator)")
args = parser.parse_args()
root = args.tinygrad_path.resolve()
out = args.output.resolve()
if not (root / "tinygrad" / "uop" / "ops.py").is_file():
  parser.error(f"not a tinygrad source checkout: {root}")

def git(*args):
  return subprocess.check_output(["git", "-C", str(root), *args], text=True).strip()

revision, date = git("show", "-s", "--format=%H %cs", "HEAD").split()
# The census reads the worktree; avoid presenting its contents as clean HEAD if modified.
dirty = bool(git("status", "--porcelain", "--untracked-files=all", "--", "tinygrad"))
snapshot = (f"Source checkout HEAD `{revision}` ({date}). "
            + ("**The scanned source directory has worktree changes; rows describe that worktree.** " if dirty else "The scanned source directory is clean. ")
            + "Relative links refer to the scanned checkout; this generator does not fetch upstream.")

def relative_link(target):
  return quote(pathlib.Path(os.path.relpath(target, out.parent)).as_posix(), safe="/#")

guide_link = relative_link(script.with_name("uops-and-rewrites.md"))

constructors=[]; drivers=[]
for path in sorted((root/'tinygrad').rglob('*.py')):
  tree=ast.parse(path.read_text())
  parents={child:parent for parent in ast.walk(tree) for child in ast.iter_child_nodes(parent)}
  def ancestors(node):
    while node in parents:
      node=parents[node]
      yield node
  for node in ast.walk(tree):
    if not isinstance(node,ast.Call) or not isinstance(node.func,ast.Name): continue
    if node.func.id not in ('PatternMatcher','graph_rewrite','line_rewrite'): continue
    anc=list(ancestors(node))
    scope=next((a.name for a in anc if isinstance(a,(ast.FunctionDef,ast.AsyncFunctionDef))),'<module/class>')
    assigned=next((ast.unparse(a.targets[0]) if isinstance(a,ast.Assign) else ast.unparse(a.target) for a in anc if isinstance(a,(ast.Assign,ast.AnnAssign))),None)
    rel=path.relative_to(root).as_posix()
    if node.func.id=='PatternMatcher':
      patterns=node.args[0] if node.args else None
      n=str(len(patterns.elts)) if isinstance(patterns,(ast.List,ast.Tuple)) else 'dynamic'
      constructors.append((rel,node.lineno,assigned or '(inline / return)',scope,n))
    else:
      matcher=ast.unparse(node.args[1]) if len(node.args)>1 else next((ast.unparse(k.value) for k in node.keywords if k.arg=='pm'),'?')
      label=next((ast.unparse(k.value) for k in node.keywords if k.arg=='name'),'—')
      flags=', '.join(f'{k.arg}={ast.unparse(k.value)}' for k in node.keywords if k.arg in ('bottom_up','walk','enter_calls','bpm')) or 'defaults'
      drivers.append((rel,node.lineno,node.func.id,matcher,label,flags))
counts=collections.Counter(r[0] for r in constructors)
def code(x): return '`'+x.replace('|','&#124;').replace('`','\\`')+'`'
def link(path,line): return f'[{path}:{line}]({relative_link(root / path)}#L{line})'
lines=['# Tinygrad matcher construction and driver census','',
'## How to read this index', '',
'A **matcher** is a collection of conditional rewrite rules. A **construction site** is a place in Python source that creates such a collection. A **driver** walks a graph or instruction list and asks a matcher to rewrite its elements. This page answers where those collections are created and used; the linked guides explain their behavior.', '',
'For example, `pm = PatternMatcher([(pattern, callback)])` contributes one construction site and one literal rule entry. Calling `graph_rewrite(root, pm)` elsewhere contributes one driver site. Neither count says how many nodes will match when a program runs.', '',
'In the construction table, follow the source link to inspect the rule list. The assignment/function column locates its surrounding Python code. In the driver table, the matcher expression identifies the rules supplied, and traversal options describe how the caller asks the driver to visit nodes. Read the matcher and its driver together: rule order and graph traversal can both affect the result.', '',

f'For explanations and examples of individual rules, use the [rule-by-rule reference]({relative_link(script.parent / "rules/README.md")}). '
f'For focused backend reading, see [AMD]({relative_link(script.with_name("amd-pattern-matchers.md"))}) and '
f'[IMAGE]({relative_link(script.with_name("image-pattern-matchers.md"))}).', '', snapshot, '',
'This is a mechanically generated **static AST census of every Python file under `tinygrad/tinygrad/`**, including production runtime and renderer support. It excludes tests, `extra/`, docs, and other checkouts. Only direct calls whose callee is the bare identifier `PatternMatcher`, `graph_rewrite`, or `line_rewrite` are counted. Aliases, attribute calls, `.rewrite(...)`, matcher factories without those literal names, and runtime-expanded compositions are outside the count. This is a reproducible search index, not a complete execution trace.', '',
f'An assignment label is the nearest enclosing assignment in the syntax tree, not proof that the entire assignment is one matcher. For composed matchers it names the composition containing this construction site. A literal rule count counts outer list/tuple entries only; comprehensions and other expressions are marked dynamic. Driver rows show the actual matcher expression and explicit traversal flags. `defaults` means normal driver defaults apply. See [UOps and rewrites]({guide_link}#4-why-these-concrete-matchers-exist) for semantic purposes, phase dependencies, and sharp edges.', '',
f'Found **{len(constructors)} direct matcher construction sites in {len(counts)} files**, and **{len(drivers)} direct graph/list driver calls**. These are source sites, not distinct runtime matchers or rules executed.', '', '## Construction sites', '', '| Source | Assignment / enclosing function | Literal entries |', '|---|---|---:|']
for p,n,a,s,c in sorted(constructors): lines.append(f'| {link(p,n)} | {code(a)} / {code(s)} | {c} |')
lines+=['','## Driver call sites','','| Source | Driver / matcher expression | Pass label | Explicit traversal options |','|---|---|---|---|']
for p,n,d,m,l,f in sorted(drivers): lines.append(f'| {link(p,n)} | {code(d)}: {code(m)} | {code(l)} | {code(f)} |')
lines+=['','## Reproduce the scope','','Use Python `ast.parse` over `Path("tinygrad/tinygrad").rglob("*.py")`; count `ast.Call` nodes with `isinstance(call.func, ast.Name)` and `call.func.id == "PatternMatcher"`. The same condition with `graph_rewrite` / `line_rewrite` selects driver sites. Include nested functions/classes and do not follow imports. Static inspection performs no imports or device initialization. The inventory was generated with this algorithm against the revision above.','']
lines += ["## Regenerate", "",
          f"Generator: [generate-matcher-inventory.py]({relative_link(script)}). Run from the workspace root:", "",
          "```bash",
          "python3 boop-docs/compiler-maps/tinygrad/generate-matcher-inventory.py",
          "# Optional alternate checkout/output:",
          "python3 boop-docs/compiler-maps/tinygrad/generate-matcher-inventory.py \\",
          "  --tinygrad-path /path/to/tinygrad --output /path/to/matcher-inventory.md",
          "```", "",
          "Defaults resolve relative to the script, so the first command can also be invoked by absolute path from another working directory. "
          "Only Python's standard library and git are needed. Counts describe the selected worktree; HEAD and source-directory cleanliness are recorded above. "
          "Regeneration does not update the manually maintained semantic guide or validate its explanations against a new revision.", ""]
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text('\n'.join(lines))
print(len(constructors),len(counts),len(drivers))
