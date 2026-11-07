(() => {
const D = window.DATA;
const $ = (s, el = document) => el.querySelector(s);
const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({'&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'}[c]));
const main = $('#main');
const STATUS = {verified: 'verified', benchmark: 'measured', indirect: 'indirect', untested: 'untested'};
const STATUS_HELP = {
  verified: 'a hardware test checks the result against a reference',
  benchmark: 'measured; results are printed, not asserted',
  indirect: 'exercised only inside larger kernels',
  untested: 'encoding checks only, or nothing',
};
const TESTS = Object.fromEntries(D.tests.map(t => [t.id, t]));
const FNS = Object.fromEntries(D.areas.flatMap(a => a.functions.map(f => [f.slug, f])));
const AREA = Object.fromEntries(D.areas.map(a => [a.id, a]));
const INTEG = new Set(D.integration.flatMap(g => g.tests));
const hangs = D.quirks.filter(q => q.hang);
const fnHangs = D.areas.flatMap(a => a.functions.filter(f => f.hangs).flatMap(f => f.hangs.map(h => ({h, f}))));
const enc = s => encodeURIComponent(s);
const badge = s => `<span class="st st-${s}" title="${esc(STATUS_HELP[s])}">${STATUS[s]}</span>`;
const tlink = id => '#/test/' + enc(id);
const caseCount = t => Math.max(1, t.variants.length);
const hex = n => '0x' + (n >>> 0).toString(16);

/* ---------- theme ---------- */
const root = document.documentElement;
$('#theme').onclick = () => {
  const dark = root.dataset.theme ? root.dataset.theme === 'dark' : matchMedia('(prefers-color-scheme: dark)').matches;
  root.dataset.theme = dark ? 'light' : 'dark';
  try { localStorage.setItem('theme', root.dataset.theme); } catch {}
};
$('#menu').onclick = () => document.body.classList.toggle('nav-open');

/* ---------- llama data (loaded lazily) ---------- */
let LL = null, llPromise = null;
const loadLlama = () => llPromise ||= fetch('llama/index.json').then(r => r.json()).then(d => { LL = d; addLlamaSearch(); return d; });

/* ---------- sidebar ---------- */
const KERNEL_NAV = [['embedding', 'Embedding'], ['qkv', 'QKV projection'], ['attention', 'Attention'], ['o', 'Output projection'],
  ['gate', 'Gate/up + SwiGLU'], ['down', 'Down projection'], ['lm', 'LM head'], ['argmax', 'Argmax']];
function sidebar(route) {
  const on = r => route === r ? ' class="on"' : '';
  $('#side').innerHTML = `
    <h6>Device functions</h6>
    <a href="#/"${on('')}>Overview</a>
    ${D.areas.map(a => `<a href="#/area/${a.id}"${on('area/' + a.id)}>${esc(a.name)}<small>${a.functions.length}</small></a>`).join('')}
    <h6>Llama 3.2 1B decode</h6>
    <a href="#/llama"${on('llama')}>One token</a>
    ${KERNEL_NAV.map(([id, name]) => `<a href="#/llama/${id}"${on('llama/' + id)}>${name}</a>`).join('')}
    <h6>Reference</h6>
    <a href="#/tests"${on('tests')}>Tests<small>${D.tests.length}</small></a>
    <a href="#/quirks"${on('quirks')}>Quirks and hangs<small>${D.quirks.length}</small></a>
    <a href="#/isa"${on('isa')}>Instructions<small>${D.instructions.length}</small></a>`;
}

/* ---------- overview ---------- */
const legend = () => `<p class="legend">${Object.keys(STATUS).map(s => `${badge(s)} ${esc(STATUS_HELP[s])}`).join('<br>')}</p>`;

function overview() {
  const cases = D.tests.reduce((n, t) => n + caseCount(t), 0);
  const count = (fns, s) => fns.filter(f => f.status === s).length || '';
  main.innerHTML = `
    <h1>Blackhole device functions</h1>
    <p class="lede">Functions of the Tenstorrent Blackhole Tensix tile, the blackhole-py hardware tests that exercise each one, and the RISC-V and Tensix code those tests run. ${D.tests.length} tests, ${cases.toLocaleString()} parameter variants. Built ${esc(D.generated)} from blackhole-py <code>${esc(D.commit)}</code>. Unofficial.</p>
    <p>The <a href="#/llama">Llama 3.2 1B decode</a> section lists every kernel launched to decode one token, with its launch parameters and annotated disassembly.</p>
    <h2>Areas</h2>
    <div class="table-wrap"><table class="data"><thead><tr><th>Area</th><th class="r">Functions</th>${Object.keys(STATUS).map(s => `<th class="r">${STATUS[s]}</th>`).join('')}</tr></thead><tbody>
    ${D.areas.map(a => `<tr><td><a href="#/area/${a.id}">${esc(a.name)}</a></td><td class="r">${a.functions.length}</td>${Object.keys(STATUS).map(s => `<td class="r">${count(a.functions, s)}</td>`).join('')}</tr>`).join('')}
    </tbody></table></div>
    ${legend()}
    <h2>Known hangs</h2>
    <ul class="plain">${[...fnHangs.map(({h, f}) => ({text: h, where: `<a href="#/area/${f.area}/${f.slug}">${esc(f.name)}</a>`})),
                      ...hangs.map(q => ({text: q.text, where: esc(q.unit) + ' · ' + esc(q.evidence)}))].map(x => `
      <li>${esc(x.text)} <span class="src">${x.where}</span></li>`).join('')}</ul>
    <h2>Model-level tests</h2>
    <p class="muted">These exercise many functions at once and are not counted above.</p>
    <table class="data"><tbody>${D.integration.map(g => `<tr><td style="width:150px">${esc(g.name)}</td><td class="inl">${g.tests.map(id => `<a href="${tlink(id)}">${esc(TESTS[id]?.func || id)}</a>`).join(', ')}</td></tr>`).join('')}</tbody></table>`;
}

/* ---------- area ---------- */
function testRow(id) {
  const t = TESTS[id];
  if (!t) return '';
  const n = caseCount(t);
  return `<a class="trow" href="${tlink(id)}">
    <div><div class="name">${esc(t.func || t.path)}</div><div class="sum">${esc(t.summary || t.path)}</div></div>
    <div class="meta">${t.repo !== 'blackhole-py' ? 'rewrite repo · ' : ''}${n > 1 ? n + ' variants' : '1 case'}</div></a>`;
}
function area(id, focus) {
  const a = AREA[id];
  if (!a) return notFound();
  main.innerHTML = `
    <div class="crumb"><a href="#/">Device functions</a></div>
    <h1>${esc(a.name)}</h1><p class="lede">${esc(a.intro)}</p>
    ${a.functions.map(f => `
      <section class="fn" id="${f.slug}">
        <div class="fn-title"><h3>${esc(f.name)}</h3>${badge(f.status)}</div>
        <p class="fn-claim">${esc(f.claim)}</p>
        ${f.instr.length ? `<div class="inl">${f.instr.map(i => `<a href="#/isa/${enc(i)}">${esc(i)}</a>`).join(' ')}</div>` : ''}
        ${(f.hangs || []).map(h => `<div class="hang">Hangs: ${esc(h)}</div>`).join('')}
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
    const cls = m[1] ? 'cm' : m[2] ? 'str' : m[3] ? 'dec' : 'kw';
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
    <div class="crumb"><a href="#/tests">Tests</a> / ${esc(t.group)}</div>
    <h1 class="mono" style="font-size:20px">${esc(t.func || t.path.split('/').pop())}</h1>
    <p class="lede">${esc(t.summary || 'No summary.')}</p>
    <dl class="kv">
      <dt>File</dt><dd class="mono">${esc((t.repo !== 'blackhole-py' ? t.repo + '/' : '') + t.path)}</dd>
      <dt>Demonstrates</dt><dd>${fns.length ? fns.map(f => `<a href="#/area/${f.area}/${f.slug}">${esc(f.name)}</a> ${badge(f.status)}`).join('<br>') : '<span class="muted">Not mapped to a device function' + (INTEG.has(id) ? ' (model-level test)' : '') + '</span>'}</dd>
      <dt>Variants</dt><dd>${t.variants.length ? `${t.variants.length.toLocaleString()} parameter combinations` : 'Single case'}</dd>
    </dl>
    ${t.variants.length > 1 ? `<input class="field" id="vf" placeholder="Filter ${t.variants.length} variants"><div class="variants" id="vl"></div>` : ''}
    <div class="tabs"><button data-tab="asm" class="on">Assembly</button><button data-tab="src">Source</button></div>
    <div id="tab"></div>`;
  if (t.variants.length > 1) {
    const vl = $('#vl'), vf = $('#vf');
    const draw = () => {
      const q = vf.value.toLowerCase(), list = t.variants.filter(v => v.toLowerCase().includes(q));
      vl.innerHTML = list.slice(0, 400).map(v => `<span class="${v === t.variants[0] ? 'on' : ''}" title="${v === t.variants[0] ? 'The assembly below is from this variant' : ''}">${esc(v)}</span>`).join('') + (list.length > 400 ? `<span>+${list.length - 400} more</span>` : '');
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
  catch { tab.innerHTML = '<div class="note">Could not load the assembly. Serve this folder over HTTP rather than opening it from disk.</div>'; return; }
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
        <div class="seg"><button data-mode="tensix" class="${mode === 'tensix' ? 'on' : ''}">Tensix only (${nT})</button><button data-mode="all" class="${mode === 'all' ? 'on' : ''}">All (${im.rows.length})</button></div>
        <input class="field" id="aq" placeholder="Filter" value="${esc(q)}">
        <span class="faint" style="font-size:13px">variant <code>${esc(a.case || 'default')}</code>${a.boundary ? ' · capture stopped at the first device read' : ''}</span>
      </div>
      <div class="asm-wrap"><table class="asm"><tbody>${rows.slice(0, limit).map(r => `
        <tr class="${r[2]}"><td class="pc">${(r[0] ?? 0).toString(16).padStart(5, '0')}</td><td class="w">${r[1]}</td><td class="op">${esc(r[3])}</td><td class="a">${esc(r[4])}</td><td class="s">${esc(r[5])}</td></tr>`).join('')}
      </tbody></table>${rows.length > limit ? `<div class="note"><button class="link" id="more">Show all ${rows.length} rows</button></div>` : ''}${rows.length ? '' : '<div class="note">No rows match.</div>'}</div>`;
    tab.querySelectorAll('[data-img]').forEach(b => b.onclick = () => { img = +b.dataset.img; draw(); });
    tab.querySelectorAll('[data-mode]').forEach(b => b.onclick = () => { mode = b.dataset.mode; draw(); });
    const aq = $('#aq'); aq.oninput = () => { q = aq.value.toLowerCase(); draw(); const e = $('#aq'); e.focus(); e.setSelectionRange(e.value.length, e.value.length); };
    $('#more') && ($('#more').onclick = () => { limit = Infinity; draw(); });
  };
  img = Math.max(0, a.images.findIndex(m => m.rows.some(r => r[2] === 't')));
  draw();
}

