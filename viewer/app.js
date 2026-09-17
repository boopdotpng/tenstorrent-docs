'use strict';
const $ = (s, el = document) => el.querySelector(s);
const esc = value => String(value ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const docURL = (path, repo='docs', anchor='') => {
 if(repo==='docs' && index?.redirects?.[path]){
  const [replacement,section]=index.redirects[path].split('#');path=replacement;anchor=section ? section+(anchor?'--'+anchor:'') : '';
 }
 const base=repo==='docs' && index?.documents.some(d=>d.path===path&&d.historical)?'/archives':'/';
 return `${base}#/docs/${encodeURIComponent(repo)}/${encodeURIComponent(path)}${anchor ? '?h='+encodeURIComponent(anchor) : ''}`;
};
const opURL = name => '/isa#/instructions/'+encodeURIComponent(name);
const assetURL = (repo,path) => '/api/asset?'+new URLSearchParams({repo,path});
const main = $('#main');
let reference, index, routeVersion = 0, searchVersion = 0;

const categories = {'Start here':'Start here','hardware':'Hardware','emulator':'Emulator models','kernel-dev':'Kernel development','build-and-dispatch':'Build & dispatch','firmware':'Firmware','matmul':'Matrix multiplication','compiler-maps':'Compiler foundations','compiler-tinygrad':'tinygrad compiler','compiler-pytorch':'PyTorch compiler','compiler-mlir':'MLIR','compiler-iree':'IREE','compiler-tt-mlir':'TT-MLIR','tinygrad':'tinygrad','microbenching':'Measurements','llk-sfpi':'ISA workload studies','multi-chip':'Multi-chip','archive':'Archive index','archive-tinygrad':'Earlier tinygrad studies','archive-matmul':'Earlier matmul results','archive-build-and-dispatch':'Retired runtime studies','benchmark-noc':'NoC measurements','benchmark-tensix':'Tensix measurements','maintenance':'Maintenance','disasms':'Disassemblies','human':'Human notes'};
const slug = text => text.toLowerCase().replace(/[^\p{L}\p{N}\s_-]/gu,'').replace(/\s/g,'-');
async function json(url) { const r = await fetch(url); const data = await r.json(); if (!r.ok) throw new Error(data.error || `HTTP ${r.status}`); return data; }
function md(text) { return DOMPurify.sanitize(marked.parse(text || ''), {FORBID_TAGS:['style','form','input','button'], FORBID_ATTR:['style']}); }
function sourceLink(source, label='Source') {
 if (!source) return '';
 if (/^https?:/.test(source)) return `<a href="${esc(source)}" target="_blank" rel="noopener noreferrer">${esc(label)}</a>`;
 const split = source.indexOf(':');
 const repo = split > 0 ? source.slice(0,split) : 'docs', path = split > 0 ? source.slice(split+1) : source;
 return `<a href="${docURL(path,repo)}">${esc(label)}</a>`;
}
function hydrate(container, repo, path) {
 const base = `https://workspace.invalid/${repo}/${path}`;
 container.querySelectorAll('a[href],img[src]').forEach(el => {
  const attr = el.tagName==='IMG'?'src':'href', raw = el.getAttribute(attr);
  if (/^(https?:|mailto:|data:)/i.test(raw)) {if(el.tagName==='A'){el.rel='noopener noreferrer';el.target='_blank';}return;}
  if (raw.startsWith('#/')) return;
  try {
   const url = new URL(raw,base), segments = url.pathname.slice(1).split('/').map(decodeURIComponent);
   const destRepo = segments.shift(), destPath = segments.join('/');
   if (!index.repositories.includes(destRepo)) return;
   if(el.tagName==='IMG') el.src = assetURL(destRepo,destPath);
   else if(/\.(svg|png|jpe?g|gif|webp|pdf)$/i.test(destPath)){el.href=assetURL(destRepo,destPath);el.target='_blank';el.rel='noopener';}
   else el.href=docURL(destPath,destRepo,decodeURIComponent(url.hash.slice(1)));
  } catch (_) { /* Keep an unresolvable link visible rather than guessing its target. */ }
 });
 const used = new Map();
 container.querySelectorAll('h1,h2,h3,h4,h5,h6').forEach(h=>{const id=slug(h.textContent),count=used.get(id)||0;used.set(id,count+1);h.id=id+(count?'-'+count:'');});
}
function toast(message) { $('#toast').textContent=message;$('#toast').classList.add('show');setTimeout(()=>$('#toast').classList.remove('show'),1800); }
function badge(text, style='') {return `<span class="badge ${style}">${esc(text)}</span>`;}
function timingStyle(op) {return /unknown|reserved|estimate|inference/.test(op.timing_status)?'warn':'';}
function archiveRoute() {
 if(location.pathname.startsWith('/archives')||location.hash.startsWith('#/archives'))return true;
 return index.documents.some(d=>d.historical && location.pathname+location.hash.split('?')[0]===docURL(d.path));
}
function nav() {
 if(location.pathname.startsWith('/isa')){
  $('#library-heading').textContent='INSTRUCTIONS';
  $('#doc-nav').setAttribute('aria-label','Instruction navigation');
  const groups=new Map();
  for(const op of reference.instructions){if(!groups.has(op.group))groups.set(op.group,[]);groups.get(op.group).push(op);}
  $('#doc-nav').innerHTML=[...groups].map(([name,ops])=>`<details open><summary>${esc(name)}</summary>${ops.map(op=>`<a href="${opURL(op.name)}">${op.name}</a>`).join('')}</details>`).join('');
  activeNav();return;
 }
 const archives=archiveRoute();
 $('#doc-nav').setAttribute('aria-label',archives?'Archive library':'Documentation library');
 $('#library-heading').textContent=archives?'ARCHIVES':'DOCUMENTATION';
 const grouped = new Map();
 for(const doc of index.documents){if(doc.historical!==archives)continue;if(!grouped.has(doc.category))grouped.set(doc.category,[]);grouped.get(doc.category).push(doc);}
 $('#doc-nav').innerHTML=[...grouped].sort((a,b)=>Object.keys(categories).indexOf(a[0])-Object.keys(categories).indexOf(b[0])).map(([category,docs])=>`<details ${['Start here','hardware'].includes(category)?'open':''}><summary>${esc(categories[category]||category)} <span class="small">${docs.length}</span></summary>${docs.map(d=>`<a href="${docURL(d.path)}" title="${esc(d.path)}">${esc(d.title)}</a>`).join('')}</details>`).join('');
 activeNav();
}
function activeNav(){
 const current=location.pathname+location.hash;
 document.querySelectorAll('#sidebar a').forEach(a=>{
  const href=a.getAttribute('href');
  const active=a.dataset.nav ? a.dataset.nav===(location.pathname.startsWith('/isa')?'instructions':archiveRoute()?'archives':'documents') : href===current.split('?')[0];
  a.classList.toggle('active',active);
  if(active){a.setAttribute('aria-current','page');const parent=a.closest('details');if(parent)parent.open=true;}else a.removeAttribute('aria-current');
 });
}
function instructionList(params) {
 main.innerHTML=`<h1>Tensix instructions</h1><div class="toolbar"><div class="search-box"><input id="op-search" aria-label="Search instructions" placeholder="Search instructions…" value="${esc(params.get('q')||'')}"></div><select id="unit-filter" aria-label="Filter by execution unit"><option value="">All execution units</option>${[...new Set(reference.instructions.map(x=>x.group))].sort().map(x=>`<option>${esc(x)}</option>`).join('')}</select><select id="evidence-filter" aria-label="Filter by evidence"><option value="">All evidence</option><option value="measured">Has timing probes</option><option value="partial">Has behavioral claims</option><option value="uncertain">Estimated / unknown timing</option></select></div><div id="op-results" aria-live="polite"></div>`;
 const render=()=>{const query=$('#op-search').value.toLowerCase().replace(/^tt_?/,''),unit=$('#unit-filter').value,evidence=$('#evidence-filter').value;
 const filtered=reference.instructions.filter(op=>(!unit||op.group===unit)&&(!evidence||(evidence==='measured'?op.observations.length:evidence==='partial'?op.contracts.length:timingStyle(op)))&&query.split(/\s+/).every(t=>JSON.stringify([op.name,op.opcode,op.overview,op.group,op.caveats,op.contracts,op.timing]).toLowerCase().includes(t)));
 $('#op-results').innerHTML=`<p class="result-count">${filtered.length} / ${reference.instructions.length} INSTRUCTIONS</p>`+(filtered.length?`<div class="table-wrap"><table class="instruction-table"><thead><tr><th>Instruction</th><th>Unit</th><th>Result latency</th><th>Issue spacing</th><th>Timing basis</th></tr></thead><tbody>${filtered.map(op=>`<tr><td><a href="${opURL(op.name)}">${op.name}</a><span class="subtext">${op.opcode}${op.observations.length?' · measured probes':''}</span></td><td>${esc(op.group)}</td><td>${esc(op.timing[0]?.latency||'unknown')}</td><td>${esc(op.timing[0]?.issue_interval||'unknown')}</td><td>${badge(op.timing_status,timingStyle(op))}</td></tr>`).join('')}</tbody></table></div>`:'<div class="empty"><h2>No matching instructions</h2><p>Try an opcode or clear the unit and evidence filters.</p></div>');};
 for(const sel of ['#op-search','#unit-filter','#evidence-filter'])$(sel).addEventListener('input',render);render();
}
function instructionDetail(name) {
 const op=reference.instructions.find(x=>x.name===name.toUpperCase());if(!op)throw new Error('Unknown instruction: '+name);
 const t=op.timing[0]||{};
 main.innerHTML=`<div class="eyebrow"><a href="/isa">Instruction reference</a> / ${esc(op.group)}</div><div class="detail-head"><div><h1>${op.name}</h1><p class="metadata">OPCODE ${op.opcode} · ${esc(op.resource)} · BLACKHOLE A0</p></div><button class="button" id="copy-link">Copy link</button></div>
 <div class="detail-layout"><article><div class="markdown" id="op-overview">${md(op.overview)}</div><p class="small">${op.overview_source?sourceLink(op.overview_source,'Manual summary'):'Source-derived synopsis'} · ${badge(op.behavior==='partial'?'Partial behavioral coverage':'No reviewed behavioral claim',op.behavior==='partial'?'':'muted')}</p>
 <div class="stats timing-stats"><div class="stat"><strong>${esc(t.latency||'unknown')}</strong><span>Result / service cycles</span></div><div class="stat"><strong>${esc(t.issue_interval||'unknown')}</strong><span>Issue spacing in cycles</span></div><div class="stat"><strong>${op.observations.length}</strong><span>Attached timing probe records</span></div></div>
 <h2 id="timing">Timing and scheduling</h2><p>${badge(op.timing_status,timingStyle(op))}</p>${op.timing.map(row=>`<div class="note ${timingStyle(op)}">${esc(row.note)}<br>${sourceLink(row.source,'Pinned timing source')}</div>`).join('')}
 ${op.observations.length?`<h3>Measured loop slopes</h3><p class="small">Cycles per body operation, measured through completion. These are not isolated result latencies. No empty-loop subtraction.</p><div class="table-wrap"><table><thead><tr><th>Probe / role</th><th>Slopes</th><th>Placement</th></tr></thead><tbody>${op.observations.map(x=>`<tr><td><code>${esc(x.case)}</code><span class="subtext">${esc(x.role)}</span></td><td>${x.slopes.map(v=>Number(v).toFixed(3)).join(' / ')}</td><td>Card ${x.card} · (${x.core.join(', ')})</td></tr>`).join('')}</tbody></table></div><details><summary class="small">Completion boundary and measurement details</summary>${op.observations.map(x=>`<div class="contract"><h3>${esc(x.case)} · ${esc(x.role)}</h3><p>${esc(x.completion)}</p><p>${esc(x.semantics)}</p><p class="metadata">${esc(x.configuration)}<br>${esc(x.loop)}<br>${x.samples_per_point} retained samples at each length</p><details><summary>Raw retained cycle samples</summary><pre>${esc(JSON.stringify(x.points,null,2))}</pre></details>${sourceLink(x.source,'Raw evidence')}</div>`).join('')}</details>`:'<p class="small">No dedicated probe record is attached for this instruction. The timing basis above may be a manual rule, estimate, or workload-dependent model.</p>'}
 <h2 id="caveats">Caveats and boundaries</h2>${op.caveats.length?op.caveats.map(c=>`<div class="note warn"><strong>${esc(c.title)}</strong><div class="markdown manual-caveat">${md(c.text)}</div></div>`).join(''):'<p class="small">No additional scheduling excerpt is attached. Read the full instruction contract and the test gaps below; this does not mean the instruction has no hazards.</p>'}
 <h2 id="tests">What blackhole-py tests</h2>${op.contracts.length?op.contracts.map(c=>`<section class="contract"><h3>${esc(c.id)}</h3><p>${esc(c.assertion)}</p><p class="gap"><strong>Not established:</strong> ${esc(c.gaps)}</p><div class="test-links">${c.tests.map(test=>`<div><a href="${docURL(test.path,'blackhole-py',test.line?'L'+test.line:'')}">${esc(test.selector)}</a>${test.source_status!=='matches audit'?` ${badge('source changed / unavailable','warn')}`:''}</div>`).join('')}</div><details><summary>Recorded evidence scope</summary><p>${esc(c.evidence_scope)}</p><p>${esc(JSON.stringify(c.evidence))}</p></details></section>`).join(''):'<div class="note warn">The audit records no reviewed behavioral claim for this opcode. Encoding checks and appearances in helper code do not establish functional coverage.</div>'}
 <h2 id="encoding">Syntax and encoding</h2>${op.syntax?`<pre><code>${esc(op.syntax)}</code></pre>`:''}<p class="small">LLK encoder fields below may include reserved bits. Field width is not a guarantee that every encoded value is supported behavior.</p><div class="table-wrap"><table><thead><tr><th>Encoder parameter</th><th>Bits</th></tr></thead><tbody>${op.encoding.map(f=>`<tr><td><code>${esc(f.parameter)}</code></td><td>${f.hi===f.lo?f.lo:f.hi+'..'+f.lo}</td></tr>`).join('')}</tbody></table></div>
 <h2 id="sources">Read further</h2><div class="doc-list">${op.manual?`<p>${sourceLink('tt-isa-documentation:'+op.manual,'Full instruction manual')} <span class="small">${op.blackhole_contract?'Blackhole page':'Shared / inherited source; check architecture qualifications'}</span></p>`:''}${op.documents.map(d=>`<a href="${docURL(d.path)}">${esc(d.title)}</a>`).join('')}</div><details><summary class="small">Source sightings (navigation, not coverage)</summary>${op.sightings.map(([path,line])=>`<div>${sourceLink('blackhole-py:'+path,path+':'+line)}</div>`).join('')||'<p>No static sightings in the audit.</p>'}</details>
 <hr><p class="metadata">Timing snapshot ${reference.timing_date} · blackhole-py ${reference.blackhole_py_commit.slice(0,12)} + local changes<br>${esc(reference.scope)}</p></article><nav class="toc" aria-label="On this page"><strong>ON THIS PAGE</strong>${[['timing','Timing & scheduling'],['caveats','Caveats'],['tests','Tests & coverage'],['encoding','Syntax & encoding'],['sources','Read further']].map(([id,title])=>`<a href="/isa#/instructions/${op.name}?h=${id}">${title}</a>`).join('')}<hr>${sourceLink('blackhole-py:tests/timing/README.md','Timing methodology')}</nav></div>`;
 hydrate($('#op-overview'), 'tt-isa-documentation', op.manual||'README.md');
 document.querySelectorAll('.manual-caveat').forEach(el=>hydrate(el,'tt-isa-documentation',op.manual||'README.md'));
 $('#copy-link').onclick=async()=>{try{await navigator.clipboard.writeText(location.href);toast('Link copied');}catch(_){toast('Copy the URL from your address bar');}};
}
function documentList(params,global=false,archives=false){
 main.innerHTML=`<h1>${global?'Search':archives?'Archives':'Documentation'}</h1><div class="toolbar"><div class="search-box"><input id="doc-search" aria-label="Search documentation" placeholder="Search all document text…" value="${esc(params.get('q')||'')}"></div></div><div id="doc-results" aria-live="polite"></div>`;
 let timer;
 const render=async()=>{const version=++searchVersion,query=$('#doc-search').value.trim(),scope=global?'all':archives?'archives':'documents';let docs=index.documents.filter(d=>global||d.historical===archives);
 try{if(query)docs=await json('/api/search?'+new URLSearchParams({q:query,scope}));if(version!==searchVersion||!$('#doc-results'))return;
 if(!query)docs.sort((a,b)=>Object.keys(categories).indexOf(a.category)-Object.keys(categories).indexOf(b.category)||a.path.localeCompare(b.path));
 const ops=global&&query?reference.instructions.filter(x=>JSON.stringify([x.name,x.overview,x.contracts]).toLowerCase().includes(query.toLowerCase())).slice(0,12):[];
 $('#doc-results').innerHTML=(ops.length?`<h2>Instructions</h2><div class="inline-links">${ops.map(x=>`<a class="button" href="${opURL(x.name)}">${x.name}</a>`).join('')}</div>`:'')+`<p class="result-count">${docs.length} DOCUMENT${docs.length===1?'':'S'}${query&&docs.length===60?' · FIRST 60 MATCHES':''}</p><div class="doc-list">${docs.map((d,i)=>`${!query && !global && (!i||docs[i-1].category!==d.category)?`<h2>${esc(categories[d.category]||d.category)}</h2>`:''}<article class="doc-result"><h3><a href="${docURL(d.path)}">${esc(d.title)}</a> ${d.historical?badge('historical','muted'):''}</h3><code>${esc(d.path)}</code>${d.excerpt?`<p>${esc(d.excerpt)}</p>`:''}</article>`).join('')||'<div class="empty">No matching documents. Try fewer words.</div>'}</div>`;
 }catch(error){if(version===searchVersion)$('#doc-results').textContent=error.message;}};
 $('#doc-search').oninput=()=>{clearTimeout(timer);timer=setTimeout(render,150);};render();if(global)$('#doc-search').focus();
}
async function documentPage(repo,path,version){
 const data=await json('/api/document?'+new URLSearchParams({repo,path}));if(version!==routeVersion)return;
 main.innerHTML=`<div class="eyebrow">${esc(repo==='docs'?(categories[path.split('/')[0]]||'Documentation'):repo)}</div><p class="metadata">${esc(path)}</p><div class="detail-layout"><article class="markdown" id="doc-content"></article><nav class="toc" id="doc-toc" aria-label="On this page"><strong>ON THIS PAGE</strong></nav></div>`;
 if(data.format==='markdown'){
  $('#doc-content').innerHTML=md(data.content);hydrate($('#doc-content'),repo,path);
  $('#doc-toc').innerHTML+=[...$('#doc-content').querySelectorAll('h2,h3')].slice(0,35).map(h=>`<a href="${docURL(path,repo,h.id)}">${esc(h.textContent)}</a>`).join('');
 }else{$('#doc-content').innerHTML=`<pre class="source-lines">${data.content.split('\n').map((line,i)=>`<span id="L${i+1}">${esc(line)}</span>`).join('')}</pre>`;$('#doc-toc').remove();}
 document.title=(data.format==='markdown'?$('#doc-content h1')?.textContent||path:path.split('/').pop())+' · Blackhole';
}
async function route(){
 const version=++routeVersion;searchVersion++;document.body.classList.remove('menu-open');nav();
 const raw=(location.hash.slice(1)||(location.pathname.startsWith('/isa')?'/instructions':location.pathname.startsWith('/archives')?'/archives':'/documents')),[pathname,query='']=raw.split('?'),parts=pathname.split('/').filter(Boolean).map(decodeURIComponent),params=new URLSearchParams(query);
 $('#breadcrumb').textContent=parts[0]==='instructions'?`Reference / ${parts[1]||'Tensix instruction set'}`:parts[0]==='docs'?parts[2]:'Blackhole / '+(parts[0]||'Overview');document.title=location.pathname.startsWith('/isa')?'Tensix ISA · Blackhole':'Blackhole docs';
 try{
  if(parts[0]==='instructions'&&!location.pathname.startsWith('/isa')){location.replace('/isa'+location.hash);return;}
  if(parts[0]==='archives'&&!location.pathname.startsWith('/archives')){location.replace('/archives');return;}
  if(parts[0]==='instructions'){if(parts[1])instructionDetail(parts[1]);else instructionList(params);}
  else if(parts[0]==='documents')documentList(params);
  else if(parts[0]==='archives')documentList(params,false,true);
  else if(parts[0]==='search')documentList(params,true);
  else if(parts[0]==='docs'){
   const canonical=docURL(parts[2],parts[1],params.get('h')||'');
   if(location.pathname+location.hash!==canonical){location.replace(canonical);return;}
   await documentPage(parts[1],parts[2],version);
  }
  else documentList(params);
  if(version!==routeVersion)return;
  const anchor=params.get('h');if(anchor){const el=document.getElementById(anchor);if(el){el.scrollIntoView();if(/^L\d+$/.test(anchor))el.classList.add('highlight');}}else window.scrollTo(0,0);
 }catch(error){if(version!==routeVersion)return;main.innerHTML=`<div class="empty"><h1>Unable to open this page</h1><p>${esc(error.message)}</p><p>Source links require the named sibling checkout. The instruction snapshot and this repository’s docs work on their own.</p><a class="button" href="/isa">Instruction reference</a></div>`;}
}
(async()=>{
 try{
  document.documentElement.dataset.theme=localStorage.getItem('bh-theme') || 'dark';
  [reference,index]=await Promise.all([json('/api/instructions'),json('/api/index')]);
  $('#instruction-count').textContent=reference.instructions.length;nav();
  $('#theme-toggle').onclick=()=>{const theme=document.documentElement.dataset.theme==='dark'?'light':'dark';document.documentElement.dataset.theme=theme;localStorage.setItem('bh-theme',theme);};
  $('#menu-toggle').onclick=()=>document.body.classList.toggle('menu-open');
  document.addEventListener('keydown',e=>{if(e.key==='/'&&!['INPUT','TEXTAREA','SELECT'].includes(document.activeElement.tagName)){e.preventDefault();if(location.hash==='#/search')$('#doc-search')?.focus();else location.href='/#/search';}if(e.key==='Escape')document.body.classList.remove('menu-open');});
  window.addEventListener('hashchange',route);route();
 }catch(error){main.innerHTML=`<div class="empty"><h1>Reference unavailable</h1><p>${esc(error.message)}</p></div>`;}
})();
