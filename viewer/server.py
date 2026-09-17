#!/usr/bin/env python3
"""Read-only local documentation server. Python standard library only."""
from __future__ import annotations
import argparse
import json
import mimetypes
import re
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
VIEWER = ROOT / 'viewer'
SIBLINGS = {'blackhole-py', 'tinygrad', 'tt-isa-documentation', 'tt-llk', 'tt-metal',
            'tt-umd', 'tt-kmd', 'sfpi', 'tt-ins-docs', 'iree', 'tt-mlir', 'pytorch', 'llvm-project', 'tt-zephyr-platforms'}
TEXT_TYPES = {'.md', '.txt', '.py', '.c', '.cc', '.cpp', '.h', '.hpp', '.json', '.jsonl',
              '.yaml', '.yml', '.mlir', '.ll', '.sh', '.toml', '.csv', '.ld', '.rs', '.cmake'}
ASSET_TYPES = {'.svg', '.png', '.jpg', '.jpeg', '.gif', '.webp', '.pdf'}


def locate(repo, name, *, assets=False):
    if repo == 'docs':
        base = ROOT
    elif repo in SIBLINGS:
        base = ROOT.parent / repo
    else:
        raise ValueError('Unknown source repository')
    if not name or Path(name).is_absolute() or any(p.startswith('.') for p in Path(name).parts):
        raise ValueError('Invalid document path')
    path = (base / name).resolve()
    if not path.is_relative_to(base.resolve()) or not path.is_file():
        raise FileNotFoundError('Document is not available in this checkout')
    if any(p.startswith('.') for p in path.relative_to(base.resolve()).parts):
        raise ValueError('Hidden files are not served')
    if path.suffix.lower() not in (ASSET_TYPES if assets else TEXT_TYPES):
        raise ValueError('This file type is not served')
    if path.stat().st_size > 8 * 1024 * 1024:
        raise ValueError('File exceeds the 8 MiB viewer limit')
    return path


def document_index():
    docs = []
    for p in sorted(ROOT.rglob('*.md')):
        rel = p.relative_to(ROOT)
        if p.is_symlink() or any(x.startswith('.') for x in rel.parts) or rel.parts[0] == 'viewer':
            continue
        content = p.read_text(encoding='utf-8')
        title = re.search(r'^# (.+)$', content, re.M)
        docs.append({'path': str(rel), 'title': title[1].replace('`', '') if title else p.stem,
                     'category': rel.parts[0] if len(rel.parts) > 1 else 'Start here',
                     'historical': rel.parts[0] in {'archive', 'disasms', 'llk-sfpi'} or 'historical' in rel.parts or str(rel).startswith('microbenching/docs/'),
                     'words': len(content.split()), 'content': content})
    return docs


class Handler(BaseHTTPRequestHandler):
    def send_bytes(self, body, kind, status=200):
        self.send_response(status)
        self.send_header('Content-Type', kind)
        self.send_header('Content-Length', str(len(body)))
        self.send_header('X-Content-Type-Options', 'nosniff')
        self.send_header('Cache-Control', 'no-cache')
        self.send_header('Content-Security-Policy', "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data:; connect-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'")
        self.end_headers()
        if self.command != 'HEAD':
            self.wfile.write(body)

    def json(self, value, status=200):
        self.send_bytes(json.dumps(value, ensure_ascii=False).encode(), 'application/json; charset=utf-8', status)

    def do_HEAD(self):
        self.do_GET()

    def do_GET(self):
        url = urlsplit(self.path)
        args = {k: v[0] for k, v in parse_qs(url.query).items()}
        try:
            if url.path == '/api/index':
                docs = document_index()
                return self.json({'documents': [{k: v for k, v in d.items() if k != 'content'} for d in docs],
                                  'repositories': ['docs', *sorted(SIBLINGS)]})
            if url.path == '/api/search':
                query = args.get('q', '').lower().strip()[:200]
                if not query:
                    return self.json([])
                terms = query.split()
                results = []
                for doc in document_index():
                    if args.get('history') != '1' and doc['historical']:
                        continue
                    hay = (doc['title'] + '\n' + doc['path'] + '\n' + doc['content']).lower()
                    if not all(t in hay for t in terms):
                        continue
                    score = sum(10 * (t in doc['title'].lower()) + 5 * (t in doc['path'].lower()) for t in terms)
                    pos = max(0, doc['content'].lower().find(terms[0]) - 80)
                    results.append({**{k: v for k, v in doc.items() if k != 'content'},
                                    'score': score, 'excerpt': re.sub(r'\s+', ' ', doc['content'][pos:pos+280])})
                return self.json(sorted(results, key=lambda d: (-d['score'], d['path']))[:60])
            if url.path in {'/api/document', '/api/asset'}:
                repo, name = args.get('repo', 'docs'), args.get('path', '')
                asset = url.path == '/api/asset'
                path = locate(repo, name, assets=asset)
                if asset:
                    return self.send_bytes(path.read_bytes(), mimetypes.guess_type(path.name)[0] or 'application/octet-stream')
                return self.json({'repo': repo, 'path': name, 'content': path.read_text(encoding='utf-8'),
                                  'format': 'markdown' if path.suffix == '.md' else 'source'})
            if url.path == '/api/instructions':
                return self.send_bytes((VIEWER / 'data/instructions.json').read_bytes(), 'application/json; charset=utf-8')
            # Static assets only; never serve the repository as a directory listing.
            name = unquote(url.path).lstrip('/') or 'index.html'
            path = (VIEWER / name).resolve()
            if not path.is_relative_to(VIEWER) or any(x.startswith('.') for x in Path(name).parts):
                raise ValueError('Invalid asset path')
            if path.suffix not in {'.html', '.css', '.js', '.svg', '.ico'} or not path.is_file():
                raise FileNotFoundError('Page not found')
            self.send_bytes(path.read_bytes(), (mimetypes.guess_type(path.name)[0] or 'text/plain') + '; charset=utf-8')
        except FileNotFoundError as error:
            self.json({'error': str(error)}, 404)
        except (ValueError, UnicodeError) as error:
            self.json({'error': str(error)}, 400)

    def log_message(self, fmt, *args):
        if args and str(args[1]) not in {'200', '304'}:
            super().log_message(fmt, *args)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--port', type=int, default=8000)
    options = parser.parse_args()
    try:
        server = ThreadingHTTPServer(('0.0.0.0', options.port), Handler)
    except OSError as error:
        parser.exit(1, f'{error}. Try ./serve.sh --port 8001\n')
    print(f'Blackhole docs → http://0.0.0.0:{server.server_port}\nCtrl+C to stop. Read-only; no hardware access.', flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == '__main__':
    main()
