(() => {
const D = window.DATA;
const $ = (s, el = document) => el.querySelector(s);
const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({'&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'}[c]));
const main = $('#main');
const STATUS = {verified: 'Verified', indirect: 'Indirect only', benchmark: 'Measured', untested: 'Untested'};
const STATUS_HELP = {
  verified: 'A hardware test checks results against an oracle',
  indirect: 'Only exercised inside larger kernels',
  benchmark: 'Results printed, not asserted',
  untested: 'Encoding checks only, or nothing',
};
const TESTS = Object.fromEntries(D.tests.map(t => [t.id, t]));
const FNS = Object.fromEntries(D.areas.flatMap(a => a.functions.map(f => [f.slug, f])));
const AREA = Object.fromEntries(D.areas.map(a => [a.id, a]));
const INTEG = new Set(D.integration.flatMap(g => g.tests));
const hangs = D.quirks.filter(q => q.hang);
const fnHangs = D.areas.flatMap(a => a.functions.filter(f => f.hangs).flatMap(f => f.hangs.map(h => ({h, f}))));
const enc = s => encodeURIComponent(s);
const badge = s => `<span class="badge s-${s}" title="${esc(STATUS_HELP[s])}">${STATUS[s]}</span>`;
const tlink = id => '#/test/' + enc(id);
const caseCount = t => Math.max(1, t.variants.length);

/* ---------- theme ---------- */
const root = document.documentElement;
try { const th = localStorage.getItem('theme'); if (th) root.dataset.theme = th; } catch {}
$('#theme').onclick = () => {
  const dark = root.dataset.theme ? root.dataset.theme === 'dark' : matchMedia('(prefers-color-scheme: dark)').matches;
  root.dataset.theme = dark ? 'light' : 'dark';
  try { localStorage.setItem('theme', root.dataset.theme); } catch {}
};
$('#menu').onclick = () => document.body.classList.toggle('nav-open');

/* ---------- sidebar ---------- */
function sidebar(route) {
  const on = r => route === r ? ' class="on"' : '';
  $('#side').innerHTML = `
    <a href="#/"${on('')}>Overview</a>
    <h6>Device functions</h6>
    ${D.areas.map(a => `<a href="#/area/${a.id}"${on('area/' + a.id)}>${esc(a.name)}<small>${a.functions.length}</small></a>`).join('')}
    <h6>Reference</h6>
    <a href="#/tests"${on('tests')}>All tests<small>${D.tests.length}</small></a>
    <a href="#/quirks"${on('quirks')}>Quirks &amp; hangs<small>${D.quirks.length}</small></a>
    <a href="#/isa"${on('isa')}>Instruction index<small>${D.instructions.length}</small></a>`;
}

/* ---------- overview ---------- */
function statusBar(fns) {
  const n = fns.length || 1;
  return `<div class="bar">${['verified', 'benchmark', 'indirect', 'untested'].map(s => {
    const c = fns.filter(f => f.status === s).length;
    return c ? `<i class="c-${s}" style="width:${100 * c / n}%" title="${c} ${STATUS[s]}"></i>` : '';
  }).join('')}</div>`;
}
const legend = () => `<div class="legend">${Object.keys(STATUS).map(s => `<span><i class="c-${s}"></i>${STATUS[s]}: ${esc(STATUS_HELP[s])}</span>`).join('')}</div>`;

function overview() {
  const fns = D.areas.flatMap(a => a.functions);
  const cases = D.tests.reduce((n, t) => n + caseCount(t), 0);
  main.innerHTML = `
    <h1>Blackhole device functions</h1>
    <p class="lede">What the blackhole-py hardware tests demonstrate about each Tenstorrent Blackhole device function, with the source and the assembly each test runs. Parameter variants are grouped under one test. Exported ${esc(D.generated)} from blackhole-py <code>${esc(D.commit)}</code> plus uncommitted work.</p>
    <div class="stats">
      <div class="stat"><b>${fns.length}</b><span>device functions</span></div>
      <div class="stat"><b>${fns.filter(f => f.status === 'verified').length}</b><span>verified on hardware</span></div>
      <div class="stat"><b>${D.tests.length}</b><span>tests</span></div>
      <div class="stat"><b>${cases.toLocaleString()}</b><span>variants</span></div>
      <div class="stat"><b>${D.quirks.length}</b><span>quirks</span></div>
      <div class="stat"><b>${hangs.length + fnHangs.length}</b><span>known hangs</span></div>
    </div>
    <h2>Areas</h2>${legend()}
    <div class="grid">${D.areas.map(a => `
      <a class="card" href="#/area/${a.id}"><h3>${esc(a.name)}</h3>
        <p>${a.functions.length} functions · ${a.functions.filter(f => f.status === 'verified').length} verified</p>
        ${statusBar(a.functions)}</a>`).join('')}
    </div>
    <h2>Known hangs</h2>
    <div class="fn">${[...fnHangs.map(({h, f}) => ({text: h, where: `<a href="#/area/${f.area}/${f.slug}">${esc(f.name)}</a>`})),
                      ...hangs.map(q => ({text: q.text, where: esc(q.unit) + ' · ' + esc(q.evidence)}))].map(x => `
      <div class="q"><div>${esc(x.text)}</div><div class="src">${x.where}</div></div>`).join('')}</div>
    <h2>Model-level and integration tests</h2>
    <p class="muted">These exercise many functions at once and are listed separately from the device functions.</p>
    <div class="grid">${D.integration.map(g => `<div class="card"><h3>${esc(g.name)}</h3><p>${g.tests.length} tests</p>
      <div class="chips">${g.tests.slice(0, 12).map(id => `<a class="chip" href="${tlink(id)}">${esc(TESTS[id]?.func || id)}</a>`).join('')}${g.tests.length > 12 ? `<span class="chip">+${g.tests.length - 12}</span>` : ''}</div></div>`).join('')}</div>`;
}

/* ---------- area ---------- */
function testRow(id) {
  const t = TESTS[id];
  if (!t) return '';
  const n = caseCount(t);
  return `<a class="trow" href="${tlink(id)}">
    <div><div class="name">${esc(t.func || t.path)}</div><div class="sum">${esc(t.summary || t.path)}</div></div>
    <div class="meta">${t.repo !== 'blackhole-py' ? 'rewrite repo · ' : ''}${n > 1 ? n + ' variants' : '1 case'}${t.asm ? ' · asm' : ''}</div></a>`;
}
function area(id, focus) {
  const a = AREA[id];
  if (!a) return notFound();
  main.innerHTML = `
    <div class="crumb"><a href="#/">Overview</a> / Device functions</div>
    <h1>${esc(a.name)}</h1><p class="lede">${esc(a.intro)}</p>
    ${statusBar(a.functions)}${legend()}
    ${a.functions.map(f => `
      <section class="fn" id="${f.slug}">
        <div class="fn-head">
          <div class="fn-title"><h3>${esc(f.name)}</h3>${badge(f.status)}</div>
          <p class="fn-claim">${esc(f.claim)}</p>
          ${f.instr.length ? `<div class="chips">${f.instr.map(i => `<a class="chip" href="#/isa/${enc(i)}">${esc(i)}</a>`).join('')}</div>` : ''}
          ${(f.hangs || []).map(h => `<div class="hang"><b>Hangs:</b> ${esc(h)}</div>`).join('')}
        </div>
        <div class="tests">${f.tests.length ? f.tests.map(testRow).join('') : '<div class="empty">No test.</div>'}</div>
      </section>`).join('')}`;
  if (focus) requestAnimationFrame(() => document.getElementById(focus)?.scrollIntoView({block: 'start'}));
}

/* ---------- test ---------- */
function highlight(src) {
  const re = /(#[^\n]*)|("""[\s\S]*?"""|'''[\s\S]*?'''|f?"(?:\\.|[^"\\\n])*"|f?'(?:\\.|[^'\\\n])*')|(^\s*@[\w.]+)|\b(def|class|return|for|in|if|elif|else|while|with|as|import|from|assert|lambda|yield|not|and|or|is|None|True|False|try|except|finally|raise|pass|break|continue)\b/gm;
  let out = '', last = 0, m;
  while ((m = re.exec(src))) {
    out += esc(src.slice(last, m.index));
    const cls = m[1] ? 'cm' : m[2] ? 'st' : m[3] ? 'dec' : 'kw';
    out += `<span class="${cls}">${esc(m[0])}</span>`;
    last = re.lastIndex;
  }
  return out + esc(src.slice(last));
}
const asmCache = {};
function test(id) {
  const t = TESTS[id];
  if (!t) return notFound();
  const fns = t.functions.map(s => FNS[s]).filter(Boolean);
  main.innerHTML = `
    <div class="crumb"><a href="#/tests">All tests</a> / ${esc(t.group)}</div>
    <h1 class="mono" style="font-size:22px">${esc(t.func || t.path.split('/').pop())}</h1>
    <p class="lede">${esc(t.summary || 'No summary.')}</p>
    <dl class="kv">
      <dt>File</dt><dd class="mono">${esc((t.repo !== 'blackhole-py' ? t.repo + '/' : '') + t.path)}</dd>
      <dt>Demonstrates</dt><dd>${fns.length ? fns.map(f => `<a href="#/area/${f.area}/${f.slug}">${esc(f.name)}</a> ${badge(f.status)}`).join('<br>') : '<span class="muted">Not mapped to a device function' + (INTEG.has(id) ? ' (model-level test)' : '') + '</span>'}</dd>
      <dt>Variants</dt><dd>${t.variants.length ? `${t.variants.length.toLocaleString()} parameter combinations` : 'Single case'}</dd>
    </dl>
    ${t.variants.length > 1 ? `<input class="field vfilter" id="vf" placeholder="Filter ${t.variants.length} variants"><div class="variants" id="vl"></div>` : ''}
    <div class="tabs"><button data-tab="asm" class="on">Assembly</button><button data-tab="src">Source</button></div>
    <div class="panel" id="tab"></div>`;
  if (t.variants.length > 1) {
    const vl = $('#vl'), vf = $('#vf');
    const draw = () => {
      const q = vf.value.toLowerCase(), list = t.variants.filter(v => v.toLowerCase().includes(q));
      vl.innerHTML = list.slice(0, 400).map((v, i) => `<span class="chip${v === t.variants[0] ? ' on' : ''}" title="${v === t.variants[0] ? 'Assembly below is from this variant' : ''}">${esc(v)}</span>`).join('') + (list.length > 400 ? `<span class="chip">+${list.length - 400} more</span>` : '');
    };
    vf.oninput = draw; draw();
  }
  const tabs = main.querySelectorAll('.tabs button');
  const show = which => {
    tabs.forEach(b => b.classList.toggle('on', b.dataset.tab === which));
    if (which === 'src') $('#tab').innerHTML = `<pre class="src">${highlight(t.source)}</pre>`;
    else showAsm(t);
  };
  tabs.forEach(b => b.onclick = () => show(b.dataset.tab));
  show(t.asm ? 'asm' : 'src');
}
async function showAsm(t) {
  const tab = $('#tab');
  if (!t.asm) { tab.innerHTML = `<div class="note">${esc(t.note || 'No assembly captured.')}</div>`; return; }
  tab.innerHTML = '<div class="note">Loading…</div>';
  let a;
  try { a = asmCache[t.asm] ||= await (await fetch(t.asm)).json(); }
  catch { tab.innerHTML = '<div class="note">Could not load the assembly file. Serve this folder over HTTP rather than opening it from disk.</div>'; return; }
  if (!document.body.contains(tab)) return;
  let img = 0, mode = 'tensix', q = '', limit = 2000;
  const draw = () => {
    const im = a.images[img];
    let rows = im.rows.filter(r => mode === 'all' || r[2] === 't');
    if (q) rows = rows.filter(r => (r[3] + ' ' + r[4] + ' ' + r[5]).toLowerCase().includes(q));
    const nT = im.rows.filter(r => r[2] === 't').length;
    tab.innerHTML = `
      <div class="asm-tools">
        <div class="seg">${a.images.map((m, i) => `<button data-img="${i}" class="${i === img ? 'on' : ''}">${esc(m.role)}</button>`).join('')}</div>
        <div class="seg"><button data-mode="tensix" class="${mode === 'tensix' ? 'on' : ''}">Tensix (${nT})</button><button data-mode="all" class="${mode === 'all' ? 'on' : ''}">All (${im.rows.length})</button></div>
        <input class="field" id="aq" placeholder="Filter op, operand, source" value="${esc(q)}">
        <span class="muted" style="font-size:12px">Variant <code>${esc(a.case || 'default')}</code>${a.boundary ? ' · capture stopped at the first device read' : ''}</span>
      </div>
      <div class="asm-wrap"><table class="asm"><tbody>${rows.slice(0, limit).map(r => `
        <tr class="${r[2]}"><td class="pc">${(r[0] ?? 0).toString(16).padStart(5, '0')}</td><td class="w">${r[1]}</td><td class="op">${esc(r[3])}</td><td class="a">${esc(r[4])}</td><td class="s">${esc(r[5])}</td></tr>`).join('')}
      </tbody></table>${rows.length > limit ? `<div class="note"><button class="chip" id="more">Show all ${rows.length} rows</button></div>` : ''}${rows.length ? '' : '<div class="note">No rows match.</div>'}</div>`;
    tab.querySelectorAll('[data-img]').forEach(b => b.onclick = () => { img = +b.dataset.img; draw(); });
    tab.querySelectorAll('[data-mode]').forEach(b => b.onclick = () => { mode = b.dataset.mode; draw(); });
    const aq = $('#aq'); aq.oninput = () => { q = aq.value.toLowerCase(); draw(); $('#aq').focus(); const e = $('#aq'); e.setSelectionRange(e.value.length, e.value.length); };
    $('#more') && ($('#more').onclick = () => { limit = Infinity; draw(); });
  };
  // Start on the first image that actually contains Tensix work.
  img = Math.max(0, a.images.findIndex(m => m.rows.some(r => r[2] === 't')));
  draw();
}

/* ---------- all tests ---------- */
function allTests() {
  const groups = {};
  D.tests.forEach(t => (groups[t.group] ||= []).push(t));
  main.innerHTML = `
    <h1>All tests</h1>
    <p class="lede">${D.tests.length} tests, ${D.tests.reduce((n, t) => n + caseCount(t), 0).toLocaleString()} variants. Summaries are one or two sentences on what each test checks.</p>
    <div class="filters"><input class="field" id="tf" placeholder="Filter by name, file or summary"></div>
    <div id="tl"></div>`;
  const draw = () => {
    const q = $('#tf').value.toLowerCase();
    $('#tl').innerHTML = Object.entries(groups).map(([g, ts]) => {
      const list = ts.filter(t => !q || (t.id + ' ' + t.summary).toLowerCase().includes(q));
      if (!list.length) return '';
      const files = {};
      list.forEach(t => (files[t.path] ||= []).push(t));
      return `<h2>${esc(g)}</h2>` + Object.entries(files).map(([p, fs]) => `
        <section class="fn"><div class="fn-head"><div class="fn-title"><h3 class="mono" style="font-weight:500">${esc(p)}</h3>${fs.some(t => INTEG.has(t.id)) ? '<span class="badge s-untested">model-level</span>' : ''}</div></div>
        <div class="tests">${fs.map(t => testRow(t.id)).join('')}</div></section>`).join('');
    }).join('') || '<p class="muted">No tests match.</p>';
  };
  $('#tf').oninput = draw; draw();
}

/* ---------- quirks ---------- */
function quirks() {
  const units = [...new Set(D.quirks.map(q => q.unit))];
  let unit = '', onlyHang = false;
  main.innerHTML = `
    <h1>Quirks &amp; hangs</h1>
    <p class="lede">Behaviour discovered while writing kernels, from tests, code comments, commit messages and boop-docs. Each entry says where the evidence is and which test, if any, reproduces it.</p>
    <div class="filters"><div class="seg" id="qu"></div><div class="seg"><button id="qh">Hangs only</button></div></div>
    <div id="ql"></div>`;
  const testHref = s => { const k = Object.keys(TESTS).find(k => k.startsWith(s + '::') || k === s || (s.startsWith('blackhole-py-rewrite ') && k.endsWith(s.split(' ').pop()))); return k ? tlink(k) : null; };
  const draw = () => {
    $('#qu').innerHTML = ['', ...units].map(u => `<button data-u="${esc(u)}" class="${u === unit ? 'on' : ''}">${esc(u || 'All')}</button>`).join('');
    $('#qh').classList.toggle('on', onlyHang);
    $('#qu').querySelectorAll('button').forEach(b => b.onclick = () => { unit = b.dataset.u; draw(); });
    const list = D.quirks.filter(q => (!unit || q.unit === unit) && (!onlyHang || q.hang));
    const by = {};
    list.forEach(q => (by[q.unit] ||= []).push(q));
    $('#ql').innerHTML = Object.entries(by).map(([u, qs]) => `<h2>${esc(u)}</h2><div class="fn">${qs.map(q => {
      const h = q.test ? testHref(q.test) : null;
      return `<div class="q"><div>${q.hang ? '<span class="badge s-hang">Hangs</span> ' : ''}${esc(q.text)}</div>
        <div class="src">Evidence: ${esc(q.evidence)}${q.test ? ` · Reproduced by ${h ? `<a href="${h}">${esc(q.test)}</a>` : esc(q.test)}` : ' · No reproducing test'}</div></div>`;
    }).join('')}</div>`).join('');
  };
  $('#qh').onclick = () => { onlyHang = !onlyHang; draw(); };
  draw();
}

/* ---------- instruction index ---------- */
function isa(focus) {
  const units = [...new Set(D.instructions.map(i => i.unit).filter(Boolean))].sort();
  main.innerHTML = `
    <h1>Instruction index</h1>
    <p class="lede">All ${D.instructions.length} Tensix encoders: which device functions use them, timing from the blackhole-py timing catalogue, and where each timing figure comes from.</p>
    <div class="filters"><input class="field" id="if" placeholder="Filter instructions" value="${esc(focus || '')}">
      <select class="field" id="iu" style="width:auto"><option value="">All units</option>${units.map(u => `<option>${esc(u)}</option>`).join('')}</select>
      <div class="seg"><button id="iun">Not covered by any function</button></div></div>
    <div class="table-wrap"><table class="data"><thead><tr><th>Instruction</th><th>Unit</th><th>Latency</th><th>Issue</th><th>Device functions</th><th>Timing source</th></tr></thead><tbody id="ib"></tbody></table></div>`;
  let uncovered = false;
  const draw = () => {
    const q = $('#if').value.toLowerCase(), u = $('#iu').value;
    $('#iun').classList.toggle('on', uncovered);
    $('#ib').innerHTML = D.instructions.filter(i => (!q || i.name.toLowerCase().includes(q)) && (!u || i.unit === u) && (!uncovered || !i.functions.some(f => f.status === 'verified'))).map(i => `
      <tr><td class="n">${esc(i.name)}</td><td>${esc(i.unit)}</td><td class="n">${esc(i.latency)}</td><td class="n">${esc(i.issue)}</td>
      <td>${i.functions.length ? i.functions.map(f => `<a href="#/area/${FNS[f.slug].area}/${f.slug}">${esc(f.name)}</a> ${badge(f.status)}`).join('<br>') : '<span class="muted">—</span>'}</td>
      <td class="muted" title="${esc(i.notes)}">${esc(i.basis)}</td></tr>`).join('');
  };
  $('#if').oninput = draw; $('#iu').onchange = draw; $('#iun').onclick = () => { uncovered = !uncovered; draw(); };
  draw();
}

function notFound() { main.innerHTML = '<h1>Not found</h1><p class="lede"><a href="#/">Back to the overview</a></p>'; }

/* ---------- router ---------- */
function route() {
  const h = decodeURIComponent(location.hash.replace(/^#\/?/, ''));
  const [kind, ...rest] = h.split('/');
  document.body.classList.remove('nav-open');
  sidebar(kind === 'area' ? 'area/' + rest[0] : kind === 'test' ? 'tests' : kind);
  if (!kind) overview();
  else if (kind === 'area') area(rest[0], rest[1]);
  else if (kind === 'test') test(rest.join('/'));
  else if (kind === 'tests') allTests();
  else if (kind === 'quirks') quirks();
  else if (kind === 'isa') isa(rest[0]);
  else notFound();
  if (kind !== 'area' || !rest[1]) window.scrollTo(0, 0);
  document.title = (kind ? (main.querySelector('h1')?.textContent + ' · ') : '') + 'Blackhole Device Functions';
}
addEventListener('hashchange', route);
route();

/* ---------- export ---------- */
function exportMarkdown() {
  const L = [];
  const fnName = s => FNS[s]?.name || s;
  L.push('# Blackhole device functions', '',
    `Exported ${D.generated} from blackhole-py ${D.commit} (plus uncommitted work). Generated from the blackhole-py hardware tests.`,
    'Status: verified = a hardware test checks results against an oracle; benchmark = measured, results printed not asserted; indirect = only exercised inside larger kernels; untested = encoding checks only or nothing.', '');
  L.push('## Device functions', '');
  for (const a of D.areas) {
    L.push(`### ${a.name}`, '', a.intro, '');
    for (const f of a.functions) {
      L.push(`#### ${f.name} [${f.status}]`, '', f.claim);
      if (f.instr.length) L.push('', 'Instructions: ' + f.instr.join(', '));
      for (const h of f.hangs || []) L.push('', 'HANGS: ' + h);
      if (f.tests.length) L.push('', 'Tests:', ...f.tests.map(id => `- \`${id}\``));
      L.push('');
    }
  }
  L.push('## Tests', '', 'Each test lists its summary and parameter variants (pytest ids).', '');
  const groups = {};
  D.tests.forEach(t => (groups[t.group] ||= []).push(t));
  for (const [g, ts] of Object.entries(groups)) {
    L.push(`### ${g}`, '');
    for (const t of ts) {
      L.push(`#### \`${t.id}\``, '', t.summary || '(no summary)');
      if (t.functions.length) L.push('', 'Demonstrates: ' + t.functions.map(fnName).join('; '));
      if (INTEG.has(t.id)) L.push('', 'Model-level / integration test.');
      if (t.variants.length) L.push('', `Variants (${t.variants.length}): ` + t.variants.slice(0, 200).join(', ') + (t.variants.length > 200 ? `, … (+${t.variants.length - 200} more)` : ''));
      L.push('');
    }
  }
  L.push('## Quirks', '');
  const units = {};
  D.quirks.forEach(q => (units[q.unit] ||= []).push(q));
  for (const [u, qs] of Object.entries(units)) {
    L.push(`### ${u}`, '');
    qs.forEach(q => L.push(`- ${q.hang ? '**HANGS** ' : ''}${q.text} (evidence: ${q.evidence}; ${q.test ? 'reproduced by ' + q.test : 'no reproducing test'})`));
    L.push('');
  }
  L.push('## Instruction index', '', '| Instruction | Unit | Latency | Issue | Device functions | Timing source |', '|---|---|---|---|---|---|');
  D.instructions.forEach(i => L.push(`| ${i.name} | ${i.unit} | ${i.latency} | ${i.issue} | ${i.functions.map(f => `${f.name} [${f.status}]`).join('; ') || '-'} | ${i.basis} |`));
  return L.join('\n') + '\n';
}
function download(name, text, type) {
  const url = URL.createObjectURL(new Blob([text], {type}));
  const a = Object.assign(document.createElement('a'), {href: url, download: name});
  document.body.append(a); a.click(); a.remove();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}
const exMenu = $('#exportMenu');
$('#exportBtn').onclick = e => { e.stopPropagation(); exMenu.hidden = !exMenu.hidden; };
addEventListener('click', e => { if (!e.target.closest('.export')) exMenu.hidden = true; });
exMenu.querySelectorAll('[data-export]').forEach(b => b.onclick = () => {
  const stamp = D.generated;
  if (b.dataset.export === 'md') download(`blackhole-device-functions-${stamp}.md`, exportMarkdown(), 'text/markdown');
  else download(`blackhole-device-functions-${stamp}.json`, JSON.stringify({...D, areas: D.areas.map(a => ({...a, functions: a.functions.map(f => ({...f}))}))}, null, 1), 'application/json');
  exMenu.hidden = true;
});

/* ---------- search ---------- */
const index = [
  ...D.areas.flatMap(a => a.functions.map(f => ({k: 'Function', t: f.name, d: f.claim, x: f.instr.join(' '), h: `#/area/${f.area}/${f.slug}`}))),
  ...D.tests.map(t => ({k: 'Test', t: t.func || t.path, d: t.summary, x: t.path, h: tlink(t.id)})),
  ...D.quirks.map(q => ({k: q.hang ? 'Hang' : 'Quirk', t: q.text, d: q.unit + ' · ' + q.evidence, x: '', h: '#/quirks'})),
  ...D.instructions.map(i => ({k: 'Instr', t: i.name, d: [i.unit, i.latency && 'latency ' + i.latency].filter(Boolean).join(' · '), x: '', h: '#/isa/' + enc(i.name)})),
];
const pal = $('#palette'), qin = $('#q'), res = $('#results');
let sel = 0, hits = [];
const open = () => { pal.hidden = false; qin.value = ''; find(); qin.focus(); };
const close = () => { pal.hidden = true; };
function find() {
  const terms = qin.value.toLowerCase().split(/\s+/).filter(Boolean);
  hits = !terms.length ? index.filter(e => e.k === 'Function').slice(0, 30) : index.map(e => {
    const name = e.t.toLowerCase(), all = (e.t + ' ' + e.d + ' ' + e.x).toLowerCase();
    if (!terms.every(w => all.includes(w))) return null;
    return [e, terms.reduce((s, w) => s + (name.startsWith(w) ? 4 : name.includes(w) ? 2 : 0), 0) - name.length / 200];
  }).filter(Boolean).sort((a, b) => b[1] - a[1]).slice(0, 60).map(x => x[0]);
  sel = 0; drawHits();
}
function drawHits() {
  res.innerHTML = hits.map((e, i) => `<a href="${e.h}" class="${i === sel ? 'sel' : ''}"><span class="k">${e.k}</span><span><div class="t">${esc(e.t)}</div><div class="d">${esc(e.d)}</div></span></a>`).join('') || '<div class="note">No results.</div>';
  res.querySelector('.sel')?.scrollIntoView({block: 'nearest'});
}
$('#searchOpen').onclick = open;
pal.onclick = e => { if (e.target === pal) close(); };
res.onclick = e => { if (e.target.closest('a')) close(); };
qin.oninput = find;
qin.onkeydown = e => {
  if (e.key === 'ArrowDown') { sel = Math.min(sel + 1, hits.length - 1); drawHits(); e.preventDefault(); }
  else if (e.key === 'ArrowUp') { sel = Math.max(sel - 1, 0); drawHits(); e.preventDefault(); }
  else if (e.key === 'Enter' && hits[sel]) { location.hash = hits[sel].h; close(); }
  else if (e.key === 'Escape') close();
};
addEventListener('keydown', e => {
  if ((e.key === '/' || (e.key === 'k' && (e.metaKey || e.ctrlKey))) && pal.hidden && !/INPUT|SELECT|TEXTAREA/.test(document.activeElement.tagName)) { e.preventDefault(); open(); }
});
})();
