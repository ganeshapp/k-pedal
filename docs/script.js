'use strict';

const PATH_COLORS = [
  '#2196F3', '#4CAF50', '#FF9800', '#E91E63', '#9C27B0',
  '#00BCD4', '#FF5722', '#607D8B', '#8BC34A', '#FFC107',
];
const NEARBY_QUERIES = [
  { label: '숙소', sub: 'Stay', q: '숙소 모텔 펜션', icon: 'hotel' },
  { label: '편의점', sub: 'Store', q: '편의점', icon: 'store' },
  { label: '화장실', sub: 'Toilet', q: '공중화장실', icon: 'toilet' },
  { label: '자전거수리', sub: 'Bike Repair', q: '자전거수리', icon: 'wrench' },
  { label: '버스정류장', sub: 'Bus Stop', q: '버스정류장', icon: 'bus' },
  { label: '기차역', sub: 'Train', q: '기차역 전철역', icon: 'train' },
];
const ICONS = {
  hotel: 'M19 7h-8v7H3V5H1v15h2v-3h18v3h2v-9c0-2.21-1.79-4-4-4M7 13c1.66 0 3-1.34 3-3S8.66 7 7 7s-3 1.34-3 3 1.34 3 3 3',
  store: 'M21.9 8.89-1.05-4.37c-.22-.9-1-1.52-1.91-1.52H5.05c-.9 0-1.69.63-1.9 1.52L2.1 8.89c-.24 1.02-.02 2.06.62 2.88.08.11.19.19.28.29V19c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2v-6.94c.09-.09.2-.18.28-.28.64-.82.87-1.87.62-2.89',
  toilet: 'M5.5 22v-7.5H4V9c0-1.1.9-2 2-2h3c1.1 0 2 .9 2 2v5.5H9.5V22zM18 22v-6h3l-2.54-7.63A2 2 0 0 0 16.56 7h-.12a2 2 0 0 0-1.9 1.37L12 16h3v6zM7.5 6a2 2 0 1 0 0-4 2 2 0 0 0 0 4M17 6a2 2 0 1 0 0-4 2 2 0 0 0 0 4',
  wrench: 'M22.7 19l-9.1-9.1c.9-2.3.4-5-1.5-6.9-2-2-5-2.4-7.4-1.3L9 6 6 9 1.6 4.7C.4 7.1.9 10.1 2.9 12.1c1.9 1.9 4.6 2.4 6.9 1.5l9.1 9.1c.4.4 1 .4 1.4 0l2.3-2.3c.5-.4.5-1.1.1-1.4',
  bus: 'M4 16c0 .88.39 1.67 1 2.22V20a1 1 0 0 0 1 1h1a1 1 0 0 0 1-1v-1h8v1a1 1 0 0 0 1 1h1a1 1 0 0 0 1-1v-1.78c.61-.55 1-1.34 1-2.22V6c0-3.5-3.58-4-8-4s-8 .5-8 4zm3.5 1A1.5 1.5 0 0 1 6 15.5 1.5 1.5 0 0 1 7.5 14 1.5 1.5 0 0 1 9 15.5 1.5 1.5 0 0 1 7.5 17m9 0a1.5 1.5 0 0 1-1.5-1.5 1.5 1.5 0 0 1 1.5-1.5 1.5 1.5 0 0 1 1.5 1.5 1.5 1.5 0 0 1-1.5 1.5M18 11H6V6h12z',
  train: 'M12 2c-4 0-8 .5-8 4v9.5C4 17.43 5.57 19 7.5 19L6 20.5v.5h12v-.5L16.5 19c1.93 0 3.5-1.57 3.5-3.5V6c0-3.5-4-4-8-4M7.5 17c-.83 0-1.5-.67-1.5-1.5S6.67 14 7.5 14s1.5.67 1.5 1.5S8.33 17 7.5 17m3.5-7H6V6h5zm2 0V6h5v4zm3.5 7c-.83 0-1.5-.67-1.5-1.5s.67-1.5 1.5-1.5 1.5.67 1.5 1.5-.67 1.5-1.5 1.5',
};

let currentMap = null;
let currentPathId = null;
const STORAGE_KEY = 'kpedal-map-provider';

