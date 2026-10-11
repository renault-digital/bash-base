#!/usr/bin/env python3
"""Diagnose Bash TTY-only branches with and without kcov (read-only).

Use --preload-input to send responses as soon as the target confirms that stdin
is a TTY, without waiting for prompts which kcov may redirect with xtrace.
Completion plus line hits, not prompt visibility, is required for success.
"""
import argparse
import errno
import os
from pathlib import Path
import pty
import select
import shutil
import signal
import subprocess
import sys
import tempfile
import time
import xml.etree.ElementTree as ET

WRAPPER = r'''#!/usr/bin/env bash
cd "$1" || exit 10
. src/argument.sh || exit 11
. src/tool.sh || exit 12
modeQuiet=false
coverage_tty_value=''
printf 'DIAG_STDIN_IS_TTY=%s\n' "$([[ -t 0 ]] && echo yes || echo no)"
[[ -t 0 ]] || exit 13
args_valid_or_read coverage_tty_value '^12345$' 'Coverage TTY input' || exit 14
[[ "$coverage_tty_value" == 12345 ]] || exit 15
confirm_to_continue || exit 16
printf '%s\n' 'TTY_PROBE_PASS shell=bash'
'''

class ProbeTimeout(Exception):
    pass


def execute_under_pty(cmd, repo, timeout, preload_input=False):
    master, slave = pty.openpty()
    child = None
    buf = bytearray()
    sent_first = sent_second = False
    preloaded = False
    try:
        child = subprocess.Popen(
            cmd, cwd=str(repo), stdin=slave, stdout=slave, stderr=slave,
            start_new_session=True,
        )
        os.close(slave)
        slave = -1
        deadline = time.monotonic() + timeout
        last_data = time.monotonic()
        while time.monotonic() < deadline:
            ready, _, _ = select.select([master], [], [], 0.2)
            if ready:
                try:
                    chunk = os.read(master, 65536)
                except OSError as exc:
                    if exc.errno != errno.EIO:
                        raise
                    chunk = b''
                if not chunk:
                    break
                buf.extend(chunk)
                last_data = time.monotonic()
                # kcov may consume stderr as a trace stream, so the prompt
                # printed to stderr is not necessarily visible on the PTY.
                # Only prefeed once the target itself has confirmed FD 0 is a TTY.
                if preload_input and not preloaded and b'DIAG_STDIN_IS_TTY=yes' in buf:
                    os.write(master, b'12345\ny\n')
                    preloaded = True
                    sent_first = sent_second = True
                if not sent_first and b'Coverage TTY input: ' in buf:
                    os.write(master, b'12345\n')
                    sent_first = True
                if not sent_second and b'Continue ? [y/N] ' in buf:
                    os.write(master, b'y\n')
                    sent_second = True
            if child.poll() is not None and time.monotonic() - last_data > 0.8:
                # A descendant may retain the PTY descriptor after the parent exits.
                # Do not loop until timeout waiting for an EOF that will never arrive.
                break
        else:
            raise ProbeTimeout('timeout={}s child_pid={} child_rc={} first_prompt={} '
                               'confirm_prompt={}'.format(timeout, child.pid, child.poll(),
                                                          sent_first, sent_second))
        if child.poll() is None:
            child.wait(timeout=max(0.5, deadline - time.monotonic()))
        return child.returncode, sent_first, sent_second, preloaded, buf.decode('utf-8', 'replace')
    except (ProbeTimeout, subprocess.TimeoutExpired) as exc:
        print('TTY_PROBE_FAIL {}'.format(exc), file=sys.stderr)
        print('--- PTY transcript (last 8000 characters) ---', file=sys.stderr)
        print(buf.decode('utf-8', 'replace')[-8000:] or '(no terminal output)', file=sys.stderr)
        raise
    finally:
        if child is not None:
            try:
                # Kill all descendants in the session, not only the kcov parent.
                os.killpg(child.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
            try:
                child.wait(timeout=1)
            except subprocess.TimeoutExpired:
                try:
                    os.killpg(child.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                child.wait(timeout=2)
        os.close(master)
        if slave >= 0:
            os.close(slave)


def source_hits(report, filename, lineno):
    root = ET.parse(report).getroot()
    matches = []
    for node in root.iter():
        if node.tag.split('}')[-1] != 'class':
            continue
        if (node.get('filename') or '').replace('\\', '/').split('/')[-1] != filename:
            continue
        for line in node.iter():
            if line.tag.split('}')[-1] == 'line' and line.get('number') == str(lineno):
                matches.append(int(line.get('hits', '0')))
    return max(matches) if matches else None


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', default='.')
    parser.add_argument('--shell', default='/bin/bash')
    parser.add_argument('--timeout', type=int, default=25)
    parser.add_argument('--direct', action='store_true')
    parser.add_argument('--preload-input', action='store_true',
                        help='send both answers on TTY confirmation; do not wait for stderr prompts')
    parser.add_argument('--out', help='nonexistent kcov destination')
    args = parser.parse_args()
    repo = Path(args.repo).resolve()
    shell = Path(args.shell).resolve()
    for name in ('src/argument.sh', 'src/tool.sh'):
        if not (repo / name).is_file():
            parser.error('Missing: {}'.format(repo / name))
    if not shell.is_file():
        parser.error('Shell does not exist: {}'.format(shell))
    if not args.direct and shutil.which('kcov') is None:
        parser.error('kcov was not found in PATH')
    if args.timeout < 1:
        parser.error('timeout must be >= 1 second')

    output = (Path(args.out).absolute() if args.out else
              Path(tempfile.mkdtemp(prefix='bash-base-tty-v2-')) / 'coverage')
    if not args.direct and output.exists():
        parser.error('Coverage directory already exists: {}'.format(output))

    with tempfile.TemporaryDirectory(prefix='bash-base-tty-v2-script-') as folder:
        wrapper = Path(folder) / 'tty_probe.sh'
        wrapper.write_text(WRAPPER, encoding='utf-8')
        wrapper.chmod(0o700)
        if args.direct:
            cmd = [str(shell), str(wrapper), str(repo)]
        else:
            cmd = ['kcov', '--bash-parser={}'.format(shell),
                   '--include-path={}'.format(repo / 'src'), str(output), str(wrapper), str(repo)]
        print('TTY_MODE={}'.format('DIRECT' if args.direct else 'KCOV'), flush=True)
        print('TTY_COMMAND={}'.format(' '.join(cmd[:5])), flush=True)
        try:
            rc, first, second, preloaded, transcript = execute_under_pty(
                cmd, repo, args.timeout, preload_input=args.preload_input)
        except (ProbeTimeout, OSError, subprocess.TimeoutExpired) as exc:
            # The detailed diagnostic was printed by execute_under_pty.
            if not isinstance(exc, (ProbeTimeout, subprocess.TimeoutExpired)):
                print('TTY_PROBE_FAIL OS error: {}'.format(exc), file=sys.stderr)
            return 1

    print('TTY_CHILD_EXIT={} first_answer_sent={} second_answer_sent={} preloaded={}'.format(
        rc, first, second, preloaded))
    print('--- PTY transcript (last 4000 characters) ---')
    print(transcript[-4000:] or '(empty)')
    if (rc != 0 or not first or not second or
            'DIAG_STDIN_IS_TTY=yes' not in transcript or
            'Inputted value:' not in transcript or
            'Continue...' not in transcript or
            'TTY_PROBE_PASS shell=bash' not in transcript):
        print('TTY_BEHAVIOR_INCOMPLETE', file=sys.stderr)
        return 1
    print('TTY_BEHAVIOR_PASS')
    if args.direct:
        return 0
    reports = sorted(output.rglob('cobertura.xml'))
    if not reports:
        print('TTY_COVERAGE_FAIL no Cobertura XML in {}'.format(output), file=sys.stderr)
        return 2
    report = next((p for p in reports if p.parent == output), reports[0])
    print('TTY_COBERTURA={}'.format(report))
    missing = 0
    for filename, lineno in (('argument.sh', 355), ('tool.sh', 45)):
        try:
            hits = source_hits(report, filename, lineno)
        except (ET.ParseError, OSError) as exc:
            print('TTY_COVERAGE_FAIL {}'.format(exc), file=sys.stderr)
            return 2
        print('TTY_SOURCE_HITS src/{}:{}={}'.format(filename, lineno,
                                                    hits if hits is not None else 'NOT-IN-REPORT'))
        if not hits:
            missing += 1
    if missing:
        print('TTY_COVERAGE_INCOMPLETE {} target lines'.format(missing), file=sys.stderr)
        return 2
    print('TTY_COVERAGE_PASS 2/2')
    return 0

if __name__ == '__main__':
    sys.exit(main())
