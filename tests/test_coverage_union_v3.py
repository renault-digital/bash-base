"""Self-tests for report validation/export; fixtures are NOT library coverage.

Run from the repository root:
    python3 -m unittest discover -s tests -p 'test_coverage_union_v3.py' -v
Only the Python standard library is required. No network or production tests run.
"""

import copy
import importlib.util
import subprocess
import sys
import tempfile
import time
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOOL = ROOT / 'bash_base_coverage_union_v3.py'
SPEC = importlib.util.spec_from_file_location('coverage_union', TOOL)
UNION = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(UNION)


class CoverageUnionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='coverage-export-test-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.src = self.root / 'src'
        self.src.mkdir()
        for name in UNION.TARGETS:
            (self.src / name).write_text('# synthetic fixture\ntrue\ntrue\ntrue\n')
        # Three full instrumentation inventories, different observed hits.
        self.full = []
        for i in range(3):
            report = {name: {2: 0, 3: 0, 4: 0} for name in UNION.TARGETS}
            for lines in report.values():
                lines[i + 2] = i + 1
            self.full.append(report)
        # The TTY fixture omits files but not lines in its one present file.
        self.tty = {'argument.sh': {2: 0, 3: 0, 4: 1}}
        self.paths = [self.root / f'full-{i}.xml' for i in range(3)]
        self.paths.append(self.root / 'tty.xml')
        self.output = self.root / 'export' / 'cobertura.xml'
        self.save_reports()

    def write_report(self, path, report):
        root = ET.Element('coverage')
        classes = ET.SubElement(ET.SubElement(ET.SubElement(root, 'packages'), 'package'), 'classes')
        for name, hit_map in report.items():
            cls = ET.SubElement(classes, 'class', filename=f'/fixture/repo/src/{name}')
            lines = ET.SubElement(cls, 'lines')
            for number, hits in hit_map.items():
                ET.SubElement(lines, 'line', number=str(number), hits=str(hits))
        ET.ElementTree(root).write(path, encoding='utf-8', xml_declaration=True)

    def save_reports(self):
        for path, report in zip(self.paths, self.full + [self.tty]):
            self.write_report(path, report)

    def run_tool(self, export=True, require=True, source=True, strict=True,
                 paths=None, extra=()):
        cmd = [sys.executable, str(TOOL)]
        if strict:
            cmd += ['--strict-line-sets']
        if source:
            cmd += ['--source-dir', str(self.src)]
        if require:
            cmd += ['--require-100']
        cmd += ['--supplemental-last', '1']
        if export:
            cmd += ['--output-cobertura', str(self.output)]
        cmd += list(extra) + [str(p) for p in (paths or self.paths)]
        return subprocess.run(cmd, text=True, capture_output=True, timeout=10)

    def assert_rejected(self, result, status):
        self.assertEqual(result.returncode, status, result.stdout + result.stderr)
        self.assertFalse(self.output.exists())
        self.assertNotIn('COVERAGE_GATE=PASS_100_PERCENT', result.stdout)

    def test_full_union_export_is_exact(self):
        before = {p.name: p.read_bytes() for p in self.src.iterdir()}
        r = self.run_tool()
        self.assertEqual(r.returncode, 0, r.stderr + r.stdout)
        self.assertIn('COVERAGE_GATE=PASS_100_PERCENT', r.stdout)
        root = ET.parse(self.output).getroot()
        self.assertEqual(root.get('lines-valid'), '30')
        self.assertEqual(root.get('lines-covered'), '30')
        self.assertEqual(float(root.get('line-rate')), 1.0)
        self.assertEqual(root.findtext('./sources/source'), '.')
        classes = root.findall('./packages/package/classes/class')
        self.assertEqual(len(classes), len(UNION.TARGETS))
        self.assertEqual({c.get('filename') for c in classes},
                         {f'src/{n}' for n in UNION.TARGETS})
        for cls in classes:
            lines = cls.findall('./lines/line')
            self.assertEqual([l.get('number') for l in lines], ['2', '3', '4'])
            self.assertEqual({l.get('hits') for l in lines}, {'1'})
        self.assertEqual(before, {p.name: p.read_bytes() for p in self.src.iterdir()})

    def test_uncovered_line_is_exported_as_zero_and_gate_still_fails(self):
        self.full[2]['string.sh'][4] = 0
        self.save_reports()
        r = self.run_tool()
        self.assertEqual(r.returncode, 4, r.stdout + r.stderr)
        self.assertIn('COVERAGE_GATE=FAIL_MISSING_1', r.stdout)
        self.assertNotIn('COVERAGE_GATE=PASS_100_PERCENT', r.stdout)
        root = ET.parse(self.output).getroot()
        self.assertEqual(root.get('lines-valid'), '30')
        self.assertEqual(root.get('lines-covered'), '29')
        line = root.find(".//class[@filename='src/string.sh']/lines/line[@number='4']")
        self.assertEqual(line.get('hits'), '0')

    def test_tty_is_allowed_to_supply_the_only_hit(self):
        self.full[2]['argument.sh'][4] = 0
        self.save_reports()
        r = self.run_tool()
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertEqual(ET.parse(self.output).getroot().get('lines-covered'), '30')

    def test_full_report_missing_file_is_rejected(self):
        del self.full[1]['tool.sh']
        self.save_reports()
        self.assert_rejected(self.run_tool(), 3)

    def test_full_report_missing_line_is_rejected(self):
        del self.full[1]['string.sh'][3]
        self.save_reports()
        self.assert_rejected(self.run_tool(), 3)

    def test_full_report_extra_line_is_rejected(self):
        self.full[1]['string.sh'][1] = 1
        self.save_reports()
        self.assert_rejected(self.run_tool(), 3)

    def test_supplemental_missing_line_in_present_file_is_rejected(self):
        del self.tty['argument.sh'][2]
        self.save_reports()
        self.assert_rejected(self.run_tool(), 3)

    def test_supplemental_extra_line_is_rejected(self):
        self.tty['argument.sh'][1] = 1
        self.save_reports()
        self.assert_rejected(self.run_tool(), 3)

    def test_duplicate_input_path_is_rejected(self):
        self.assert_rejected(self.run_tool(paths=self.paths[:2] + [self.paths[0], self.paths[3]]), 2)

    def test_duplicate_path_alias_is_rejected(self):
        alias = self.root / 'alias.xml'
        alias.symlink_to(self.paths[0])
        self.assert_rejected(self.run_tool(paths=[self.paths[0], alias, self.paths[2], self.paths[3]]), 2)

    def test_missing_input_is_rejected(self):
        self.paths[1].unlink()
        self.assert_rejected(self.run_tool(), 2)

    def test_malformed_xml_is_rejected(self):
        self.paths[1].write_text('<coverage>')
        self.assert_rejected(self.run_tool(), 2)

    def test_wrong_root_is_rejected(self):
        self.paths[1].write_text('<not-coverage/>')
        self.assert_rejected(self.run_tool(), 2)

    def test_negative_hits_are_rejected(self):
        self.full[1]['string.sh'][2] = -1
        self.save_reports()
        self.assert_rejected(self.run_tool(), 2)

    def test_nonnumeric_hits_are_rejected(self):
        self.full[1]['string.sh'][2] = 'invalid'
        self.save_reports()
        self.assert_rejected(self.run_tool(), 2)

    def test_nonpositive_line_number_is_rejected(self):
        self.full[1]['string.sh'][0] = 1
        self.save_reports()
        self.assert_rejected(self.run_tool(), 2)

    def test_zero_production_hits_are_rejected(self):
        self.tty = {'argument.sh': {2: 0, 3: 0, 4: 0}}
        self.save_reports()
        self.assert_rejected(self.run_tool(), 2)

    def test_missing_baseline_source_file_is_rejected(self):
        del self.full[0]['tool.sh']
        self.save_reports()
        self.assert_rejected(self.run_tool(), 2)

    def test_empty_baseline_inventory_is_rejected_not_divided_by_zero(self):
        self.full[0]['tool.sh'] = {}
        self.save_reports()
        self.assert_rejected(self.run_tool(), 2)

    def test_out_of_range_baseline_line_is_rejected(self):
        self.full[0]['tool.sh'][5] = 1
        self.save_reports()
        self.assert_rejected(self.run_tool(), 2)

    def test_new_production_source_file_is_rejected(self):
        (self.src / 'new-module.sh').write_text('true\n')
        self.assert_rejected(self.run_tool(), 2)

    def test_missing_production_source_file_is_rejected(self):
        (self.src / 'tool.sh').unlink()
        self.assert_rejected(self.run_tool(), 2)

    def test_output_requires_source_directory(self):
        self.assert_rejected(self.run_tool(source=False), 2)

    def test_output_requires_src_path_name(self):
        new_src = self.root / 'another-directory'
        self.src.rename(new_src)
        self.src = new_src
        self.assert_rejected(self.run_tool(), 2)

    def test_output_requires_strict_validation(self):
        self.assert_rejected(self.run_tool(strict=False, require=False), 2)

    def test_existing_output_is_not_overwritten(self):
        self.output.parent.mkdir()
        self.output.write_bytes(b'old evidence')
        r = self.run_tool()
        self.assertEqual(r.returncode, 2)
        self.assertEqual(self.output.read_bytes(), b'old evidence')
        self.assertNotIn('VALIDATED_COBERTURA=', r.stdout)

    def test_output_symlink_is_rejected(self):
        self.output.parent.mkdir()
        self.output.symlink_to(self.root / 'absent.xml')
        r = self.run_tool()
        self.assertEqual(r.returncode, 2)
        self.assertTrue(self.output.is_symlink())
        self.assertFalse((self.root / 'absent.xml').exists())

    def test_output_cannot_be_written_into_src(self):
        self.output = self.src / 'coverage.xml'
        self.assert_rejected(self.run_tool(), 2)

    def test_output_io_error_is_not_a_passing_gate(self):
        self.output.parent.write_text('not a directory')
        self.assert_rejected(self.run_tool(), 5)

    def test_non_source_classes_do_not_enter_export(self):
        self.full[0]['test_helper.sh'] = {2: 1}
        self.save_reports()
        r = self.run_tool()
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertNotIn('test_helper', self.output.read_text())
        self.assertEqual(ET.parse(self.output).getroot().get('lines-valid'), '30')

    def test_output_has_current_timestamp_and_no_invented_branches(self):
        self.assertEqual(self.run_tool().returncode, 0)
        root = ET.parse(self.output).getroot()
        self.assertLess(abs(int(root.get('timestamp')) - int(time.time())), 10)
        self.assertEqual(root.get('branches-valid'), '0')
        self.assertEqual(root.get('branches-covered'), '0')
        self.assertFalse(root.findall('.//condition'))
        self.assertEqual({l.get('branch') for l in root.findall('.//line')}, {'false'})

    def test_legacy_cli_still_passes_without_export(self):
        r = self.run_tool(export=False)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertIn('COVERAGE_GATE=PASS_100_PERCENT', r.stdout)
        self.assertNotIn('VALIDATED_COBERTURA=', r.stdout)
        self.assertFalse(self.output.exists())

    def test_legacy_cli_still_fails_missing_coverage(self):
        self.full[2]['string.sh'][4] = 0
        self.save_reports()
        self.assert_rejected(self.run_tool(export=False), 4)

    def test_strict_export_without_require100_reports_actual_partial_coverage(self):
        self.full[2]['string.sh'][4] = 0
        self.save_reports()
        r = self.run_tool(require=False)
        self.assertEqual(r.returncode, 0)
        self.assertNotIn('COVERAGE_GATE=PASS_100_PERCENT', r.stdout)
        self.assertEqual(ET.parse(self.output).getroot().get('lines-covered'), '29')

    def test_require100_alone_still_validates_all_line_sets(self):
        del self.full[1]['tool.sh'][2]
        self.save_reports()
        self.assert_rejected(self.run_tool(strict=False), 3)

    def test_export_roundtrip_preserves_zero_lines_and_inventory(self):
        self.full[2]['string.sh'][4] = 0
        self.save_reports()
        self.assertEqual(self.run_tool().returncode, 4)
        loaded = UNION.load_cobertura(self.output)
        self.assertEqual(set(loaded), set(UNION.TARGETS))
        for name in UNION.TARGETS:
            self.assertEqual(set(loaded[name]), set(self.full[0][name]))
        self.assertEqual(loaded['string.sh'][4], 0)

    def test_duplicate_class_line_entries_do_not_inflate_denominator(self):
        root = ET.parse(self.paths[0]).getroot()
        classes = root.find('.//classes')
        classes.append(copy.deepcopy(classes[0]))
        ET.ElementTree(root).write(self.paths[0])
        self.assertEqual(self.run_tool().returncode, 0)
        self.assertEqual(ET.parse(self.output).getroot().get('lines-valid'), '30')


if __name__ == '__main__':
    unittest.main()
