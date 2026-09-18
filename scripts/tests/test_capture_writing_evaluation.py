import base64
import importlib.util
import json
from pathlib import Path
import stat
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'capture_writing_evaluation.py'
spec = importlib.util.spec_from_file_location('capture_writing_evaluation', SCRIPT)
capture = importlib.util.module_from_spec(spec)
spec.loader.exec_module(capture)
MANIFEST = json.dumps({
    'requested_model': 'anthropic/claude-sonnet-5',
    'provider_route': 'anthropic', 'fallback': False, 'zdr_required': True,
    'max_output_tokens': 700, 'max_input_utf8_bytes': 2048,
    'max_price_usd_per_million_tokens': {'prompt': 2, 'completion': 10},
}).encode()


class CaptureWritingEvaluationTests(unittest.TestCase):
    def test_raw_failure_is_saved_exactly_without_retry_or_overwrite(self):
        raw = b' {"refusal":"No.\\n"}\r\n\xff'
        envelope = json.dumps({'error': 'provider_http_error',
                               'raw_response_base64': base64.b64encode(raw).decode()}).encode()
        calls = []

        def transport(request):
            calls.append(request)
            self.assertEqual(request.full_url, capture.ENDPOINT)
            self.assertEqual(request.get_header('X-prosepal-dev-gateway-secret'), 'test-access')
            if request.method == 'GET':
                return 200, MANIFEST
            self.assertEqual(request.data, b'{"synthetic":true}')
            return 502, envelope

        with tempfile.TemporaryDirectory() as parent:
            directory = Path(parent) / 'new-evidence'
            status = capture.capture(b'{"synthetic":true}', directory, 'test-access', transport)
            self.assertEqual(status, 502)
            self.assertEqual([r.method for r in calls], ['GET', 'POST'])
            self.assertEqual((directory / 'provider-response.raw').read_bytes(), raw)
            self.assertEqual((directory / 'response.json').read_bytes(), envelope)
            self.assertEqual(stat.S_IMODE(directory.stat().st_mode), 0o700)
            for path in directory.iterdir():
                self.assertEqual(stat.S_IMODE(path.stat().st_mode), 0o600)
                self.assertNotIn(b'test-access', path.read_bytes())
            with self.assertRaises(FileExistsError):
                capture.capture(b'{}', directory, 'test-access', transport)
            self.assertEqual(len(calls), 2)

    def test_manifest_failure_stops_before_generation(self):
        calls = []

        def transport(request):
            calls.append(request.method)
            return 403, b'{"error":"evaluation_staging_only"}'

        with tempfile.TemporaryDirectory() as parent:
            directory = Path(parent) / 'evidence'
            with self.assertRaisesRegex(ValueError, 'no generation requested'):
                capture.capture(b'{}', directory, 'test-access', transport)
            self.assertEqual(calls, ['GET'])
            self.assertFalse((directory / 'response.json').exists())

    def test_changed_pin_or_caps_stop_before_generation(self):
        calls = []

        def transport(request):
            calls.append(request.method)
            configuration = json.loads(MANIFEST)
            configuration['fallback'] = True
            return 200, json.dumps(configuration).encode()

        with tempfile.TemporaryDirectory() as parent:
            with self.assertRaisesRegex(ValueError, 'no generation requested'):
                capture.capture(b'{}', Path(parent) / 'evidence', 'test-access', transport)
        self.assertEqual(calls, ['GET'])

    def test_repository_destination_is_rejected_before_network_or_write(self):
        with self.assertRaisesRegex(ValueError, 'outside the repository'):
            capture.capture(b'{}', capture.REPO / 'must-not-create-evaluation', 'test-access',
                            lambda _: self.fail('No network call is allowed'))
        self.assertFalse((capture.REPO / 'must-not-create-evaluation').exists())


if __name__ == '__main__':
    unittest.main()
