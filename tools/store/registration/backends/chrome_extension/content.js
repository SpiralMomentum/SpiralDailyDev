// Play Console 페이지에서 로컬 HTTP 서버(register.py가 띄움)를 폴링한다.
// GET  http://localhost:7892/cmd    → { step, config, app_id, developer_id } 또는 null
// POST http://localhost:7892/result → { success, app_id, message }

const SERVER = 'http://localhost:7892';
let running = false;

// background.js를 통해 fetch (CSP 우회)
function bgFetch(url, method = 'GET', body = null) {
  return new Promise((resolve, reject) => {
    chrome.runtime.sendMessage(
      { type: 'fetch', url, method, body: body ? JSON.stringify(body) : undefined },
      res => {
        if (chrome.runtime.lastError) return reject(new Error(chrome.runtime.lastError.message));
        if (res && res.ok) resolve(res.data);
        else reject(new Error(res ? res.error : 'no response'));
      }
    );
  });
}

function checkPage(expectedPath) {
  if (!location.pathname.includes(expectedPath)) {
    return { success: false, app_id: null, message: `페이지 불일치: 예상=${expectedPath}, 현재=${location.pathname}` };
  }
  return null;
}

async function poll() {
  if (running) return;
  let cmd;
  try {
    cmd = await bgFetch(`${SERVER}/cmd`);
  } catch {
    return;
  }
  if (!cmd || !cmd.step) return;

  running = true;
  let result;
  try {
    result = await dispatch(cmd);
  } catch (e) {
    result = { success: false, app_id: null, message: e.message };
  }
  running = false;

  await bgFetch(`${SERVER}/result`, 'POST', result).catch(() => {});
}

setInterval(poll, 1500);

// ── 헬퍼 ──────────────────────────────────────────────────

function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

async function clickSave() {
  const btn = [...document.querySelectorAll('button')]
    .find(b => /저장|Save/i.test(b.textContent.trim()));
  if (btn) { btn.click(); await sleep(2000); }
}

async function pickRadio(selector, index) {
  const els = document.querySelectorAll(selector);
  if (els[index]) { els[index].click(); await sleep(400); }
}

// ── 단계별 핸들러 (navigation 없음 — server.py가 직접 이동시킴) ──────

async function create_app({ config, developer_id }) {
  document.querySelectorAll('input').forEach(el => {
    if (/name|title/i.test(el.name + el.placeholder)) el.value = config.name_en;
    if (/package/i.test(el.name + el.placeholder))    el.value = config.package_name;
    el.dispatchEvent(new Event('input', { bubbles: true }));
  });
  await pickRadio('input[role="radio"]', config.app_type === 'game' ? 1 : 0);
  await pickRadio('input[role="radio"]', config.monetization === 'free' ? 2 : 3);
  return { success: true, app_id: null, message: '법적 동의 체크 후 "앱 만들기" 클릭 필요' };
}

async function set_store_settings({ config, app_id, developer_id }) {
  const err = checkPage(`/app/${app_id}/store-settings`);
  if (err) return err;
  const sel = document.querySelector('mat-select');
  if (sel) {
    sel.click(); await sleep(500);
    const opt = [...document.querySelectorAll('mat-option')]
      .find(o => o.getAttribute('value') === config.category || o.textContent.includes(config.category));
    if (opt) { opt.click(); await sleep(300); }
  }
  await clickSave();
  return { success: true, app_id: null, message: '' };
}

async function set_privacy_policy({ config, app_id, developer_id }) {
  const err = checkPage(`/app/${app_id}/app-content/privacy-policy`);
  if (err) return err;
  const input = document.querySelector('input[type="url"], input[type="text"]');
  if (input) {
    input.value = config.privacy_policy_url;
    input.dispatchEvent(new Event('input', { bubbles: true }));
    input.dispatchEvent(new Event('change', { bubbles: true }));
    await sleep(500);
  }
  await clickSave();
  return { success: true, app_id: null, message: '' };
}

async function set_ads({ config, app_id, developer_id }) {
  const err = checkPage(`/app/${app_id}/app-content/ads`);
  if (err) return err;
  await pickRadio('input[role="radio"]', config.ads ? 1 : 0);
  await clickSave();
  return { success: true, app_id: null, message: '' };
}

async function set_app_access({ config, app_id, developer_id }) {
  const err = checkPage(`/app/${app_id}/app-content/app-access`);
  if (err) return err;
  await pickRadio('input[role="radio"]', config.requires_login ? 1 : 0);
  await clickSave();
  return { success: true, app_id: null, message: '' };
}

async function set_content_rating({ config, app_id, developer_id }) {
  // 페이지가 맞는지 확인 (ratings 페이지가 아니면 리다이렉트된 것)
  const expectedPath = `/app/${app_id}/app-content/ratings`;
  if (!location.pathname.includes(expectedPath)) {
    return { success: false, app_id: null, message: `ratings 페이지 접근 불가 (현재: ${location.pathname}) — APK 업로드 후 가능` };
  }
  const startBtn = [...document.querySelectorAll('button')]
    .find(b => /시작|Start/i.test(b.textContent));
  if (!startBtn) {
    // 이미 완료된 상태일 수 있음
    const ratingBadge = document.querySelector('[class*="rating-badge"], [class*="content-rating"]');
    if (ratingBadge) return { success: true, app_id: null, message: '이미 완료' };
    return { success: false, app_id: null, message: '시작 버튼 없음 — 설문 접근 불가' };
  }
  startBtn.click(); await sleep(2000);
  document.querySelectorAll('input[role="radio"]').forEach((r, i) => {
    if (i % 2 === 0) r.click();
  });
  await sleep(500);
  const calcBtn = [...document.querySelectorAll('button')]
    .find(b => /계산|Calculate/i.test(b.textContent));
  if (calcBtn) { calcBtn.click(); await sleep(2000); }
  await clickSave();
  return { success: true, app_id: null, message: '' };
}

async function set_target_audience({ config, app_id, developer_id }) {
  const err = checkPage(`/app/${app_id}/app-content/target-audience-and-content`);
  if (err) return err;
  const idx = { all: 0, teen: 1, adult: 2 }[config.target_age ?? 'all'] ?? 0;
  await pickRadio('input[role="radio"]', idx);
  await clickSave();
  return { success: true, app_id: null, message: '' };
}

const HANDLERS = {
  create_app, set_store_settings, set_privacy_policy,
  set_ads, set_app_access, set_content_rating, set_target_audience,
};

async function dispatch(cmd) {
  const h = HANDLERS[cmd.step];
  if (!h) return { success: false, app_id: null, message: `unknown step: ${cmd.step}` };
  return h(cmd);
}