/* ---------- all tests ---------- */
function allTests() {
  const groups = {};
  D.tests.forEach(t => (groups[t.group] ||= []).push(t));
  main.innerHTML = `
    <h1>Tests</h1>
    <p class="lede">${D.tests.length} tests, ${D.tests.reduce((n, t) => n + caseCount(t), 0).toLocaleString()} variants.</p>
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
        <section class="fn"><div class="fn-title"><h3 class="mono" style="font-weight:500;font-size:13.5px">${esc(p)}</h3>${fs.some(t => INTEG.has(t.id)) ? '<span class="faint" style="font-size:12.5px">model-level</span>' : ''}</div>
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
    <h1>Quirks and hangs</h1>
    <p class="lede">Behaviour found while writing kernels, from tests, code comments, commit messages and boop-docs. Each entry gives its evidence and the test that reproduces it, if any.</p>
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
    $('#ql').innerHTML = Object.entries(by).map(([u, qs]) => `<h2>${esc(u)}</h2>${qs.map(q => {
      const h = q.test ? testHref(q.test) : null;
      return `<div class="q"><div>${q.hang ? '<span class="st st-hang">hangs</span> ' : ''}${esc(q.text)}</div>
        <div class="src">${esc(q.evidence)}${q.test ? ` · reproduced by ${h ? `<a href="${h}">${esc(q.test)}</a>` : esc(q.test)}` : ' · no reproducing test'}</div></div>`;
    }).join('')}`).join('');
  };
  $('#qh').onclick = () => { onlyHang = !onlyHang; draw(); };
  draw();
}

/* ---------- instruction index ---------- */
function isa(focus) {
  const units = [...new Set(D.instructions.map(i => i.unit).filter(Boolean))].sort();
  main.innerHTML = `
    <h1>Instructions</h1>
    <p class="lede">The ${D.instructions.length} Tensix encoders, the device functions that use each, and timing from the blackhole-py timing catalogue with its source.</p>
    <div class="filters"><input class="field" id="if" placeholder="Filter instructions" value="${esc(focus || '')}">
      <select class="field" id="iu"><option value="">All units</option>${units.map(u => `<option>${esc(u)}</option>`).join('')}</select>
      <div class="seg"><button id="iun">Not verified by any function</button></div></div>
    <div class="table-wrap"><table class="data"><thead><tr><th>Instruction</th><th>Unit</th><th>Latency</th><th>Issue</th><th>Device functions</th><th>Timing source</th></tr></thead><tbody id="ib"></tbody></table></div>`;
  let uncovered = false;
  const draw = () => {
    const q = $('#if').value.toLowerCase(), u = $('#iu').value;
    $('#iun').classList.toggle('on', uncovered);
    $('#ib').innerHTML = D.instructions.filter(i => (!q || i.name.toLowerCase().includes(q)) && (!u || i.unit === u) && (!uncovered || !i.functions.some(f => f.status === 'verified'))).map(i => `
      <tr><td class="n">${esc(i.name)}</td><td>${esc(i.unit)}</td><td class="n">${esc(i.latency)}</td><td class="n">${esc(i.issue)}</td>
      <td>${i.functions.length ? i.functions.map(f => `<a href="#/area/${FNS[f.slug].area}/${f.slug}">${esc(f.name)}</a> ${badge(f.status)}`).join('<br>') : '<span class="faint">—</span>'}</td>
      <td class="muted" title="${esc(i.notes)}">${esc(i.basis)}</td></tr>`).join('');
  };
  $('#if').oninput = draw; $('#iu').onchange = draw; $('#iun').onclick = () => { uncovered = !uncovered; draw(); };
  draw();
}

/* ---------- llama: overview ---------- */
const imgCount = (p, v) => v.images.reduce((n, id) => n + (LL.sizes[id] || 0), 0);
const uniqueImages = p => [...new Set(p.variants.flatMap(v => v.images))];
async function llama(id, sub, variant) {
  main.innerHTML = '<div class="note">Loading…</div>';
  try { await loadLlama(); } catch { main.innerHTML = '<div class="note">Could not load llama/index.json. Serve this folder over HTTP.</div>'; return; }
  if (id) return llamaKernel(id, sub, variant);
  const P = Object.fromEntries(LL.programs.map(p => [p.id, p]));
  const c = LL.config;
  const row = (n, p) => `<tr><td class="r num">${n}</td><td><a href="#/llama/${p.id}">${esc(p.title)}</a></td><td class="num">${esc(p.math)}</td>
    <td class="r">${p.cores.length}</td><td class="r">${p.variants.length}</td><td class="r">${uniqueImages(p).reduce((n, i) => n + LL.sizes[i], 0).toLocaleString()}</td></tr>`;
  main.innerHTML = `
    <h1>Llama 3.2 1B decode</h1>
    <p class="lede">Every kernel launched to decode one token on a p150a, built from blackhole-py <code>${esc(LL.commit)}</code> <span class="faint">(examples/llama3)</span>. The listings are the worker images the runtime uploads, disassembled with addresses replaced by register and variable names.</p>
    <p class="facts"><b>${c.layers}</b> layers · d_model <b>${c.embed_dim}</b> · <b>${c.q_heads}</b> query / <b>${c.kv_heads}</b> KV heads of <b>${c.head_dim}</b> · MLP <b>${c.mlp_dim}</b> · vocabulary <b>${c.vocab.toLocaleString()}</b> · context <b>${c.max_tokens}</b> · BF16 weights and KV cache</p>
    <h2>Launches per token</h2>
    <p>The runtime records these ${LL.launches} launches once as a trace and replays it for every token. Each kernel is compiled once against layer 0; per-layer launches rebind the weight and cache parameters.</p>
    <div class="table-wrap"><table class="data"><thead><tr><th class="r">#</th><th>Kernel</th><th>Computes</th><th class="r">Cores</th><th class="r">Variants</th><th class="r">Instructions</th></tr></thead><tbody>
      ${row(1, P.embedding)}
      <tr><td></td><td colspan="5" class="muted" style="padding-top:10px">Each of the ${c.layers} layers, launches 2–6 for layer 0, then every 5 up to ${1 + 5 * c.layers}</td></tr>
      ${['qkv', 'attention', 'o', 'gate', 'down'].map((k, i) => row(2 + i, P[k])).join('')}
      ${row(2 + 5 * c.layers, P.lm)}${row(3 + 5 * c.layers, P.argmax)}
    </tbody></table></div>
    <p class="muted" style="font-size:13.5px">Variants are distinct sets of images within one launch: projection cores differ in row count, DRAM port and starting bank; attention cores differ in head. Instructions counts every distinct image once.</p>
    <h2>Per-token parameters</h2>
    <p>Patched into the trace before each replay. Everything else is fixed or rebound per layer.</p>
    <table class="data"><tbody>${Object.entries(LL.runtime).map(([k, v]) => `<tr><td class="n" style="width:160px">${k}</td><td>${esc(v)}</td></tr>`).join('')}</tbody></table>
    <h2>Reading the listings</h2>
    <dl class="legend-list">
      <dt>BRISC, NCRISC, TRISC0–2</dt><dd>Each worker core runs five RISC-V harts with separate images. BRISC reads DRAM into L1, NCRISC writes L1 out, the TRISCs drive the unpacker, math (FPU and SFPU) and packer. Uppercase mnemonics are Tensix instructions issued inline from a TRISC.</dd>
      <dt>%hi(NAME), %lo(NAME)</dt><dd>A lui/addi pair that builds the address of NAME. The constant was resolved by propagating values through the image's control flow.</dd>
      <dt>[NAME]</dt><dd>Effective address of a load or store, when it is known statically.</dd>
      <dt>NOC0.NOC_CMD_CTRL[0], PC_BUF.SEMAPHORE[5], STREAM[8]…</dt><dd>MMIO register names from ttsim (<code>data/bh/tile_regs.json</code>); [n] is the command buffer, semaphore or overlay stream index. A few NoC words ttsim does not model use tt-metal's names.</dd>
      <dt>CFG[72].THCON_SEC0_REG2_Out_data_format</dt><dd>Tensix configuration word 72 and its first field (ttsim and tt-metal cfg_defines.h). The comment lists every field the store sets.</dd>
      <dt>param.NAME</dt><dd>Launch parameter slot, at ${hex(LL.paramBase)} + 4 × slot.</dd>
      <dt>weight_cb, weight_cb.rd_ptr, weight_cb.tiles_acked</dt><dd>Circular buffers are named after the variable that holds them in kernels.py: the L1 ring itself, the hart's private read/write pointer and tile counter, and the shared overlay-stream counters.</dd>
      <dt>ids_l1, local.NAME</dt><dd>Other L1 allocations and RISC-local words, named the same way.</dd>
      <dt>Grey rows</dt><dd>The kernels.py line that emitted the instructions below it. The right column names the innermost helper (ttko) frame.</dd>
    </dl>
    <p class="muted" style="font-size:13.5px">Addresses are link-time addresses at each hart's text base. The runtime copies every distinct image into a resident kernel arena and patches the final jump back to firmware; all branches are PC-relative. DRAM addresses come from an offline allocation with the same allocator and order as the runtime.</p>`;
}

