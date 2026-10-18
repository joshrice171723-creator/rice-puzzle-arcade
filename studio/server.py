"""Private studio reports and public, bounded gameplay ingestion. Python stdlib only."""
import json
import os
import re
import sqlite3
import time
from contextlib import contextmanager
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from urllib.parse import urlparse, parse_qs

ROOT = Path(__file__).parent
DB = os.environ.get('STUDIO_DB', str(ROOT / 'events.sqlite3'))
GAMES = ['grid-foundry', 'merge-drift', 'color-cascade']
NAMES = {'session_start', 'session_active', 'run_start', 'run_resume', 'run_end', 'run_exit', 'run_progress', 'boost_offer', 'boost_request', 'boost_earned', 'ad_request', 'ad_loaded', 'ad_shown', 'ad_closed', 'ad_earned', 'ad_failed'}
FIELDS = {'run', 'mode', 'level', 'score', 'moves', 'outcome', 'reason', 'rewardUsed', 'format', 'code', 'seconds', 'platform', 'version'}

@contextmanager
def connect():
    db = sqlite3.connect(DB)
    db.execute('CREATE TABLE IF NOT EXISTS events (id TEXT PRIMARY KEY, player TEXT, session TEXT, game TEXT, environment TEXT, at INTEGER, name TEXT, fields TEXT)')
    db.execute('CREATE INDEX IF NOT EXISTS events_period ON events(environment, at, game)')
    db.execute('DELETE FROM events WHERE at < ?', ((time.time()-90*86400)*1000,))
    try:
        with db:
            yield db
    finally:
        db.close()

def validate(event):
    if not isinstance(event, dict) or set(event) != {'id', 'player', 'session', 'game', 'environment', 'at', 'name', 'fields'}: return False
    if any(not isinstance(event[k], str) or not re.fullmatch(r'[A-Za-z0-9_-]{8,100}', event[k]) for k in ['id', 'player', 'session']): return False
    if event['game'] not in GAMES or event['environment'] not in ['test', 'production'] or event['name'] not in NAMES: return False
    if type(event['at']) is not int or not (time.time()*1000 - 8*86400000 <= event['at'] <= time.time()*1000+300000): return False
    fields = event['fields']
    return isinstance(fields, dict) and set(fields) <= FIELDS and all(type(v) in [str, int, float, bool] and (not isinstance(v, str) or len(v) <= 100) and (not isinstance(v, (int, float)) or abs(v) <= 1e12) for v in fields.values())

def ingest(batch):
    if not isinstance(batch, list) or not 1 <= len(batch) <= 50 or not all(validate(e) for e in batch): raise ValueError('Invalid event batch')
    with connect() as db:
        db.executemany('INSERT OR IGNORE INTO events VALUES (?,?,?,?,?,?,?,?)', [(e['id'], e['player'], e['session'], e['game'], e['environment'], e['at'], e['name'], json.dumps(e['fields'])) for e in batch])
        db.execute('DELETE FROM events WHERE at < ?', ((time.time()-90*86400)*1000,))
    return {'accepted': [e['id'] for e in batch]}