function getMapProvider() {
  return localStorage.getItem(STORAGE_KEY) || 'kakao';
}
function setMapProvider(p) {
  localStorage.setItem(STORAGE_KEY, p);
  document.querySelectorAll('[data-provider]').forEach((el) => {
    el.classList.toggle('active', el.dataset.provider === p);
  });
  document.querySelectorAll('.open-maps-btn').forEach(updateOpenMapsBtn);
}
function updateOpenMapsBtn(btn) {
  const p = getMapProvider();
  btn.classList.toggle('kakao', p === 'kakao');
  btn.classList.toggle('naver', p === 'naver');
  btn.querySelector('.label').textContent =
    `Open in ${p === 'kakao' ? 'Kakao' : 'Naver'} Maps`;
}

function openInMaps(cp) {
  const p = getMapProvider();
  if (p === 'kakao') {
    if (cp.kakao_link) return window.open(cp.kakao_link, '_blank', 'noopener');
    const url = `https://map.kakao.com/?q=${encodeURIComponent(cp.name)}&px=${cp.lng}&py=${cp.lat}`;
    return window.open(url, '_blank', 'noopener');
  }
  if (cp.naver_link) return window.open(cp.naver_link, '_blank', 'noopener');
  const url = `https://map.naver.com/p/search/${cp.lat},${cp.lng}`;
  window.open(url, '_blank', 'noopener');
}

function searchNearby(cp, keyword) {
  const p = getMapProvider();
  const url = p === 'kakao'
    ? `https://map.kakao.com/?q=${encodeURIComponent(keyword)}&px=${cp.lng}&py=${cp.lat}`
    : `https://map.naver.com/p/search/${encodeURIComponent(keyword)}/place?c=15.00,${cp.lat},${cp.lng},0,0,0,dh`;
  window.open(url, '_blank', 'noopener');
}

async function loadPath(id) {
  const res = await fetch(`data/path-${id}.json`);
  if (!res.ok) throw new Error(`Failed to load path-${id}.json`);
  return res.json();
}

function fmtKm(n) { return Math.round(n).toLocaleString(); }

function pathColor(id) { return PATH_COLORS[(id - 1) % PATH_COLORS.length]; }

function buildElevationSvg(samples, color) {
  if (!samples || samples.length < 2) return '';
  const W = 800, H = 160, P = 24;
  const xs = samples.map((s) => s.distance_km);
  const ys = samples.map((s) => s.elevation_m);
  const xMax = Math.max(...xs);
  const yMin = Math.min(...ys);
  const yMax = Math.max(...ys);
  const yPad = Math.max(20, (yMax - yMin) * 0.1);
  const yLo = yMin - yPad;
  const yHi = yMax + yPad;
  const px = (v) => P + ((v) / xMax) * (W - P * 2);
  const py = (v) => H - P - ((v - yLo) / (yHi - yLo)) * (H - P * 2);

  let pathD = `M ${px(xs[0]).toFixed(1)} ${py(ys[0]).toFixed(1)}`;
  for (let i = 1; i < xs.length; i++) {
    pathD += ` L ${px(xs[i]).toFixed(1)} ${py(ys[i]).toFixed(1)}`;
  }
  const fillD = pathD + ` L ${px(xMax).toFixed(1)} ${(H - P).toFixed(1)} L ${P.toFixed(1)} ${(H - P).toFixed(1)} Z`;

  return `
    <svg viewBox="0 0 ${W} ${H}" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="none" class="elev-svg">
      <defs>
        <linearGradient id="elev-grad" x1="0" x2="0" y1="0" y2="1">
          <stop offset="0%" stop-color="${color}" stop-opacity="0.45"/>
          <stop offset="100%" stop-color="${color}" stop-opacity="0"/>
        </linearGradient>
      </defs>
      <path d="${fillD}" fill="url(#elev-grad)" stroke="none"/>
      <path d="${pathD}" stroke="${color}" stroke-width="2" fill="none" stroke-linejoin="round" stroke-linecap="round" vector-effect="non-scaling-stroke"/>
      <text x="${P}" y="${P - 6}" fill="rgba(255,255,255,0.5)" font-size="11" font-family="ui-monospace,Menlo,monospace">${Math.round(yMax)} m</text>
      <text x="${P}" y="${H - 6}" fill="rgba(255,255,255,0.5)" font-size="11" font-family="ui-monospace,Menlo,monospace">${Math.round(yMin)} m</text>
      <text x="${W - P}" y="${H - 6}" text-anchor="end" fill="rgba(255,255,255,0.5)" font-size="11" font-family="ui-monospace,Menlo,monospace">${Math.round(xMax)} km</text>
      <text x="${P + 60}" y="${H - 6}" fill="rgba(255,255,255,0.5)" font-size="11" font-family="ui-monospace,Menlo,monospace">0 km</text>
    </svg>
  `;
}

