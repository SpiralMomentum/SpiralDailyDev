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

// 찾지 못하면 false. 핸들러는 false를 성공으로 보고하면 안 된다.
async function clickSave() {
  const btn = [...document.querySelectorAll('button')]
    .find(b => /저장|Save/i.test(b.textContent.trim()) && !b.disabled);
  if (!btn) return false;
  btn.click(); await sleep(2000);
  return true;
}

async function pickRadio(selector, index) {
  const els = document.querySelectorAll(selector);
  if (!els[index]) return false;
  els[index].click(); await sleep(400);
  return true;
}

function ok(message = '') { return { success: true, app_id: null, message }; }
function fail(message) { return { success: false, app_id: null, message: `${message} (현재: ${location.pathname})` }; }

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

// store_listing.json category(영문 키) -> Play Console 화면 라벨 [한국어, 영어]
const PLAY_CATEGORIES = {
  art_and_design: ['예술/디자인', 'Art & Design'], auto_and_vehicles: ['자동차', 'Auto & Vehicles'],
  beauty: ['뷰티', 'Beauty'], books_and_reference: ['도서/참고자료', 'Books & Reference'],
  business: ['비즈니스', 'Business'], comics: ['만화', 'Comics'], communication: ['커뮤니케이션', 'Communication'],
  dating: ['데이트', 'Dating'], education: ['교육', 'Education'], entertainment: ['엔터테인먼트', 'Entertainment'],
  events: ['이벤트', 'Events'], finance: ['금융', 'Finance'], food_and_drink: ['식음료', 'Food & Drink'],
  health_and_fitness: ['건강/운동', 'Health & Fitness'], house_and_home: ['홈/인테리어', 'House & Home'],
  libraries_and_demo: ['라이브러리/데모', 'Libraries & Demo'], lifestyle: ['라이프스타일', 'Lifestyle'],
  maps_and_navigation: ['지도/내비게이션', 'Maps & Navigation'], medical: ['의료', 'Medical'],
  music_and_audio: ['음악/오디오', 'Music & Audio'], news_and_magazines: ['뉴스/잡지', 'News & Magazines'],
  parenting: ['출산/육아', 'Parenting'], personalization: ['맞춤설정', 'Personalization'],
  photography: ['사진', 'Photography'], productivity: ['생산성', 'Productivity'], shopping: ['쇼핑', 'Shopping'],
  social: ['소셜', 'Social'], sports: ['스포츠', 'Sports'], tools: ['도구', 'Tools'],
  travel_and_local: ['여행 및 지역정보', 'Travel & Local'], video_players: ['동영상 플레이어 및 편집기', 'Video Players & Editors'],
  weather: ['날씨', 'Weather'],
};
// Play에 없는 값의 대응 (utilities는 Play의 Tools)
const CATEGORY_ALIASES = { utilities: 'tools' };

async function set_store_settings({ config, app_id }) {
  const err = checkPage(`/app/${app_id}/store-settings`);
  if (err) return err;
  const labels = PLAY_CATEGORIES[CATEGORY_ALIASES[config.category] ?? config.category];
  if (!labels) return fail(`Play 카테고리가 아닌 값: ${config.category}`);

  const edit = [...document.querySelectorAll('button')].find(b => /^(수정|Edit)$/.test(b.innerText.trim()));
  if (!edit) return fail('앱 카테고리 수정 버튼 없음');
  edit.click(); await sleep(1500);

  // 대화상자 안의 마지막 드롭다운이 카테고리 (앞은 앱/게임)
  const selects = [...document.querySelectorAll('material-dropdown-select')];
  const category = selects[selects.length - 1];
  if (!category || selects.length < 2) return fail('카테고리 드롭다운 없음');
  // dropdown-button 자체가 아니라 안쪽 role=button을 눌러야 목록이 열린다
  const opener = category.querySelector('dropdown-button [role="button"]');
  if (!opener) return fail('카테고리 드롭다운 버튼 없음');
  opener.click(); await sleep(800);
  const opt = [...document.querySelectorAll('material-select-dropdown-item')]
    .find(o => labels.includes(o.innerText.trim()));
  if (!opt) return fail(`카테고리 옵션 없음: ${labels.join(' / ')}`);
  opt.click(); await sleep(500);
  if (!await clickSave()) return fail('저장 버튼 비활성');
  return ok(labels[0]);
}

async function set_privacy_policy({ config, app_id, developer_id }) {
  const err = checkPage(`/app/${app_id}/app-content/privacy-policy`);
  if (err) return err;
  const input = document.querySelector('input[type="url"], input[type="text"]');
  if (!input) return fail('URL 입력란 없음');
  if (input.value === config.privacy_policy_url) return ok('이미 설정됨');
  input.value = config.privacy_policy_url;
  input.dispatchEvent(new Event('input', { bubbles: true }));
  input.dispatchEvent(new Event('change', { bubbles: true }));
  await sleep(500);
  if (!await clickSave()) return fail('저장 버튼 없음');
  return ok();
}

async function set_ads({ config, app_id, developer_id }) {
  const err = checkPage(`/app/${app_id}/app-content/ads-declaration`);
  if (err) return err;
  if (!await pickRadio('input[role="radio"]', config.ads ? 0 : 1)) return fail('광고 여부 라디오 버튼 없음');
  if (!await clickSave()) return fail('저장 버튼 없음');
  return ok();
}

async function set_app_access({ config, app_id, developer_id }) {
  const err = checkPage(`/app/${app_id}/app-content/testing-credentials`);
  if (err) return err;
  // 화면 순서: [0] 예(로그인 필요) [1] 아니요
  if (!await pickRadio('input[role="radio"]', config.requires_login ? 0 : 1)) return fail('로그인 필요 여부 라디오 버튼 없음');
  if (!await clickSave()) return fail('저장 버튼 없음');
  return ok();
}

// 콘텐츠 등급(IARC 설문)과 타겟층(다단계 마법사)은 항목별 답이 법적 선언이라 임의 응답으로 제출하지 않는다.
async function set_content_rating({ app_id }) {
  const err = checkPage(`/app/${app_id}/app-content/content-rating-overview`);
  if (err) return err;
  return fail('콘텐츠 등급 설문 자동화 미구현 — Play Console에서 직접 작성 필요');
}

async function set_target_audience({ app_id }) {
  const err = checkPage(`/app/${app_id}/app-content/target-audience-content`);
  if (err) return err;
  return fail('타겟층 마법사 자동화 미구현 — Play Console에서 직접 작성 필요');
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
