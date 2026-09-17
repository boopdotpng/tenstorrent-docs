"""Offline data integrity and real HTTP contract checks; no device access."""
import importlib.util
import json
from pathlib import Path
import tempfile
import threading
import unittest
from urllib.error import HTTPError
from urllib.parse import urlencode
from urllib.request import urlopen

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('docs_server', ROOT / 'viewer/server.py')
server = importlib.util.module_from_spec(spec)
spec.loader.exec_module(server)


class Reference(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.data = json.loads((ROOT / 'viewer/data/instructions.json').read_text())
        cls.ops = {x['name']: x for x in cls.data['instructions']}

    def test_complete_unique_snapshot(self):
        self.assertEqual(len(self.ops), 137)
        self.assertEqual(len(self.ops), len(self.data['instructions']))
        for op in self.ops.values():
            self.assertTrue(op['timing_status'])
            self.assertEqual(op['behavior'] == 'partial', bool(op['contracts']))

    def test_timing_preserves_unknown_and_corrected_dmanop(self):
        for name in ('RAREB', 'RSTDMA', 'TRNSPSRCA'):
            self.assertEqual(self.ops[name]['timing_status'], 'unknown')
        self.assertEqual(self.ops['TBUFCMD']['timing_status'], 'reserved')
        for row in self.ops['DMANOP']['observations']:
            self.assertTrue(all(.98 < slope < 1.02 for slope in row['slopes']))
        self.assertEqual(self.ops['MVMUL']['timing'][0]['latency'], '5')
        self.assertEqual(self.ops['MVMUL']['timing'][0]['issue_interval'], '1')

    def test_measured_records_have_completion_and_raw_evidence(self):
        rows = [r for op in self.ops.values() for r in op['observations']]
        self.assertEqual(len(rows), 129)
        self.assertEqual(sum(bool(x['observations']) for x in self.ops.values()), 24)
        for row in rows:
            self.assertTrue(row['completion'])
            self.assertEqual(len(row['probe_source_sha256']), 64)
            self.assertEqual(len(row['points']), 3)
            self.assertTrue(all(len(p['raw_cycles']) == 7 for p in row['points']))

    def test_claims_keep_gaps_and_exact_selectors(self):
        for op in self.ops.values():
            for claim in op['contracts']:
                self.assertTrue(claim['assertion'])
                self.assertTrue(claim['gaps'])
                self.assertTrue(claim['tests'])
                for test in claim['tests']:
                    self.assertIn('::', test['selector'])


class HTTP(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.http = server.ThreadingHTTPServer(('127.0.0.1', 0), server.Handler)
        cls.thread = threading.Thread(target=cls.http.serve_forever, daemon=True)
        cls.thread.start()
        cls.base = f'http://127.0.0.1:{cls.http.server_port}'

    @classmethod
    def tearDownClass(cls):
        cls.http.shutdown()
        cls.http.server_close()
        cls.thread.join()

    def get(self, path):
        with urlopen(self.base + path) as r:
            return r.read(), r.headers

    def test_home_and_all_indexed_documents(self):
        body, headers = self.get('/')
        self.assertIn(b'ISA reference', body)
        self.assertIn("script-src 'self'", headers['Content-Security-Policy'])
        body, _ = self.get('/api/index')
        index = json.loads(body)
        self.assertTrue(index['documents'])
        self.assertTrue(any(d['historical'] for d in index['documents']))
        for doc in index['documents']:
            self.assertTrue(server.locate('docs', doc['path']).is_file())

    def test_search_body_and_archives(self):
        body, _ = self.get('/api/search?' + urlencode({'q':'firmware', 'scope':'documents'}))
        results = json.loads(body)
        self.assertTrue(results)
        self.assertFalse(any(d['historical'] for d in results))
        body, _ = self.get('/api/search?' + urlencode({'q':'4234a9d727e52a6bb033c387d2c869cea4caf641', 'scope':'archives'}))
        self.assertTrue(json.loads(body))
        self.assertTrue(all(d['historical'] for d in json.loads(body)))

    def test_dedicated_pages_and_redirects(self):
        for route in ('/isa','/archives'):
            body, _ = self.get(route)
            self.assertIn(b'id="main"', body)
        body, _ = self.get('/api/index')
        index = json.loads(body)
        self.assertEqual(index['redirects']['kernel-dev/dataflow-and-cbs.md'], 'kernel-dev/dataflow.md')
        self.assertFalse(any(d['path']=='kernel-dev/dataflow-and-cbs.md' for d in index['documents']))

    def test_document_and_reference(self):
        body, _ = self.get('/api/document?' + urlencode({'repo':'docs','path':'intro.md'}))
        self.assertEqual(json.loads(body)['format'], 'markdown')
        body, _ = self.get('/api/instructions')
        self.assertEqual(len(json.loads(body)['instructions']), 137)

    def test_path_boundaries(self):
        for repo, path in [('docs','../blackhole-py/README.md'),('docs','.git/config'),('docs','/etc/passwd'),('unknown','README.md')]:
            with self.subTest(path=path), self.assertRaises(HTTPError) as raised:
                self.get('/api/document?' + urlencode({'repo':repo,'path':path}))
            self.assertIn(raised.exception.code, (400,404))
            raised.exception.close()
        with tempfile.TemporaryDirectory() as directory:
            link = Path(directory)/'external.md'
            link.symlink_to('/etc/passwd')
            old = server.ROOT
            try:
                server.ROOT = Path(directory)
                with self.assertRaises(FileNotFoundError): server.locate('docs','external.md')
            finally:
                server.ROOT = old

    def test_missing_source_is_explicit(self):
        with self.assertRaises(HTTPError) as raised:
            self.get('/api/document?repo=blackhole-py&path=does-not-exist.md')
        self.assertEqual(raised.exception.code,404)
        self.assertIn('not available', json.load(raised.exception)['error'])
        raised.exception.close()


if __name__ == '__main__': unittest.main()