function checkpointKmFromStart(path) {
  // Walk routes in order, accumulate per checkpoint by matching start coordinate.
  // The app uses checkpoint_pairs[i].distance_km between i and i+1.
  const pairs = path.checkpoint_pairs || [];
  const kms = [0];
  for (let i = 0; i < pairs.length; i++) {
    kms.push((kms[i] || 0) + (pairs[i].distance_km || 0));
  }
  return kms;
}

function renderCheckpointCard(cp, idx, totalCount, kmFromStart, color, isLast) {
  const photos = (cp.images || []).slice(0, 6);
  const photoHtml = photos.length
    ? `<div class="cp-photos">${photos.map((u, i) => `<img loading="lazy" src="${u}" alt="${escapeHtml(cp.name)} photo ${i + 1}" onerror="this.style.display='none'">`).join('')}</div>`
    : '';
  const desc = (cp.description || '').trim();
  const descHtml = desc ? `<div class="cp-about"><span class="cp-about-label">About</span><p>${escapeHtml(desc)}</p></div>` : '';
  const nearbyHtml = NEARBY_QUERIES.map((n) => `
    <button class="cp-nearby-btn" data-action="nearby" data-keyword="${escapeAttr(n.q)}">
      <svg viewBox="0 0 24 24" fill="currentColor"><path d="${ICONS[n.icon]}"/></svg>
      <span><strong>${n.label}</strong><em>${n.sub}</em></span>
    </button>
  `).join('');

  return `
    <div class="cp-card" data-cp-id="${cp.id}" style="--cp-color:${color}">
      <button class="cp-summary" data-action="toggle" aria-expanded="false">
        <span class="cp-num">${idx + 1}</span>
        <span class="cp-summary-text">
          <span class="cp-name">${escapeHtml(cp.name)}</span>
          <span class="cp-from-start">${kmFromStart.toFixed(1)} km from start</span>
        </span>
        <svg class="cp-chevron" viewBox="0 0 24 24" fill="currentColor"><path d="M8.6 16.6 13.2 12 8.6 7.4 10 6l6 6-6 6z"/></svg>
      </button>
      <div class="cp-detail" hidden>
        ${photoHtml}
        <div class="cp-coord">${cp.lat.toFixed(5)}, ${cp.lng.toFixed(5)}</div>
        <div class="cp-actions">
          <button class="open-maps-btn ${getMapProvider()}" data-action="open-maps">
            <svg viewBox="0 0 24 24" fill="currentColor"><path d="M20.5 3l-.16.03L15 5.1 9 3 3.36 4.9c-.21.07-.36.25-.36.48V20.5c0 .28.22.5.5.5l.16-.03L9 18.9l6 2.1 5.64-1.9c.21-.07.36-.25.36-.48V3.5c0-.28-.22-.5-.5-.5M15 19l-6-2.11V5l6 2.11z"/></svg>
            <span class="label">Open in ${getMapProvider() === 'kakao' ? 'Kakao' : 'Naver'} Maps</span>
          </button>
        </div>
        ${descHtml}
        <div class="cp-nearby">
          <div class="cp-nearby-head">
            <strong>Find Nearby</strong>
            <span>Opens ${getMapProvider() === 'kakao' ? 'Kakao' : 'Naver'} Maps</span>
          </div>
          <div class="cp-nearby-grid">${nearbyHtml}</div>
        </div>
      </div>
      ${isLast ? '' : `<div class="cp-leg"><svg viewBox="0 0 24 24" fill="currentColor"><path d="M9.78 12.46 15.36 18l1.06-1.06-4.94-4.94 4.94-4.94L15.36 6z" transform="rotate(-90 12 12)"/></svg></div>`}
    </div>
  `;
}

