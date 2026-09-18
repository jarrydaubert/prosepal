#!/usr/bin/env python3
"""Capture staging evaluation evidence privately; never handle a provider key."""
import base64
import json
import os
from pathlib import Path
import sys
import urllib.error
import urllib.request

ENDPOINT = 'https://llolwgqphwnhbiqewmcq.supabase.co/functions/v1/evaluate-writing'
REPO = Path(__file__).resolve().parents[1]
SECRET_FILE = Path.home() / '.config/prosepal/staging-gateway-secret'


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def send(request):
    opener = urllib.request.build_opener(NoRedirect)
    try:
        response = opener.open(request, timeout=40)
    except urllib.error.HTTPError as error:
        response = error
    with response:
        return response.status, response.read()


def request(method, secret, body=None):
    return urllib.request.Request(ENDPOINT, method=method, data=body, headers={
        'Content-Type': 'application/json', 'Accept': 'application/json',
        'X-ProsePal-Dev-Gateway-Secret': secret,
    })


def write_private(path, data):
    descriptor = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(descriptor, 'wb') as output:
        output.write(data)


def capture(input_bytes, destination, secret, transport=send):
    destination = Path(destination).resolve()
    if destination.is_relative_to(REPO):
        raise ValueError('Evaluation evidence must be outside the repository.')
    # Create exclusively before any calls; never repeat a call for an existing batch.
    destination.mkdir(mode=0o700)
    write_private(destination / 'request.json', input_bytes)
    status, manifest = transport(request('GET', secret))
    write_private(destination / 'manifest.json', manifest)
    if status != 200:
        raise ValueError('Evaluation manifest unavailable; no generation requested.')
    configuration = json.loads(manifest)
    expected = {
        'requested_model': 'anthropic/claude-sonnet-5',
        'provider_route': 'anthropic', 'fallback': False, 'zdr_required': True,
        'max_output_tokens': 700, 'max_input_utf8_bytes': 2048,
        'max_price_usd_per_million_tokens': {'prompt': 2, 'completion': 10},
    }
    if any(configuration.get(key) != value for key, value in expected.items()):
        raise ValueError('Evaluation manifest differs from the approved pin/caps; no generation requested.')
    status, envelope = transport(request('POST', secret, input_bytes))
    write_private(destination / 'response.json', envelope)
    write_private(destination / 'http-status.json', json.dumps({'status': status}).encode())
    parsed = json.loads(envelope)
    if 'raw_response_base64' in parsed:
        write_private(destination / 'provider-response.raw',
                      base64.b64decode(parsed['raw_response_base64'], validate=True))
    return status


def main():
    args = sys.argv[1:]
    if args != ['manifest'] and not (len(args) == 3 and args[0] == 'capture'):
        raise ValueError('Usage: capture_writing_evaluation.py manifest | capture REQUEST.json NEW_PRIVATE_DIRECTORY')
    secret = SECRET_FILE.read_text().strip()
    if not secret:
        raise ValueError('Existing staging gateway secret is empty.')
    if args == ['manifest']:
        status, body = send(request('GET', secret))
        if status != 200:
            raise ValueError('Evaluation manifest unavailable; no generation requested.')
        print(json.dumps(json.loads(body), indent=2))
        return
    status = capture(Path(args[1]).read_bytes(), args[2], secret)
    print(f'Private evidence captured (HTTP {status}). No outputs or identities printed.')
    if status != 200:
        raise ValueError('Evaluation failed; raw evidence retained where available. No retry performed.')


if __name__ == '__main__':
    try:
        main()
    except Exception:
        # Network exceptions may contain request details; never print them.
        print('Evaluation capture failed. Check private artefacts/configuration; no retry performed.', file=sys.stderr)
        sys.exit(1)