/* ---------- llama: kernel ---------- */
const COLS = [...Array(7)].map((_, i) => i + 1).concat([...Array(5)].map((_, i) => i + 10));
const ROWS = [...Array(10)].map((_, i) => i + 2);
const imgCache = {};
const ROLE_NAMES = {brisc: 'BRISC', ncrisc: 'NCRISC', trisc0: 'TRISC0', trisc1: 'TRISC1', trisc2: 'TRISC2'};

function paramValue(p) {
  const values = Array.isArray(p.values) ? p.values : null;
  if (p.kind === 'buffer') {
    const what = `${p.dtype} [${p.shape.join(', ')}]`;
    if (!values) return `${what} <span class="faint">at</span> <span class="num">${hex(p.addr)}</span>`;
    return `${what}, one shard per core <details><summary>${values.length} shard addresses</summary><div class="vals">${values.map(hex).join(' ')}</div></details>`;
  }
  if (!values) return `<span class="num">${p.values}</span>`;
  return `<details><summary>per core: ${values.slice(0, 4).join(', ')}, …</summary><div class="vals">${values.join(' ')}</div></details>`;
}
function bindingText(p) {
  if (p.binding === 'token') return `per token: ${esc(p.note)}`;
  if (p.binding === 'layer') return `per layer: <span class="mono">${esc(p.note)}</span>`;
  return '<span class="faint">fixed</span>';
}

