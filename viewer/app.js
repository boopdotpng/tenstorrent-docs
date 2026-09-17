'use strict';
const $ = (s, el = document) => el.querySelector(s);
const esc = value => String(value ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const docURL = (path, repo='docs', anchor='') => `#/docs/${encodeURIComponent(repo)}/${encodeURIComponent(path)}${anchor ? '?h='+encodeURIComponent(anchor) : ''}`;
const opURL = name => '#/instructions/'+encodeURIComponent(name);
const assetURL = (repo,path) => '/api/asset?'+new URLSearchParams({repo,path});
const main = $('#main');
let reference, index, routeVersion = 0, searchVersion = 0;
let showHistory = localStorage.getItem('bh-history') !== 'false';
const categories = {'Start here':'Start here','hardware':'Hardware','kernel-dev':'Kernel development','build-and-dispatch':'Build & dispatch','firmware':'Firmware','matmul':'Matrix multiplication','compiler-maps':'Compiler maps','tinygrad':'tinygrad','microbenching':'Measurements','llk-sfpi':'ISA workload studies','multi-chip':'Multi-chip','archive':'Historical studies','maintenance':'Maintenance','disasms':'Disassemblies','human':'Human notes'};
const slug = text => text.toLowerCase().replace(/[^\p{L}\p{N}\s_-]/gu,'').replace(/\s/g,'-');
async function json(url) { const r = await fetch(url); const data = await r.json(); if (!r.ok) throw new Error(data.error || `HTTP ${r.status}`); return data; }
function md(text) { return DOMPurify.sanitize(marked.parse(text || ''), {FORBID_TAGS:['style','form','input','button'], FORBID_ATTR:['style']}); }
function sourceLink(source, label='Source') {
 if (!source) return '';
 if (/^https?:/.test(source)) return `<a href="${esc(source)}" target="_blank" rel="noopener noreferrer">${esc(label)} ↗</a>`;
 const split = source.indexOf(':');
 const repo = split > 0 ? source.slice(0,split) : 'docs', path = split > 0 ? source.slice(split+1) : source;
 return `<a href="${docURL(path,repo)}">${esc(label)} →</a>`;
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
function nav() {
 const grouped = new Map();
 for(const doc of index.documents){if(!showHistory && doc.historical)continue;if(!grouped.has(doc.category))grouped.set(doc.category,[]);grouped.get(doc.category).push(doc);}
 $('#doc-nav').innerHTML=[...grouped].sort((a,b)=>Object.keys(categories).indexOf(a[0])-Object.keys(categories).indexOf(b[0])).map(([category,docs])=>`<details ${['Start here','hardware'].includes(category)?'open':''}><summary>${esc(categories[category]||category)} <span class="small">${docs.length}</span></summary>${docs.map(d=>`<a href="${docURL(d.path)}" title="${esc(d.path)}">${esc(d.title)}</a>`).join('')}</details>`).join('');
 activeNav();
}
function activeNav(){const hash=location.hash;document.querySelectorAll('#sidebar a').forEach(a=>{const href=a.getAttribute('href');const active=href===hash||(a.dataset.nav==='instructions'&&hash.startsWith('#/instructions/'));a.classList.toggle('active',active);if(active){a.setAttribute('aria-current','page');const parent=a.closest('details');if(parent)parent.open=true;}else a.removeAttribute('aria-current');});}
function overview() {
 const ops=reference.instructions, measured=ops.filter(x=>x.observations.length).length;
 main.innerHTML=`<div class="hero"><div><div class="eyebrow">A working reference for Blackhole A0</div><h1>Know the instruction.<br>Understand the machine.</h1><p class="lede">Hardware behavior, cycle counts, and the tests behind them. Follow an instruction from its encoding to what we’ve actually observed.</p><div class="inline-links"><a class="button" href="#/instructions">Explore the instruction set →</a><a class="button" href="${docURL('intro.md')}">Start with the hardware</a></div></div><div class="hero-art" aria-hidden="true">${'<i></i>'.repeat(64)}</div></div>
 <div class="stats"><div class="stat"><strong>${ops.length}</strong><span>Tensix encoders classified</span></div><div class="stat"><strong>${measured}</strong><span>Instructions with attached timing probes</span></div><div class="stat"><strong>${index.documents.length}</strong><span>Documents in the library</span></div></div>
 <div class="section-heading"><h2>Pick up a thread</h2><span>01 / EXPLORE</span></div><div class="cards">
 <a class="card" href="${opURL('MVMUL')}"><span class="number">01 · MATRIX</span><span class="arrow">↗</span><h3>Keep the matrix engine fed</h3><p>MVMUL issue spacing, dependent Dst blocks, fidelity phases, and result latency.</p></a>
 <a class="card" href="${opURL('SFPLOADMACRO')}"><span class="number">02 · VECTOR</span><span class="arrow">↗</span><h3>A load can be a schedule</h3><p>SFPU pipelines, delayed work, register hazards, and the assertions that check them.</p></a>
 <a class="card" href="${opURL('SEMWAIT')}"><span class="number">03 · SYNCHRONIZATION</span><span class="arrow">↗</span><h3>Know what you’re waiting for</h3><p>Semaphore masks and wait conditions. One cycle to latch is not one cycle to finish.</p></a></div>
 <div class="note"><strong>Numbers with their context.</strong> Documented result latency, issue spacing, and measured loop slopes are shown separately. Estimates stay labeled; unknowns stay unknown. ${sourceLink('blackhole-py:tests/timing/README.md','Read the timing method')}</div>
 <div class="section-heading"><h2>From a tile to a program</h2><span>02 / READ</span></div><div class="cards">${[['hardware/behavior-from-tests.md','What the tests demonstrate','Specific assertions, caveats, and remaining gaps.'],['build-and-dispatch/blackhole-py-runtime.md','The current runtime','Host memory, controller images, dispatch, and completion.'],['compiler-maps/README.md','From expressions to kernels','Compiler source maps and worked lowering studies.']].map(([path,title,description])=>`<a class="card" href="${docURL(path)}"><h3>${title}</h3><p>${description}</p></a>`).join('')}</div>`;
}
function instructionList(params) {
 main.innerHTML=`<div class="eyebrow">Blackhole A0 / Instruction set</div><h1>Tensix reference</h1><p class="lede">Search an opcode, an operation, or a caveat. Every entry connects behavior, timing, and test evidence.</p><div class="toolbar"><div class="search-box"><input id="op-search" aria-label="Search instructions" placeholder="Search instructions… e.g. MVMUL, semaphore, rounding" value="${esc(params.get('q')||'')}"></div><select id="unit-filter" aria-label="Filter by execution unit"><option value="">All execution units</option>${[...new Set(reference.instructions.map(x=>x.group))].sort().map(x=>`<option>${esc(x)}</option>`).join('')}</select><select id="evidence-filter" aria-label="Filter by evidence"><option value="">All evidence</option><option value="measured">Has timing probes</option><option value="partial">Has behavioral claims</option><option value="uncertain">Estimated / unknown timing</option></select></div><div id="op-results" aria-live="polite"></div>`;
 const render=()=>{const query=$('#op-search').value.toLowerCase().replace(/^tt_?/,''),unit=$('#unit-filter').value,evidence=$('#evidence-filter').value;
 const filtered=reference.instructions.filter(op=>(!unit||op.group===unit)&&(!evidence||(evidence==='measured'?op.observations.length:evidence==='partial'?op.contracts.length:timingStyle(op)))&&query.split(/\s+/).every(t=>JSON.stringify([op.name,op.opcode,op.overview,op.group,op.caveats,op.contracts,op.timing]).toLowerCase().includes(t)));
 $('#op-results').innerHTML=`<p class="result-count">${filtered.length} / ${reference.instructions.length} INSTRUCTIONS</p>`+(filtered.length?`<div class="table-wrap"><table class="instruction-table"><thead><tr><th>Instruction</th><th>Unit</th><th>Result latency</th><th>Issue spacing</th><th>Timing basis</th></tr></thead><tbody>${filtered.map(op=>`<tr><td><a href="${opURL(op.name)}">${op.name} ↗</a><span class="subtext">${op.opcode}${op.observations.length?' · measured probes':''}</span></td><td>${esc(op.group)}</td><td>${esc(op.timing[0]?.latency||'unknown')}</td><td>${esc(op.timing[0]?.issue_interval||'unknown')}</td><td>${badge(op.timing_status,timingStyle(op))}</td></tr>`).join('')}</tbody></table></div>`:'<div class="empty"><h2>No matching instructions</h2><p>Try an opcode or clear the unit and evidence filters.</p></div>');};
 for(const sel of ['#op-search','#unit-filter','#evidence-filter'])$(sel).addEventListener('input',render);render();
}
function instructionDetail(name) {
 const op=reference.instructions.find(x=>x.name===name.toUpperCase());if(!op)throw new Error('Unknown instruction: '+name);
 const t=op.timing[0]||{};
 main.innerHTML=`<div class="eyebrow"><a href="#/instructions">Instruction reference</a> / ${esc(op.group)}</div><div class="detail-head"><div><h1>${op.name}</h1><p class="metadata">OPCODE ${op.opcode} · ${esc(op.resource)} · BLACKHOLE A0</p></div><button class="button" id="copy-link">Copy link</button></div>
 <div class="detail-layout"><article><div class="markdown" id="op-overview">${md(op.overview)}</div><p class="small">${op.overview_source?sourceLink(op.overview_source,'Manual summary'):'Source-derived synopsis'} · ${badge(op.behavior==='partial'?'Partial behavioral coverage':'No reviewed behavioral claim',op.behavior==='partial'?'':'muted')}</p>
 <div class="stats timing-stats"><div class="stat"><strong>${esc(t.latency||'unknown')}</strong><span>Result / service cycles</span></div><div class="stat"><strong>${esc(t.issue_interval||'unknown')}</strong><span>Issue spacing in cycles</span></div><div class="stat"><strong>${op.observations.length}</strong><span>Attached timing probe records</span></div></div>
 <h2 id="timing">Timing and scheduling</h2><p>${badge(op.timing_status,timingStyle(op))}</p>${op.timing.map(row=>`<div class="note ${timingStyle(op)}">${esc(row.note)}<br>${sourceLink(row.source,'Pinned timing source')}</div>`).join('')}
 ${op.observations.length?`<h3>Measured loop slopes</h3><p class="small">Cycles per body operation, measured through completion. These are not isolated result latencies. No empty-loop subtraction.</p><div class="table-wrap"><table><thead><tr><th>Probe / role</th><th>Slopes</th><th>Placement</th></tr></thead><tbody>${op.observations.map(x=>`<tr><td><code>${esc(x.case)}</code><span class="subtext">${esc(x.role)}</span></td><td>${x.slopes.map(v=>Number(v).toFixed(3)).join(' / ')}</td><td>Card ${x.card} · (${x.core.join(', ')})</td></tr>`).join('')}</tbody></table></div><details><summary class="small">Completion boundary and measurement details</summary>${op.observations.map(x=>`<div class="contract"><h3>${esc(x.case)} · ${esc(x.role)}</h3><p>${esc(x.completion)}</p><p>${esc(x.semantics)}</p><p class="metadata">${esc(x.configuration)}<br>${esc(x.loop)}<br>${x.samples_per_point} retained samples at each length</p><details><summary>Raw retained cycle samples</summary><pre>${esc(JSON.stringify(x.points,null,2))}</pre></details>${sourceLink(x.source,'Raw evidence')}</div>`).join('')}</details>`:'<p class="small">No dedicated probe record is attached for this instruction. The timing basis above may be a manual rule, estimate, or workload-dependent model.</p>'}
 <h2 id="caveats">Caveats and boundaries</h2>${op.caveats.length?op.caveats.map(c=>`<div class="note warn"><strong>${esc(c.title)}</strong><div class="markdown manual-caveat">${md(c.text)}</div></div>`).join(''):'<p class="small">No additional scheduling excerpt is attached. Read the full instruction contract and the test gaps below; this does not mean the instruction has no hazards.</p>'}
 <h2 id="tests">What blackhole-py tests</h2>${op.contracts.length?op.contracts.map(c=>`<section class="contract"><h3>${esc(c.id)}</h3><p>${esc(c.assertion)}</p><p class="gap"><strong>Not established:</strong> ${esc(c.gaps)}</p><div class="test-links">${c.tests.map(test=>`<div><a href="${docURL(test.path,'blackhole-py',test.line?'L'+test.line:'')}">${esc(test.selector)} ↗</a>${test.source_status!=='matches audit'?` ${badge('source changed / unavailable','warn')}`:''}</div>`).join('')}</div><details><summary>Recorded evidence scope</summary><p>${esc(c.evidence_scope)}</p><p>${esc(JSON.stringify(c.evidence))}</p></details></section>`).join(''):'<div class="note warn">The audit records no reviewed behavioral claim for this opcode. Encoding checks and appearances in helper code do not establish functional coverage.</div>'}
 <h2 id="encoding">Syntax and encoding</h2>${op.syntax?`<pre><code>${esc(op.syntax)}</code></pre>`:''}<p class="small">LLK encoder fields below may include reserved bits. Field width is not a guarantee that every encoded value is supported behavior.</p><div class="table-wrap"><table><thead><tr><th>Encoder parameter</th><th>Bits</th></tr></thead><tbody>${op.encoding.map(f=>`<tr><td><code>${esc(f.parameter)}</code></td><td>${f.hi===f.lo?f.lo:f.hi+'..'+f.lo}</td></tr>`).join('')}</tbody></table></div>
 <h2 id="sources">Read further</h2><div class="doc-list">${op.manual?`<p>${sourceLink('tt-isa-documentation:'+op.manual,'Full instruction manual')} <span class="small">${op.blackhole_contract?'Blackhole page':'Shared / inherited source; check architecture qualifications'}</span></p>`:''}${op.documents.map(d=>`<a href="${docURL(d.path)}">${esc(d.title)} →</a>`).join('')}</div><details><summary class="small">Source sightings (navigation, not coverage)</summary>${op.sightings.map(([path,line])=>`<div>${sourceLink('blackhole-py:'+path,path+':'+line)}</div>`).join('')||'<p>No static sightings in the audit.</p>'}</details>
 <hr><p class="metadata">Timing snapshot ${reference.timing_date} · blackhole-py ${reference.blackhole_py_commit.slice(0,12)} + local changes<br>${esc(reference.scope)}</p></article><nav class="toc" aria-label="On this page"><strong>ON THIS PAGE</strong>${[['timing','Timing & scheduling'],['caveats','Caveats'],['tests','Tests & coverage'],['encoding','Syntax & encoding'],['sources','Read further']].map(([id,title])=>`<a href="#/instructions/${op.name}?h=${id}">${title}</a>`).join('')}<hr>${sourceLink('blackhole-py:tests/timing/README.md','Timing methodology')}</nav></div>`;
 hydrate($('#op-overview'), 'tt-isa-documentation', op.manual||'README.md');
 document.querySelectorAll('.manual-caveat').forEach(el=>hydrate(el,'tt-isa-documentation',op.manual||'README.md'));
 $('#copy-link').onclick=async()=>{try{await navigator.clipboard.writeText(location.href);toast('Link copied');}catch(_){toast('Copy the URL from your address bar');}};
}
function documentList(params,global=false){
 main.innerHTML=`<div class="eyebrow">${global?'Search the workbench':'The library'}</div><h1>${global?'Find the detail.':'Documentation'}</h1><p class="lede">${global?'Search instruction behavior and the full text of the documentation.':'Hardware guides, compiler studies, and recorded experiments. Historical material keeps its original scope.'}</p><div class="toolbar"><div class="search-box"><input id="doc-search" aria-label="Search documentation" placeholder="Search all document text…" value="${esc(params.get('q')||'')}"></div><label class="small"><input id="search-history" type="checkbox" ${showHistory?'checked':''}> Include archives</label></div><div id="doc-results" aria-live="polite"></div>`;
 let timer;
 const render=async()=>{const version=++searchVersion,query=$('#doc-search').value.trim(),history=$('#search-history').checked;let docs=index.documents.filter(d=>history||!d.historical);
 try{if(query)docs=await json('/api/search?'+new URLSearchParams({q:query,history:history?'1':'0'}));if(version!==searchVersion||!$('#doc-results'))return;
 const ops=global&&query?reference.instructions.filter(x=>JSON.stringify([x.name,x.overview,x.contracts]).toLowerCase().includes(query.toLowerCase())).slice(0,12):[];
 $('#doc-results').innerHTML=(ops.length?`<h2>Instructions</h2><div class="inline-links">${ops.map(x=>`<a class="button" href="${opURL(x.name)}">${x.name} →</a>`).join('')}</div>`:'')+`<p class="result-count">${docs.length} DOCUMENT${docs.length===1?'':'S'}${query&&docs.length===60?' · FIRST 60 MATCHES':''}</p><div class="doc-list">${docs.map(d=>`<article class="doc-result"><h3><a href="${docURL(d.path)}">${esc(d.title)}</a> ${d.historical?badge('historical','muted'):''}</h3><code>${esc(d.path)}</code>${d.excerpt?`<p>${esc(d.excerpt)}</p>`:''}</article>`).join('')||'<div class="empty">No matching documents. Try fewer words or include archives.</div>'}</div>`;
 }catch(error){if(version===searchVersion)$('#doc-results').textContent=error.message;}};
 $('#doc-search').oninput=()=>{clearTimeout(timer);timer=setTimeout(render,150);};$('#search-history').onchange=render;render();if(global)$('#doc-search').focus();
}
async function documentPage(repo,path,version){
 const data=await json('/api/document?'+new URLSearchParams({repo,path}));if(version!==routeVersion)return;
 main.innerHTML=`<div class="eyebrow">${esc(repo==='docs'?(categories[path.split('/')[0]]||'Field notes'):repo)}</div><p class="metadata">${esc(path)}</p><div class="detail-layout"><article class="markdown" id="doc-content"></article><nav class="toc" id="doc-toc" aria-label="On this page"><strong>ON THIS PAGE</strong></nav></div>`;
 if(data.format==='markdown'){
  $('#doc-content').innerHTML=md(data.content);hydrate($('#doc-content'),repo,path);
  $('#doc-toc').innerHTML+=[...$('#doc-content').querySelectorAll('h2,h3')].slice(0,35).map(h=>`<a href="${docURL(path,repo,h.id)}">${esc(h.textContent)}</a>`).join('');
 }else{$('#doc-content').innerHTML=`<pre class="source-lines">${data.content.split('\n').map((line,i)=>`<span id="L${i+1}">${esc(line)}</span>`).join('')}</pre>`;$('#doc-toc').remove();}
 document.title=(data.format==='markdown'?$('#doc-content h1')?.textContent||path:path.split('/').pop())+' · Blackhole';
}
async function route(){
 const version=++routeVersion;searchVersion++;document.body.classList.remove('menu-open');activeNav();
 const raw=(location.hash.slice(1)||'/home'),[pathname,query='']=raw.split('?'),parts=pathname.split('/').filter(Boolean).map(decodeURIComponent),params=new URLSearchParams(query);
 $('#breadcrumb').textContent=parts[0]==='instructions'?`Reference / ${parts[1]||'Tensix instruction set'}`:parts[0]==='docs'?parts[2]:'Blackhole / '+(parts[0]||'Overview');document.title='Blackhole · Field notes';
 try{
  if(parts[0]==='instructions'){if(parts[1])instructionDetail(parts[1]);else instructionList(params);}
  else if(parts[0]==='documents')documentList(params);
  else if(parts[0]==='search')documentList(params,true);
  else if(parts[0]==='docs')await documentPage(parts[1],parts[2],version);
  else overview();
  if(version!==routeVersion)return;
  const anchor=params.get('h');if(anchor){const el=document.getElementById(anchor);if(el){el.scrollIntoView();if(/^L\d+$/.test(anchor))el.classList.add('highlight');}}else window.scrollTo(0,0);
 }catch(error){if(version!==routeVersion)return;main.innerHTML=`<div class="empty"><h1>Unable to open this page</h1><p>${esc(error.message)}</p><p>Source links require the named sibling checkout. The instruction snapshot and this repository’s docs work on their own.</p><a class="button" href="#/instructions">Instruction reference</a></div>`;}
}
(async()=>{
 try{
  if(localStorage.getItem('bh-theme'))document.documentElement.dataset.theme=localStorage.getItem('bh-theme');
  [reference,index]=await Promise.all([json('/api/instructions'),json('/api/index')]);
  $('#instruction-count').textContent=reference.instructions.length;$('#show-history').checked=showHistory;nav();
  $('#show-history').onchange=e=>{showHistory=e.target.checked;localStorage.setItem('bh-history',showHistory);nav();};
  $('#theme-toggle').onclick=()=>{const theme=document.documentElement.dataset.theme==='dark'?'light':'dark';document.documentElement.dataset.theme=theme;localStorage.setItem('bh-theme',theme);};
  $('#menu-toggle').onclick=()=>document.body.classList.toggle('menu-open');
  document.addEventListener('keydown',e=>{if(e.key==='/'&&!['INPUT','TEXTAREA','SELECT'].includes(document.activeElement.tagName)){e.preventDefault();if(location.hash==='#/search')$('#doc-search')?.focus();else location.hash='/search';}if(e.key==='Escape')document.body.classList.remove('menu-open');});
  window.addEventListener('hashchange',route);route();
 }catch(error){main.innerHTML=`<div class="empty"><h1>Reference unavailable</h1><p>${esc(error.message)}</p></div>`;}
})();