function escapeHtml(s) {
  return String(s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}
function escapeAttr(s) { return escapeHtml(s); }

function renderPathDetail(path) {
  const color = pathColor(path.id);
  const kms = checkpointKmFromStart(path);
  const cps = path.checkpoints || [];
  const totalElev = path.overall_elevation || [];
  const elevSvg = totalElev.length >= 2 ? buildElevationSvg(totalElev, color) : '';
  const shortName = path.name.replace(/ Bicycle Paths?$/, '');

  const detail = document.getElementById('path-detail');
  detail.style.setProperty('--path-color', color);
  detail.innerHTML = `
    <div class="path-detail-bar">
      <div class="container path-detail-bar-inner">
        <a class="path-detail-back" href="#paths" aria-label="Back to paths">
          <svg viewBox="0 0 24 24" fill="currentColor"><path d="M20 11H7.83l5.59-5.59L12 4l-8 8 8 8 1.42-1.41L7.83 13H20z"/></svg>
        </a>
        <div class="path-detail-title">
          <span class="path-detail-num">${String(path.id).padStart(2, '0')}</span>
          ${escapeHtml(shortName)}
        </div>
        <div class="map-toggle" role="tablist" aria-label="Map provider">
          <button data-provider="kakao" data-action="set-provider" class="${getMapProvider() === 'kakao' ? 'active' : ''}">Kakao</button>
          <button data-provider="naver" data-action="set-provider" class="${getMapProvider() === 'naver' ? 'active' : ''}">Naver</button>
        </div>
      </div>
    </div>

    <div id="path-map" class="path-detail-map"></div>

    <div class="container path-detail-body">
      <div class="path-detail-stats">
        <div class="pd-stat">
          <span class="pd-stat-value">${fmtKm(path.total_distance_km)}</span>
          <span class="pd-stat-label">km total</span>
        </div>
        <div class="pd-stat">
          <span class="pd-stat-value">${cps.length}</span>
          <span class="pd-stat-label">checkpoints</span>
        </div>
        <div class="pd-stat">
          <span class="pd-stat-value gain">+${fmtKm(path.elevation_gain_m)}</span>
          <span class="pd-stat-label">m gain</span>
        </div>
        <div class="pd-stat">
          <span class="pd-stat-value loss">−${fmtKm(path.elevation_loss_m)}</span>
          <span class="pd-stat-label">m loss</span>
        </div>
      </div>

      ${elevSvg ? `
        <div class="path-detail-elev">
          <div class="elev-head">
            <svg viewBox="0 0 24 24" fill="currentColor" class="elev-icon"><path d="M14 6l-3.75 5 2.85 3.8L11.5 16c-1.99-2.65-5-7-5-7L1 19h22z"/></svg>
            <strong>Elevation profile</strong>
          </div>
          ${elevSvg}
        </div>
      ` : ''}

      <div class="path-detail-cps">
        <h3>Checkpoints</h3>
        <div class="cp-list">
          ${cps.map((cp, i) => renderCheckpointCard(cp, i, cps.length, kms[i] || 0, color, i === cps.length - 1)).join('')}
        </div>
      </div>
    </div>
  `;

  // Init Leaflet
  if (currentMap) { currentMap.remove(); currentMap = null; }
  const allCoords = path.routes.flatMap((r) => r.coordinates || []);
  const map = L.map('path-map', {
    zoomControl: true,
    scrollWheelZoom: false,
    attributionControl: true,
  });
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 18,
    attribution: '&copy; <a href="https://openstreetmap.org/copyright">OpenStreetMap</a>',
  }).addTo(map);

  for (const r of path.routes) {
    if ((r.coordinates || []).length < 2) continue;
    L.polyline(r.coordinates, { color, weight: 4, opacity: 0.9 }).addTo(map);
  }
  cps.forEach((cp, i) => {
    const html = `<div class="map-pin"><span>${i + 1}</span></div>`;
    const icon = L.divIcon({
      html, className: 'map-pin-wrap',
      iconSize: [28, 28], iconAnchor: [14, 14],
    });
    const m = L.marker([cp.lat, cp.lng], { icon }).addTo(map);
    m.on('click', () => {
      const card = document.querySelector(`.cp-card[data-cp-id="${cp.id}"]`);
      if (card) {
        card.scrollIntoView({ behavior: 'smooth', block: 'center' });
        toggleCheckpoint(card, true);
      }
    });
  });
  if (allCoords.length > 0) {
    map.fitBounds(L.latLngBounds(allCoords), { padding: [30, 30] });
  }
  currentMap = map;

  // Wire delegated click handlers within the detail view
  detail.addEventListener('click', onDetailClick);
}

