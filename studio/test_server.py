import tempfile
import time
import unittest
from pathlib import Path
import server

class StudioTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        server.DB = str(Path(self.tmp.name) / 'test.sqlite3')
    def tearDown(self): self.tmp.cleanup()
    def event(self, name, event_id='event12345', **fields):
        return dict(id=event_id, player='player12345', session='session12345', game='merge-drift', environment='test', at=int(time.time()*1000), name=name, fields=fields)
    def test_deduplication_and_environment(self):
        e=self.event('run_start', run='run12345', level=7)
        server.ingest([e]); server.ingest([e])
        self.assertEqual(server.report('test',7)['events'],1)
        self.assertEqual(server.report('production',7)['events'],0)
    def test_final_rewarded_outcome_and_rule_losses(self):
        server.ingest([self.event('run_start',run='run12345',level=7), self.event('run_end','event12346',run='run12345',level=7,outcome='loss',reason='progression_rule')])
        self.assertEqual(server.report('test',7)['levels'][0]['ruleLosses'],1)
        server.ingest([self.event('run_end','event12347',run='run12345',level=7,outcome='win',reason='boost_goal')])
        report=server.report('test',7)
        self.assertEqual(report['games'][1]['wins'],1)
        self.assertEqual(report['games'][1]['finished'],1)
    def test_rejects_unknown_fields_and_bad_batches(self):
        with self.assertRaises(ValueError): server.ingest([self.event('run_start',email='private@example.com')])
        with self.assertRaises(ValueError): server.ingest([self.event('run_start')]*51)
        e=self.event('run_start'); e['at']=0
        with self.assertRaises(ValueError): server.ingest([e])

if __name__=='__main__': unittest.main()