function llamaKernel(id, sub, variant) {
  const p = LL.programs.find(x => x.id === id);
  if (!p) return notFound();
  const coreVariant = {};
  p.variants.forEach((v, i) => v.cores.forEach(c => coreVariant[c.join(',')] = i));
  let vi = Math.min(Math.max(0, (+variant || 1) - 1), p.variants.length - 1), raw = false, words = false, q = '';
  let role = ROLE_NAMES[sub] ? sub : (p.id === 'embedding' || p.id === 'argmax' ? 'brisc' : 'trisc1');
  const remember = () => history.replaceState(null, '', `#/llama/${p.id}/${role}${vi ? '/' + (vi + 1) : ''}`);
  main.innerHTML = `
    <div class="crumb"><a href="#/llama">Llama 3.2 1B decode</a></div>
    <h1>${esc(p.title)}</h1>
    <p class="math">${esc(p.math)}</p>
    <p>${esc(p.text)}</p>
    <h2>Launch</h2>
    <div class="map-wrap">
      <div>
        <div class="chip-map" id="map" style="grid-template-columns: repeat(${COLS.length + 1}, 14px)"></div>
        <div class="map-axis">worker grid, x 1–7 and 10–14, y 2–11</div>
      </div>
      <dl class="kv" style="margin:0;flex:1;min-width:280px">
        <dt>Cores</dt><dd>${p.cores.length}</dd>
        <dt>Variants</dt><dd>${p.variants.length}${p.variants.length > 1 ? ' <span class="faint">(click a core or pick below)</span>' : ''}</dd>
        <dt>Parameters</dt><dd>${p.params.length} words at ${hex(LL.paramBase)}</dd>
        <dt>Circular buffers</dt><dd>${p.cbs.length}</dd>
      </dl>
    </div>
    <h3 style="margin-top:22px">Parameters</h3>
    <div class="table-wrap"><table class="data"><thead><tr><th class="r">Slot</th><th>Name</th><th>Value (layer 0)</th><th>Bound</th></tr></thead><tbody>
      ${p.params.map(x => `<tr><td class="r num">${x.slot}</td><td class="n">${esc(x.name)}</td><td>${paramValue(x)}</td><td>${bindingText(x)}</td></tr>`).join('')}
    </tbody></table></div>
    <h3 style="margin-top:22px">L1</h3>
    <div class="table-wrap"><table class="data"><thead><tr><th>Name</th><th>Format</th><th class="r">Tiles</th><th>Address</th><th class="r">Bytes</th></tr></thead><tbody>
      ${p.cbs.map(c => `<tr><td class="n">${esc(c.name)} <span class="faint">cb${c.index}</span></td><td>${c.dtype}</td><td class="r">${c.depth}</td><td class="n">${hex(c.addr)}</td><td class="r">${c.size.toLocaleString()}</td></tr>`).join('')}
      ${p.l1.map(c => `<tr><td class="n">${esc(c.name)}</td><td class="faint">—</td><td></td><td class="n">${hex(c.addr)}</td><td class="r">${c.size.toLocaleString()}</td></tr>`).join('')}
    </tbody></table></div>
    <h2>Code</h2>
    ${p.variants.length > 1 ? `<p><select class="field" id="vsel">${p.variants.map((v, i) => `<option value="${i}">${i + 1}. ${esc(v.key)} — ${v.cores.length} core${v.cores.length > 1 ? 's' : ''}</option>`).join('')}</select></p>` : ''}
    <div class="tabs" id="roles"></div>
    <div class="listing-tools">
      <input class="field" id="lq" placeholder="Filter instructions">
      <label class="toggle"><input type="checkbox" id="raw"> raw operands</label>
      <label class="toggle"><input type="checkbox" id="words"> encodings</label>
      <span class="faint" id="lcount" style="font-size:13px"></span>
    </div>
    <div class="role-note" id="rnote"></div>
    <div class="lst-wrap" id="lst"></div>`;

  const drawMap = () => {
    let html = '';
    for (const y of ROWS) for (const x of [...COLS.slice(0, 7), 0, ...COLS.slice(7)]) {
      if (!x) { html += '<i class="gap"></i>'; continue; }
      const k = x + ',' + y, v = coreVariant[k];
      html += v === undefined ? `<i title="(${x}, ${y})"></i>` : `<i class="in${v === vi ? ' sel' : ''}" data-v="${v}" title="(${x}, ${y}) · variant ${v + 1}${p.variants[v].key ? ': ' + esc(p.variants[v].key) : ''}"></i>`;
    }
    $('#map').innerHTML = html;
    $('#map').querySelectorAll('[data-v]').forEach(el => el.onclick = () => { vi = +el.dataset.v; if ($('#vsel')) $('#vsel').value = vi; remember(); drawMap(); drawRoles(); drawListing(); });
  };
  const drawRoles = () => {
    const v = p.variants[vi];
    $('#roles').innerHTML = v.images.map(im => { const r = im.split('-')[0]; return `<button data-r="${r}" class="${r === role ? 'on' : ''}">${ROLE_NAMES[r]}<small>${LL.sizes[im].toLocaleString()}</small></button>`; }).join('');
    $('#roles').querySelectorAll('button').forEach(b => b.onclick = () => { role = b.dataset.r; remember(); drawRoles(); drawListing(); });
  };
  let token = 0;
  const drawListing = async () => {
    const mine = ++token;
    const imageId = p.variants[vi].images.find(i => i.startsWith(role + '-'));
    $('#rnote').textContent = LL.roles[role];
    $('#lst').innerHTML = '<div class="note">Loading…</div>';
    let img;
    try { img = imgCache[imageId] ||= await (await fetch(`llama/img/${imageId}.json`)).json(); }
    catch { $('#lst').innerHTML = '<div class="note">Could not load this image.</div>'; return; }
    if (mine !== token) return;
    $('#lst').innerHTML = renderListing(img, {raw, words, q});
    const n = img.rows.length;
    $('#lcount').textContent = `${n.toLocaleString()} instructions · ${imageId}`;
  };
  if ($('#vsel')) { $('#vsel').value = vi; $('#vsel').onchange = e => { vi = +e.target.value; remember(); drawMap(); drawRoles(); drawListing(); }; }
  $('#raw').onchange = e => { raw = e.target.checked; drawListing(); };
  $('#words').onchange = e => { words = e.target.checked; drawListing(); };
  let timer;
  $('#lq').oninput = e => { clearTimeout(timer); timer = setTimeout(() => { q = e.target.value.toLowerCase(); drawListing(); }, 150); };
  drawMap(); drawRoles(); drawListing();
}

