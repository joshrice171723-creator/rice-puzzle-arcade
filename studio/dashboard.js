let catalog = [], titles = {};
const desktop = window.studioDesktop;
const colors = ['#e9bc72','#8ecedf','#e7a2bd','#b2d18d','#bfa2e7','#f09d7b','#c9ba8c','#84c5b1'];
const $ = id => document.getElementById(id);
const fmt = n => Number(n).toLocaleString();
const rate = (n,d) => d ? `${Math.round(n/d*100)}%` : '—';
let current, busy = false, pending = false;
function renderLevels(){
  const rows=current.levels.filter(l=>$('game').value==='all'||l.game===$('game').value);
  $('levelRows').innerHTML=rows.map(l=>`<tr><td>${titles[l.game]} / Z${Math.ceil(l.level/10)} · L${(l.level-1)%10+1}</td>${['players','attempts','wins','losses','ruleLosses','unfinished'].map(k=>`<td>${fmt(l[k])}</td>`).join('')}</tr>`).join('')||'<tr><td colspan="7" class="empty">No level attempts received for this selection.</td></tr>';
}
async function refresh(){
  if (busy) { pending = true; return; } busy = true;
  $('status').textContent='Refreshing…';
  try{
    let report;
    if (desktop) report = await desktop.report($('environment').value, Number($('days').value));
    else { const r=await fetch(`/games/api/report?environment=${$('environment').value}&days=${$('days').value}`, {signal:AbortSignal.timeout(15000)}); if(!r.ok)throw Error(r.status === 401 ? 'SIGN_IN' : 'Connection failed'); report=await r.json(); }
    current=report;
    // Include planned titles even when connected to an older collector version.
    current.games = catalog.map(item => ({game:item.id,players:0,returning:0,sessions:0,starts:0,finished:0,wins:0,losses:0,activeSeconds:0,best:0,ad_loaded:0,ad_request:0,ad_shown:0,ad_failed:0,boost_request:0,boost_offer:0,boost_earned:0,modes:{normal:0,daily:0,journey:0}, ...current.games.find(g=>g.game===item.id), ...item}));
    $('login').hidden = true;
    $('signout').hidden = !desktop;
    const sum=k=>current.games.reduce((n,g)=>n+g[k],0);
    $('overview').innerHTML=[['Active installations',fmt(sum('players')),'Across the portfolio'],['Runs started',fmt(sum('starts')),'New attempts in this period'],['Completed-run win rate',rate(sum('wins'),sum('finished')),'Wins / final reported outcomes'],['Boosts earned',fmt(sum('boost_earned')),'Confirmed rewards applied']].map(([l,n,h])=>`<div class="metric"><span>${l}</span><strong>${n}</strong><small>${h}</small></div>`).join('');
    const max=Math.max(...current.daily.map(d=>d.players),1);
    $('pulse').innerHTML=current.daily.map(d=>`<div class="day" title="${d.day}: ${d.players}">${d.players}<div class="bar" style="height:${d.players/max*95}px"></div>${d.day.slice(5)}</div>`).join('')||'<div class="empty">Waiting for gameplay. Open a connected game to begin collecting test activity.</div>';
    $('portfolio').innerHTML=current.games.map((g,i)=>`<article class="game" style="--color:${colors[i]}"><span class="tag">0${i+1} / ${g.status.toUpperCase()} · ${g.category}</span><h3>${titles[g.game]}</h3>${[['Installations',fmt(g.players)],['Sessions',fmt(g.sessions)],['Last activity received',g.lastEvent?new Date(g.lastEvent).toLocaleString():'None yet'],['Active on 2+ UTC days',fmt(g.returning)],['Free / daily / journey',`${g.modes.normal} / ${g.modes.daily} / ${g.modes.journey}`],['Runs / session',g.sessions?(g.starts/g.sessions).toFixed(1):'—'],['Active play',`${Math.round(g.activeSeconds/60)} min`],['Wins / losses',`${g.wins} / ${g.losses}`],['Best score',fmt(g.best)],['Ad loads / requests',`${g.ad_loaded} / ${g.ad_request}`],['Ads shown / failures',`${g.ad_shown} / ${g.ad_failed}`],['Boost requests / offers',`${g.boost_request} / ${g.boost_offer}`],['Boosts earned',fmt(g.boost_earned)]].map(([l,v])=>`<div class="stat"><span>${l}</span><b>${v}</b></div>`).join('')}<p>${g.starts?'Compare level losses and unfinished runs below before changing difficulty.':g.status==='Planned'?'Planned · tracking begins when this game is built.':'No runs received yet.'}</p></article>`).join('');
    renderLevels();
    $('feed').replaceChildren();
    for(const e of current.latest){const row=document.createElement('div');row.className='feed-row';for(const t of [titles[e.game],e.name.replaceAll('_',' '),e.fields.level?`Level ${e.fields.level}`:'']){const span=document.createElement('span');span.textContent=t;row.append(span);}const time=document.createElement('time');time.textContent=new Date(e.at).toLocaleString();row.append(time);$('feed').append(row);}
    $('status').textContent=`${current.environment.toUpperCase()} · connected · updated ${new Date(current.generatedAt).toLocaleTimeString()} · refreshes every 30s`;
  }catch(error){
    const login = String(error.message).includes('SIGN_IN');
    $('login').hidden = !(login && desktop);
    $('status').textContent=login?'Sign in required':`Offline · ${current ? 'showing '+current.environment+' report from '+new Date(current.generatedAt).toLocaleTimeString() : 'no report loaded'} · retry`;
  } finally { busy = false; if (pending) { pending = false; void refresh(); } }
}
for(const id of ['environment','days'])$(id).addEventListener('change',refresh);
$('game').addEventListener('change',()=>current&&renderLevels());$('refresh').addEventListener('click',refresh);
$('export').addEventListener('click',()=>{if(!current)return;const url=URL.createObjectURL(new Blob([JSON.stringify(current,null,2)],{type:'application/json'}));const a=document.createElement('a');a.href=url;a.download=`studio-${current.environment}-${Date.now()}.json`;a.click();URL.revokeObjectURL(url);});
$('loginForm').addEventListener('submit',async event=>{event.preventDefault(); $('loginError').textContent='Connecting…'; try { await desktop.login($('username').value,$('password').value); $('password').value=''; $('loginError').textContent=''; await refresh(); } catch { $('loginError').textContent='Could not sign in. Check your login and connection.'; }});
$('signout').addEventListener('click',async()=>{await desktop.logout(); current=undefined; for(const id of ['overview','portfolio','pulse','levelRows','feed'])$(id).replaceChildren(); $('signout').hidden=true; await refresh();});
async function initialize(){
  if (desktop) catalog=await desktop.catalog();
  else { const response=await fetch('./catalog.json'); catalog=await response.json(); }
  titles=Object.fromEntries(catalog.map(g=>[g.id,g.title]));
  $('game').replaceChildren(new Option('All games','all'),...catalog.map(g=>new Option(g.title,g.id)));
  await refresh();
}
initialize().catch(()=>{$('status').textContent='Could not load the game catalog. Reopen the app.';});setInterval(()=>{if(!document.hidden)refresh();},30000);
