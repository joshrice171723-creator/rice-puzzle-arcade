const titles = {'grid-foundry':'Grid Foundry','merge-drift':'Merge Drift','color-cascade':'Color Cascade'};
const colors = ['#e9bc72','#8ecedf','#e7a2bd'];
const $ = id => document.getElementById(id);
const fmt = n => Number(n).toLocaleString();
const rate = (n,d) => d ? `${Math.round(n/d*100)}%` : '—';
let current;
function renderLevels(){
  const rows=current.levels.filter(l=>$('game').value==='all'||l.game===$('game').value);
  $('levelRows').innerHTML=rows.map(l=>`<tr><td>${titles[l.game]} / Z${Math.ceil(l.level/10)} · L${(l.level-1)%10+1}</td>${['players','attempts','wins','losses','ruleLosses','unfinished'].map(k=>`<td>${fmt(l[k])}</td>`).join('')}</tr>`).join('')||'<tr><td colspan="7" class="empty">No level attempts received for this selection.</td></tr>';
}
async function refresh(){
  $('status').textContent='Refreshing…';
  try{
    const r=await fetch(`/games/api/report?environment=${$('environment').value}&days=${$('days').value}`);
    if(!r.ok)throw Error();
    current=await r.json();
    const sum=k=>current.games.reduce((n,g)=>n+g[k],0);
    $('overview').innerHTML=[['Active installations',fmt(sum('players')),'Across the three games'],['Runs started',fmt(sum('starts')),'New attempts in this period'],['Completed-run win rate',rate(sum('wins'),sum('finished')),'Wins / final reported outcomes'],['Boosts earned',fmt(sum('boost_earned')),'Confirmed rewards applied']].map(([l,n,h])=>`<div class="metric"><span>${l}</span><strong>${n}</strong><small>${h}</small></div>`).join('');
    const max=Math.max(...current.daily.map(d=>d.players),1);
    $('pulse').innerHTML=current.daily.map(d=>`<div class="day" title="${d.day}: ${d.players}">${d.players}<div class="bar" style="height:${d.players/max*95}px"></div>${d.day.slice(5)}</div>`).join('')||'<div class="empty">Waiting for gameplay. Open a connected game to begin collecting test activity.</div>';
    $('portfolio').innerHTML=current.games.map((g,i)=>`<article class="game" style="--color:${colors[i]}"><span class="tag">0${i+1} / ${current.environment.toUpperCase()}</span><h3>${titles[g.game]}</h3>${[['Installations',fmt(g.players)],['Sessions',fmt(g.sessions)],['Active on 2+ UTC days',fmt(g.returning)],['Free / daily / journey',`${g.modes.normal} / ${g.modes.daily} / ${g.modes.journey}`],['Runs / session',g.sessions?(g.starts/g.sessions).toFixed(1):'—'],['Active play',`${Math.round(g.activeSeconds/60)} min`],['Wins / losses',`${g.wins} / ${g.losses}`],['Best score',fmt(g.best)],['Ad loads / requests',`${g.ad_loaded} / ${g.ad_request}`],['Ads shown / failures',`${g.ad_shown} / ${g.ad_failed}`],['Boost requests / offers',`${g.boost_request} / ${g.boost_offer}`],['Boosts earned',fmt(g.boost_earned)]].map(([l,v])=>`<div class="stat"><span>${l}</span><b>${v}</b></div>`).join('')}<p>${g.starts?'Compare level losses and unfinished runs below before changing difficulty.':'No runs received yet.'}</p></article>`).join('');
    renderLevels();
    $('feed').replaceChildren();
    for(const e of current.latest){const row=document.createElement('div');row.className='feed-row';for(const t of [titles[e.game],e.name.replaceAll('_',' '),e.fields.level?`Level ${e.fields.level}`:'']){const span=document.createElement('span');span.textContent=t;row.append(span);}const time=document.createElement('time');time.textContent=new Date(e.at).toLocaleString();row.append(time);$('feed').append(row);}
    $('status').textContent=`Updated ${new Date().toLocaleTimeString()}`;
  }catch{$('status').textContent='Connection failed · retry';}
}
for(const id of ['environment','days'])$(id).addEventListener('change',refresh);
$('game').addEventListener('change',()=>current&&renderLevels());$('refresh').addEventListener('click',refresh);
$('export').addEventListener('click',()=>{if(!current)return;const url=URL.createObjectURL(new Blob([JSON.stringify(current,null,2)],{type:'application/json'}));const a=document.createElement('a');a.href=url;a.download=`studio-${current.environment}-${Date.now()}.json`;a.click();URL.revokeObjectURL(url);});
refresh();setInterval(()=>{if(!document.hidden)refresh();},30000);