const KERNEL_FILE = 'examples/llama3/kernels.py';
function headFrame(stack) {
  const k = stack.findIndex(f => LL.files[f[0]] === KERNEL_FILE);
  return k < 0 ? stack.length - 1 : k;
}
function symbolize(text) {
  // Highlight names inside %hi()/%lo() and [ ] without touching register names.
  return esc(text).replace(/(%(?:hi|lo)\()([^)]*)(\))/g, '$1<span class="sym">$2</span>$3').replace(/\[([^\]]+)\]/g, '[<span class="sym">$1</span>]');
}
function renderListing(img, {raw, words, q}) {
  let out = '', lastHead = null, shown = 0;
  const ncol = words ? 6 : 5;
  img.rows.forEach((r, i) => {
    const [word, kind, op, ops, rawOps, note, si] = r;
    const operands = raw && rawOps ? rawOps : ops;
    const labels = img.labels[i];
    if (q && !(op + ' ' + ops + ' ' + (rawOps || '') + ' ' + note + ' ' + (labels || []).join(' ')).toLowerCase().includes(q)) return;
    const stack = si >= 0 ? img.stacks[si] : null;
    if (stack) {
      const h = headFrame(stack), f = stack[h], key = f[0] + ':' + f[1];
      if (key !== lastHead) {
        const path = LL.files[f[0]], text = (LL.sources[path] || [])[f[1] - 1] || '';
        out += `<tr class="py"><td colspan="${ncol}"><b>${esc(path.split('/').pop())}:${f[1]}</b>${esc(text.trim())}</td></tr>`;
        lastHead = key;
      }
    }
    if (labels) out += `<tr class="lab"><td colspan="${ncol}">${esc(labels.join(', '))}:</td></tr>`;
    let via = '';
    if (stack) {
      const h = headFrame(stack);
      if (h > 0) { const f = stack[0]; via = `${LL.files[f[0]].split('/').pop()}:${f[1]} ${f[2]}`; }
    }
    const pc = (img.base + 4 * i).toString(16).padStart(5, '0');
    out += `<tr class="i ${kind}"><td class="pc">${pc}</td>${words ? `<td class="w">${word}</td>` : ''}<td class="op">${esc(op)}</td><td class="a">${raw ? esc(operands) : symbolize(operands)}</td><td class="c">${esc(note)}</td><td class="v">${esc(via)}</td></tr>`;
    shown++;
  });
  if (!shown) return '<div class="note">No instructions match.</div>';
  return `<table class="lst"><tbody>${out}</tbody></table>`;
}