def report(environment, days):
    with connect() as db:
        rows = db.execute('SELECT player,session,game,at,name,fields FROM events WHERE environment=? AND at>=? ORDER BY at', (environment, (time.time()-days*86400)*1000)).fetchall()
    events = [dict(player=r[0], session=r[1], game=r[2], at=r[3], name=r[4], f=json.loads(r[5])) for r in rows]
    games = []
    levels = []
    daily = {}
    for e in events:
        day = time.strftime('%Y-%m-%d', time.gmtime(e['at']/1000))
        daily.setdefault(day, set()).add((e['game'], e['player']))
    for game in GAMES:
        es = [e for e in events if e['game'] == game]
        starts = [e for e in es if e['name'] == 'run_start']
        # A revived run may end twice. Use its final reported outcome once.
        ends = {e['f'].get('run'): e for e in es if e['name'] == 'run_end'}
        sessions = len({(e['player'], e['session']) for e in es})
        players = len({e['player'] for e in es})
        player_days = {}
        for e in es:
            player_days.setdefault(e['player'], set()).add(e['at'] // 86400000)
        returning = sum(len(days_seen) > 1 for days_seen in player_days.values())
        modes = {mode: sum(e['f'].get('mode') == mode for e in starts) for mode in ['normal', 'daily', 'journey']}
        wins = sum(e['f'].get('outcome') == 'win' for e in ends.values())
        ads = {name: sum(e['name'] == name for e in es) for name in ['ad_request', 'ad_loaded', 'ad_shown', 'ad_failed', 'boost_offer', 'boost_request', 'boost_earned']}
        seconds = sum(e['f'].get('seconds', 0) for e in es if e['name'] == 'session_active')
        games.append(dict(game=game, players=players, returning=returning, modes=modes, sessions=sessions, starts=len(starts), finished=len(ends), wins=wins, losses=len(ends)-wins, activeSeconds=seconds, best=max([e['f'].get('score', 0) for e in es] or [0]), **ads))
        for level in sorted({e['f']['level'] for e in starts if isinstance(e['f'].get('level'), int) and e['f']['level'] > 0}):
            ls = [e for e in starts if e['f'].get('level') == level]
            le = [e for e in ends.values() if e['f'].get('level') == level]
            levels.append(dict(game=game, level=level, attempts=len(ls), players=len({e['player'] for e in ls}), wins=sum(e['f'].get('outcome') == 'win' for e in le), losses=sum(e['f'].get('outcome') == 'loss' for e in le), ruleLosses=sum(e['f'].get('reason') == 'progression_rule' for e in le), unfinished=sum(e['f'].get('run') not in ends for e in ls)))
    return dict(environment=environment, days=days, generatedAt=int(time.time()*1000), events=len(events), games=games, levels=levels, daily=[dict(day=d, players=len(p)) for d,p in sorted(daily.items())], latest=[dict(game=e['game'], name=e['name'], at=e['at'], fields=e['f']) for e in events[-20:]][::-1])

class Handler(BaseHTTPRequestHandler):
    def log_message(self, *_): pass  # Do not retain player IP addresses in application logs.
    def reply(self, code, body, mime='application/json'):
        payload = json.dumps(body).encode() if mime == 'application/json' else body
        self.send_response(code)
        self.send_header('Content-Type', mime)
        self.send_header('Content-Length', str(len(payload)))
        self.send_header('Cache-Control', 'no-store')
        self.send_header('X-Content-Type-Options', 'nosniff')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.send_header('Access-Control-Allow-Methods', 'POST, OPTIONS')
        self.end_headers()
        self.wfile.write(payload)
    def do_OPTIONS(self): self.reply(200, {})
    def do_POST(self):
        if urlparse(self.path).path != '/games/api/events': return self.reply(404, {})
        try:
            size = int(self.headers.get('Content-Length', '0'))
            if not 0 < size <= 65536: return self.reply(413, {'error': 'Batch too large'})
            self.connection.settimeout(10)
            return self.reply(200, ingest(json.loads(self.rfile.read(size))))
        except (ValueError, TypeError): return self.reply(400, {'error': 'Invalid event batch'})
    def do_GET(self):
        url = urlparse(self.path)
        if url.path == '/games/health': return self.reply(200, {'status': 'ok'})
        if url.path == '/games/api/report':
            query = parse_qs(url.query)
            environment = query.get('environment', ['test'])[0]
            days = query.get('days', ['7'])[0]
            if environment not in ['test', 'production'] or days not in ['1', '7', '30', '90']: return self.reply(400, {})
            return self.reply(200, report(environment, int(days)))
        files = {'/games/': ('index.html', 'text/html; charset=utf-8'), '/games': ('index.html', 'text/html; charset=utf-8'), '/games/dashboard.js': ('dashboard.js', 'text/javascript'), '/games/style.css': ('style.css', 'text/css')}
        if url.path not in files: return self.reply(404, {})
        file, mime = files[url.path]
        self.reply(200, (ROOT / file).read_bytes(), mime)

if __name__ == '__main__':
    # Public reports MUST sit behind the supplied authenticated reverse proxy.
    HTTPServer(('127.0.0.1', int(os.environ.get('PORT', '8090'))), Handler).serve_forever()
