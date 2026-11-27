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

// 이미 원하는 값이 저장된 화면에서는 저장 버튼이 비활성이므로, 선택 상태로 성공을 판정한다.
function radioChecked(selector, index) {
  const el = document.querySelectorAll(selector)[index];
  return !!el && (el.checked || el.getAttribute('aria-checked') === 'true');
}

async function chooseRadioAndSave(selector, index, what) {
  if (radioChecked(selector, index)) return ok('이미 설정됨');
  if (!await pickRadio(selector, index)) return fail(`${what} 라디오 버튼 없음`);
  if (!await clickSave()) return fail('저장 버튼 없음');
  return ok();
}

// "카테고리\n도구" 처럼 라벨과 값이 한 행에 표시된 읽기 전용 값
function shownValue(label) {
  const leaf = [...document.querySelectorAll('*')]
    .find(e => e.children.length === 0 && e.innerText && e.innerText.trim() === label);
  let row = leaf;
  while (row && row.innerText.trim() === label) row = row.parentElement;
  return row ? row.innerText.trim().slice(label.length).trim() : null;
}

function ok(message = '') { return { success: true, app_id: null, message }; }
function fail(message) { return { success: false, app_id: null, message: `${message} (현재: ${location.pathname})` }; }

// ── 단계별 핸들러 (navigation 없음 — server.py가 직접 이동시킴) ──────

function visible(el) { return el.offsetParent !== null; }

function buttonByText(text) {
  return [...document.querySelectorAll('button')].filter(visible)
    .find(b => b.innerText.trim() === text && !b.disabled);
}

async function clickButton(text, wait = 2500) {
  const b = buttonByText(text);
  if (!b) return false;
  b.click(); await sleep(wait);
  return true;
}

// material 컴포넌트는 aria-checked를 비워 두므로 안쪽 input.checked로 판정한다.
function isChecked(el) { return !!el.querySelector('input')?.checked; }

async function check(el) {
  if (!isChecked(el)) { el.click(); await sleep(400); }
  return isChecked(el);
}

function byText(selector, predicate) {
  return [...document.querySelectorAll(selector)].filter(visible).find(e => predicate(e.innerText.trim()));
}

function setInput(input, value) {
  input.value = value;
  input.dispatchEvent(new Event('input', { bubbles: true }));
  input.dispatchEvent(new Event('change', { bubbles: true }));
}

// 입력란 위쪽에 처음 나오는 텍스트 줄을 라벨로 본다 (예: "이메일 주소 *").
function inputLabel(input) {
  let el = input;
  for (let k = 0; k < 8 && el; k++) {
    el = el.parentElement;
    const line = (el?.innerText || '').trim().split('\n')[0];
    if (line) return line;
  }
  return '';
}

function inputByLabel(prefix) {
  return [...document.querySelectorAll('input')].filter(visible).find(i => inputLabel(i).startsWith(prefix));
}

// 기본 언어 스토어 등록정보 제목이 Play 앱 이름이 된다 (30자 제한).
function playAppName(config) {
  const lang = (config.default_language || 'en-US').split('-')[0];
  const title = config.store_text?.android?.[lang]?.title;
  return title || (lang === 'ko' ? config.name_ko : config.name_en);
}