function notFound() { main.innerHTML = '<h1>Not found</h1><p><a href="#/">Overview</a></p>'; }

/* ---------- router ---------- */
function route() {
  const h = decodeURIComponent(location.hash.replace(/^#\/?/, ''));
  const [kind, ...rest] = h.split('/');
  document.body.classList.remove('nav-open');
  sidebar(kind === 'area' ? 'area/' + rest[0] : kind === 'test' ? 'tests' : kind === 'llama' && rest[0] ? 'llama/' + rest[0] : kind);
  if (!kind) overview();
  else if (kind === 'area') area(rest[0], rest[1]);
  else if (kind === 'test') test(rest.join('/'));
  else if (kind === 'tests') allTests();
  else if (kind === 'quirks') quirks();
  else if (kind === 'isa') isa(rest[0]);
  else if (kind === 'llama') llama(rest[0], rest[1], rest[2]);
  else notFound();
  if (kind !== 'area' || !rest[1]) window.scrollTo(0, 0);
  const title = kind === 'llama' ? (rest[0] ? (KERNEL_NAV.find(k => k[0] === rest[0]) || [, ''])[1] + ' · Llama 3.2 1B' : 'Llama 3.2 1B decode') : main.querySelector('h1')?.textContent;
  document.title = (kind && title ? title + ' · ' : '') + 'Blackhole device functions';
}
addEventListener('hashchange', route);
route();

/* ---------- export ---------- */
function exportMarkdown() {
  const L = [];
  const fnName = s => FNS[s]?.name || s;
  L.push('# Blackhole device functions', '',
    `Built ${D.generated} from blackhole-py ${D.commit}.`,
    'Status: verified = a hardware test checks results against a reference; measured = results printed, not asserted; indirect = only exercised inside larger kernels; untested = encoding checks only or nothing.', '');
  L.push('## Device functions', '');
  for (const a of D.areas) {
    L.push(`### ${a.name}`, '', a.intro, '');
    for (const f of a.functions) {
      L.push(`#### ${f.name} [${STATUS[f.status]}]`, '', f.claim);
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
      if (INTEG.has(t.id)) L.push('', 'Model-level test.');
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
  L.push('## Instructions', '', '| Instruction | Unit | Latency | Issue | Device functions | Timing source |', '|---|---|---|---|---|---|');
  D.instructions.forEach(i => L.push(`| ${i.name} | ${i.unit} | ${i.latency} | ${i.issue} | ${i.functions.map(f => `${f.name} [${STATUS[f.status]}]`).join('; ') || '-'} | ${i.basis} |`));
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
  else download(`blackhole-device-functions-${stamp}.json`, JSON.stringify(D, null, 1), 'application/json');
  exMenu.hidden = true;
});

/* ---------- search ---------- */
const index = [
  ...D.areas.flatMap(a => a.functions.map(f => ({k: 'Function', t: f.name, d: f.claim, x: f.instr.join(' '), h: `#/area/${f.area}/${f.slug}`}))),
  ...D.tests.map(t => ({k: 'Test', t: t.func || t.path, d: t.summary, x: t.path, h: tlink(t.id)})),
  ...D.quirks.map(q => ({k: q.hang ? 'Hang' : 'Quirk', t: q.text, d: q.unit + ' · ' + q.evidence, x: '', h: '#/quirks'})),
  ...D.instructions.map(i => ({k: 'Instr', t: i.name, d: [i.unit, i.latency && 'latency ' + i.latency].filter(Boolean).join(' · '), x: '', h: '#/isa/' + enc(i.name)})),
  ...KERNEL_NAV.map(([id, name]) => ({k: 'Kernel', t: name, d: 'Llama 3.2 1B decode', x: 'llama ' + id, h: '#/llama/' + id})),
];
function addLlamaSearch() {
  for (const p of LL.programs) {
    const e = index.find(x => x.h === '#/llama/' + p.id);
    if (e) { e.d = p.math; e.x += ' ' + p.text + ' ' + p.params.map(x => x.name).join(' '); }
  }
}
const pal = $('#palette'), qin = $('#q'), res = $('#results');
let sel = 0, hits = [];
const open = () => { pal.hidden = false; qin.value = ''; find(); qin.focus(); };
const close = () => { pal.hidden = true; };
function find() {
  const terms = qin.value.toLowerCase().split(/\s+/).filter(Boolean);
  hits = !terms.length ? index.filter(e => e.k === 'Function' || e.k === 'Kernel').slice(0, 40) : index.map(e => {
    const name = e.t.toLowerCase(), all = (e.t + ' ' + e.d + ' ' + e.x).toLowerCase();
    if (!terms.every(w => all.includes(w))) return null;
    return [e, terms.reduce((s, w) => s + (name.startsWith(w) ? 4 : name.includes(w) ? 2 : 0), 0) - name.length / 200];
  }).filter(Boolean).sort((a, b) => b[1] - a[1]).slice(0, 60).map(x => x[0]);
  sel = 0; drawHits();
}
function drawHits() {
  res.innerHTML = hits.map((e, i) => `<a href="${e.h}" class="${i === sel ? 'sel' : ''}"><span class="k">${e.k}</span><span><div class="t">${esc(e.t)}</div><div class="d">${esc(e.d)}</div></span></a>`).join('') || '<div class="note" style="padding:10px 14px">No results.</div>';
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
loadLlama().catch(() => {});
})();
