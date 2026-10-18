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

    def test_all_eight_games_and_nightfall_outcome(self):
        event=self.event('run_end',run='arena12345',score=500,outcome='win',wave=5)
        event['game']='nightfall-arena'
        server.ingest([event])
        report=server.report('test',7)
        self.assertEqual(len(report['games']),8)
        self.assertEqual(report['games'][3]['wins'],1)
        self.assertEqual(report['games'][3]['lastEvent'],event['at'])
        self.assertEqual(report['games'][7]['status'],'Planned')
        self.assertEqual(report['games'][7]['players'],0)
        self.assertEqual(server.report('production',7)['events'],0)

    def test_bad_numeric_fields_do_not_break_reports(self):
        for value in ['bad', float('nan'), float('inf'), -1, True]:
            with self.assertRaises(ValueError): server.ingest([self.event('session_active',seconds=value)])
    def test_run_ids_are_scoped_to_installation(self):
        a=self.event('run_end',run='same-run-id',outcome='win')
        b=self.event('run_end','event-other',run='same-run-id',outcome='loss'); b['player']='player-other'
        server.ingest([a,b])
        self.assertEqual(server.report('test',7)['games'][1]['finished'],2)

if __name__=='__main__': unittest.main()