async function create_app({ config }) {
  const err = checkPage('/create-new-app');
  if (err) return err;
  const name = inputByLabel('앱 이름') ?? document.querySelector('input[aria-label="앱 이름"]');
  const pkg = document.querySelector('input[aria-label="App package name"]');
  if (!name || !pkg) return fail('앱 이름/패키지 입력란 없음');
  setInput(name, playAppName(config));
  setInput(pkg, config.package_name);

  const language = [...document.querySelectorAll('material-dropdown-select')].find(visible);
  const opener = language?.querySelector('dropdown-button [role="button"]');
  if (!opener) return fail('기본 언어 드롭다운 없음');
  opener.click(); await sleep(800);
  const lang = [...document.querySelectorAll('material-select-dropdown-item')]
    .find(o => o.innerText.trim().endsWith(`– ${config.default_language}`));
  if (!lang) return fail(`기본 언어 옵션 없음: ${config.default_language}`);
  lang.click(); await sleep(500);

  const radio = label => byText('material-radio', t => t === label);
  for (const label of [config.app_type === 'game' ? '게임' : '앱', config.monetization === 'free' ? '무료' : '유료']) {
    const r = radio(label);
    if (!r || !await check(r)) return fail(`"${label}" 선택 실패`);
  }

  // 개발자 프로그램 정책·미국 수출법 동의는 사용자가 --accept-terms로 명시한 경우에만 체크한다.
  if (!config._accept_terms) return ok('법적 동의 체크 후 "앱 만들기" 클릭 필요');
  for (const c of [...document.querySelectorAll('material-checkbox')].filter(visible)) {
    if (!await check(c)) return fail(`동의 체크 실패: ${c.innerText.trim().slice(0, 30)}`);
  }
  if (!await clickButton('앱 만들기', 1000)) return fail('"앱 만들기" 버튼 비활성 (이름/패키지 중복 여부 확인)');
  return ok('앱 만들기 클릭');
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

// 화면의 [0] 수정 = 앱 카테고리, [1] 수정 = 스토어 등록정보 연락처 세부정보
function editButtons() {
  return [...document.querySelectorAll('button')].filter(b => /^(수정|Edit)$/.test(b.innerText.trim()));
}

async function set_store_settings({ config, app_id }) {
  const err = checkPage(`/app/${app_id}/store-settings`);
  if (err) return err;
  const category = await setCategory(config);
  if (!category.success) return category;
  const contact = await setContact(config);
  if (!contact.success) return contact;
  return ok(`카테고리: ${category.message}, 연락처: ${contact.message}`);
}

// 연락처 이메일이 없으면 출시 화면에서 "아직 앱을 게시할 수 없습니다"로 막힌다.
async function setContact(config) {
  if (!config.contact_email) return fail('contact_email 없음');
  const current = shownValue('이메일 주소');
  if (current?.split('\n')[0].trim() === config.contact_email) return ok('이미 설정됨');
  const edit = editButtons()[1];
  if (!edit) return fail('연락처 세부정보 수정 버튼 없음');
  edit.click(); await sleep(1500);
  const email = inputByLabel('이메일 주소');
  if (!email) return fail('연락처 이메일 입력란 없음');
  setInput(email, config.contact_email);
  const site = inputByLabel('https://');
  if (site && !site.value && config.support_url) setInput(site, config.support_url);
  await sleep(500);
  if (!await clickButton('저장 및 출시', 2500)) return fail('연락처 "저장 및 출시" 버튼 비활성');
  return ok(config.contact_email);
}

async function setCategory(config) {
  const labels = PLAY_CATEGORIES[CATEGORY_ALIASES[config.category] ?? config.category];
  if (!labels) return fail(`Play 카테고리가 아닌 값: ${config.category}`);
  const current = shownValue('카테고리') ?? shownValue('Category');
  if (current && labels.includes(current)) return ok(`이미 설정됨 ${current}`);

  const edit = editButtons()[0];
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
  return chooseRadioAndSave('input[role="radio"]', config.ads ? 0 : 1, '광고 여부');
}

async function set_app_access({ config, app_id, developer_id }) {
  const err = checkPage(`/app/${app_id}/app-content/testing-credentials`);
  if (err) return err;
  // 화면 순서: [0] 예(로그인 필요) [1] 아니요
  return chooseRadioAndSave('input[role="radio"]', config.requires_login ? 0 : 1, '로그인 필요 여부');
}

// 콘텐츠 등급(IARC 설문)과 타겟층은 항목별 답이 법적 선언이다.
// store_listing.json이 모든 답을 "아니요"로 정할 수 있는 경우(일반 앱, 등급 관련 콘텐츠·상호작용·구매 없음)만
// 자동으로 제출하고, 하나라도 "예"가 필요한 앱은 하위 질문이 열리므로 사람에게 넘긴다.
const IARC_YES_FIELDS = ['content_violence', 'content_gambling', 'content_adult',
  'content_user_interaction', 'content_digital_purchases'];

function questionGroups() {
  return [...document.querySelectorAll('material-radio-group')].filter(visible);
}

async function set_content_rating({ config, app_id }) {
  const err = checkPage(`/app/${app_id}/app-content/content-rating`);
  if (err) return err;
  if (config.app_type === 'game') return fail('게임 카테고리 설문은 자동화 대상 아님 — 직접 작성 필요');
  const yes = IARC_YES_FIELDS.filter(f => config[f]);
  if (yes.length) return fail(`"예" 답변 필요 (${yes.join(', ')}) — 하위 질문이 있어 직접 작성 필요`);
  if (!config._accept_terms) return fail('IARC 약관 동의 필요 — --accept-terms로 실행하거나 직접 작성');
  if (!config.contact_email) return fail('contact_email 없음');

  if (!await clickButton('설문지 시작', 3500)) {
    // 이미 제출된 앱의 개요 화면에는 시작 버튼이 없다.
    return /전체이용가|PEGI|만 \d+세 이상/.test(document.body.innerText) ? ok('이미 제출됨') : fail('"설문지 시작" 버튼 없음');
  }

  // 1단계: 카테고리
  const email = [...document.querySelectorAll('input[type="email"]')].find(visible);
  if (!email) return fail('IARC 이메일 입력란 없음');
  setInput(email, config.contact_email);
  const other = byText('material-radio', t => t.startsWith('다른 모든 앱 유형'));
  if (!other || !await check(other)) return fail('"다른 모든 앱 유형" 선택 실패');
  const terms = byText('material-checkbox', t => t.includes('IARC'));
  if (!terms || !await check(terms)) return fail('IARC 약관 체크 실패');
  if (!await clickButton('다음', 3000)) return fail('카테고리 "다음" 버튼 비활성');

  // 2단계: 설문. 답할 때마다 질문이 늘 수 있어 남은 질문이 없을 때까지 하나씩 답한다.
  for (let i = 0; i < 30; i++) {
    const open = questionGroups().find(g => ![...g.querySelectorAll('input')].some(x => x.checked));
    if (!open) break;
    const no = [...open.querySelectorAll('material-radio')].find(r => r.innerText.trim() === '아니요');
    if (!no) return fail('"아니요" 선택지가 없는 질문');
    no.click(); await sleep(300);
  }
  const answered = questionGroups().length;
  if (!answered) return fail('설문 질문을 찾지 못함');
  if (!await clickButton('저장', 3000)) return fail('설문 "저장" 버튼 없음');
  if (!await clickButton('다음', 3500)) return fail('설문 "다음" 버튼 비활성');

  // 3단계: 요약 확인 후 제출
  const rating = /전체이용가/.test(document.body.innerText) ? '전체이용가' : '요약 확인 필요';
  if (!await clickButton('저장', 4000)) return fail('요약 "저장" 버튼 없음');
  return ok(`질문 ${answered}개 아니요, 등급 ${rating}`);
}

// 만 18세 이상만 고르면 아동 관련 단계 없이 바로 요약으로 간다. 그 밖의 연령대는 추가 질문이 있어 직접 작성한다.
async function set_target_audience({ config, app_id }) {
  const err = checkPage(`/app/${app_id}/app-content/target-audience-content`);
  if (err) return err;
  if (config.target_age !== 'adult') return fail(`target_age=${config.target_age}는 추가 질문이 있어 직접 작성 필요`);

  const ages = [...document.querySelectorAll('material-checkbox')].filter(visible);
  if (!ages.length) {
    return /만 18세 이상/.test(document.body.innerText) ? ok('이미 설정됨') : fail('연령대 체크박스 없음');
  }
  for (const c of ages) {
    const want = c.innerText.trim() === '만 18세 이상';
    if (isChecked(c) !== want) { c.click(); await sleep(300); }
  }
  if (!await clickButton('다음', 3000)) return fail('연령대 "다음" 버튼 비활성');
  if (!/대상 연령대는 만 18세 이상/.test(document.body.innerText)) return fail('요약 화면이 아님 — 추가 단계 확인 필요');
  if (!await clickButton('저장', 3500)) return fail('요약 "저장" 버튼 없음');
  return ok('만 18세 이상');
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