function onDetailClick(ev) {
  const target = ev.target.closest('[data-action]');
  if (!target) return;
  const action = target.dataset.action;

  if (action === 'set-provider') {
    setMapProvider(target.dataset.provider);
    document.querySelectorAll('.cp-nearby-head span').forEach((el) => {
      el.textContent = `Opens ${getMapProvider() === 'kakao' ? 'Kakao' : 'Naver'} Maps`;
    });
    return;
  }
  if (action === 'toggle') {
    const card = target.closest('.cp-card');
    toggleCheckpoint(card);
    return;
  }
  if (action === 'open-maps') {
    const card = target.closest('.cp-card');
    const cp = findCheckpoint(card.dataset.cpId);
    if (cp) openInMaps(cp);
    return;
  }
  if (action === 'nearby') {
    const card = target.closest('.cp-card');
    const cp = findCheckpoint(card.dataset.cpId);
    if (cp) searchNearby(cp, target.dataset.keyword);
    return;
  }
}

function toggleCheckpoint(card, forceOpen = false) {
  const detail = card.querySelector('.cp-detail');
  const summary = card.querySelector('.cp-summary');
  const willOpen = forceOpen || detail.hasAttribute('hidden');
  if (willOpen) {
    detail.removeAttribute('hidden');
    card.classList.add('open');
    summary.setAttribute('aria-expanded', 'true');
  } else {
    detail.setAttribute('hidden', '');
    card.classList.remove('open');
    summary.setAttribute('aria-expanded', 'false');
  }
}

let _loadedPath = null;
function findCheckpoint(id) {
  if (!_loadedPath) return null;
  return _loadedPath.checkpoints.find((c) => c.id === id);
}

async function showPathDetail(id) {
  if (currentPathId === id) return;
  currentPathId = id;
  document.body.classList.add('detail-open');
  const detail = document.getElementById('path-detail');
  detail.innerHTML = `<div class="path-detail-loading"><span class="spinner"></span> Loading path…</div>`;
  detail.scrollIntoView({ behavior: 'instant', block: 'start' });
  window.scrollTo({ top: 0, behavior: 'instant' });
  try {
    const path = await loadPath(id);
    _loadedPath = path;
    renderPathDetail(path);
  } catch (err) {
    detail.innerHTML = `<div class="container" style="padding:80px 0;text-align:center;color:var(--text-mute)">Failed to load path. <a href="#paths">Back to paths</a>.</div>`;
    console.error(err);
  }
}

function showHome() {
  document.body.classList.remove('detail-open');
  currentPathId = null;
  _loadedPath = null;
  if (currentMap) { currentMap.remove(); currentMap = null; }
  const detail = document.getElementById('path-detail');
  detail.innerHTML = '';
}

function route() {
  const m = location.hash.match(/^#\/path\/(\d+)$/);
  if (m) {
    showPathDetail(parseInt(m[1], 10));
  } else {
    showHome();
  }
}

// Wire path-card clicks to navigate via hash
function wirePathCards() {
  document.querySelectorAll('.path-card[data-path-id]').forEach((card) => {
    card.setAttribute('href', `#/path/${card.dataset.pathId}`);
  });
}

// Sticky-nav border on scroll
function wireNav() {
  const nav = document.getElementById('nav');
  if (!nav) return;
  const onScroll = () => nav.classList.toggle('scrolled', window.scrollY > 8);
  document.addEventListener('scroll', onScroll, { passive: true });
  onScroll();
}

// Reveal-on-scroll for cards and section headings
function wireReveals() {
  const targets = document.querySelectorAll('.reveal, .path-card');
  if (!targets.length) return;
  const io = new IntersectionObserver((entries) => {
    for (const e of entries) {
      if (e.isIntersecting) {
        e.target.classList.add('in-view');
        io.unobserve(e.target);
      }
    }
  }, { threshold: 0.12, rootMargin: '0px 0px -40px 0px' });
  targets.forEach((el) => io.observe(el));
}

window.addEventListener('hashchange', route);
window.addEventListener('DOMContentLoaded', () => {
  wireNav();
  wireReveals();
  wirePathCards();
  route();
});
