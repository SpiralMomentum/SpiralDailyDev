#!/usr/bin/env node
/**
 * Playwright 백엔드 CLI.
 * 계약: tools/store/registration/contract.json
 *
 * 의존성: npm install playwright && npx playwright install chromium
 *
 * 출력: stdout에 JSON 한 줄
 * 로그: stderr
 */

const { chromium } = require('playwright');

const CONSOLE_BASE = 'https://play.google.com/console/u/0/developers';

function out(result) {
  process.stdout.write(JSON.stringify(result) + '\n');
}

function log(msg) {
  process.stderr.write(`[playwright] ${msg}\n`);
}

function parseArgs() {
  const args = process.argv.slice(2);
  const get = (flag) => {
    const i = args.indexOf(flag);
    return i !== -1 ? args[i + 1] : null;
  };
  return {
    step: get('--step'),
    config: JSON.parse(get('--config') || '{}'),
    appId: get('--app-id'),
    developerId: get('--developer-id'),
  };
}

async function withPage(fn) {
  const profileDir = `${process.env.HOME}/.playwright-play-console`;
  const context = await chromium.launchPersistentContext(profileDir, {
    headless: false,
    channel: 'chrome',
    args: ['--disable-blink-features=AutomationControlled'],
  });
  const page = await context.newPage();
  try {
    await page.goto('https://play.google.com/console');
    await page.waitForTimeout(2000);
    if (page.url().includes('accounts.google.com') || page.url().includes('signin')) {
      log('Google 로그인이 필요합니다. 브라우저에서 로그인하면 자동으로 진행됩니다...');
      // 로그인 완료 = play.google.com/console 으로 리디렉션될 때까지 대기
      await page.waitForURL('**/console/**', { timeout: 120000 });
      log('로그인 감지됨. 계속 진행합니다.');
    }
    return await fn(page);
  } finally {
    await context.close();
  }
}

async function createApp(page, { config, developerId }) {
  await page.goto(`${CONSOLE_BASE}/${developerId}/create-new-app`);
  await page.waitForURL('**/create-new-app**');

  await page.fill('input[name="title"]', config.name_en);
  await page.fill('input[placeholder*="package"]', config.package_name);

  const appType = config.app_type === 'game' ? 'GAME' : 'APPLICATION';
  await page.locator(`mat-radio-button[value="${appType}"] input`).click();

  const price = config.monetization === 'free' ? 'FREE' : 'PAID';
  await page.locator(`mat-radio-button[value="${price}"] input`).click();

  log('법적 동의 체크박스 2개를 직접 체크한 뒤 엔터를 누르세요.');
  await new Promise(r => process.stdin.once('data', r));

  await page.locator('button[type="submit"]').click();
  await page.waitForURL('**/app-dashboard**', { timeout: 15000 });

  const match = page.url().match(/\/app\/(\d+)\//);
  return { success: true, app_id: match?.[1] ?? null, message: '' };
}

async function setStoreSettings(page, { config, appId, developerId }) {
  await page.goto(`${CONSOLE_BASE}/${developerId}/app/${appId}/store-settings`);
  await page.locator('mat-select').first().click();
  await page.locator(`mat-option[value="${config.category}"]`).click();
  await page.locator('button[type="submit"]').click();
  await page.waitForTimeout(1500);
  return { success: true, app_id: null, message: '' };
}

async function setPrivacyPolicy(page, { config, appId, developerId }) {
  await page.goto(`${CONSOLE_BASE}/${developerId}/app/${appId}/app-content/privacy-policy`);
  await page.waitForTimeout(2000);

  // URL 입력 필드
  const input = page.locator('input[type="url"], input[type="text"]').first();
  await input.fill(config.privacy_policy_url);

  // 저장 버튼 — Play Console은 텍스트 기반
  const saveBtn = page.locator('button:has-text("저장"), button:has-text("Save")').first();
  await saveBtn.click();
  await page.waitForTimeout(2000);
  return { success: true, app_id: null, message: '' };
}

async function setAds(page, { config, appId, developerId }) {
  await page.goto(`${CONSOLE_BASE}/${developerId}/app/${appId}/app-content/ads`);
  const value = config.ads ? 'YES' : 'NO';
  await page.locator(`input[role="radio"][value="${value}"], mat-radio-button[value="${value}"] input`).first().click();
  await page.locator('button[type="submit"]').click();
  await page.waitForTimeout(1500);
  return { success: true, app_id: null, message: '' };
}

async function setAppAccess(page, { config, appId, developerId }) {
  await page.goto(`${CONSOLE_BASE}/${developerId}/app/${appId}/app-content/app-access`);
  const idx = config.requires_login ? 1 : 0;
  await page.locator('input[role="radio"]').nth(idx).click();
  await page.locator('button[type="submit"]').click();
  await page.waitForTimeout(1500);
  return { success: true, app_id: null, message: '' };
}

async function setContentRating(page, { config, appId, developerId }) {
  await page.goto(`${CONSOLE_BASE}/${developerId}/app/${appId}/app-content/ratings`);
  await page.locator('button:has-text("시작"), button:has-text("Start")').click();
  await page.waitForTimeout(2000);
  // content_* = false → 모든 질문에 첫 번째(없음/아니오) 선택
  const radios = await page.locator('input[role="radio"]').all();
  for (let i = 0; i < radios.length; i += 2) await radios[i].click();
  await page.locator('button:has-text("계산"), button:has-text("Calculate")').click();
  await page.waitForTimeout(2000);
  await page.locator('button[type="submit"]').click();
  await page.waitForTimeout(1500);
  return { success: true, app_id: null, message: '' };
}

async function setTargetAudience(page, { config, appId, developerId }) {
  await page.goto(`${CONSOLE_BASE}/${developerId}/app/${appId}/app-content/target-audience-and-content`);
  const ageMap = { all: 0, teen: 1, adult: 2 };
  const idx = ageMap[config.target_age ?? 'all'] ?? 0;
  await page.locator('input[role="radio"]').nth(idx).click();
  await page.locator('button[type="submit"]').click();
  await page.waitForTimeout(1500);
  return { success: true, app_id: null, message: '' };
}

const STEP_FN = {
  create_app:          createApp,
  set_store_settings:  setStoreSettings,
  set_privacy_policy:  setPrivacyPolicy,
  set_ads:             setAds,
  set_app_access:      setAppAccess,
  set_content_rating:  setContentRating,
  set_target_audience: setTargetAudience,
};

(async () => {
  const args = parseArgs();
  const fn = STEP_FN[args.step];
  if (!fn) {
    out({ success: false, app_id: null, message: `unknown step: ${args.step}` });
    process.exit(1);
  }
  try {
    const result = await withPage(page => fn(page, args));
    out(result);
  } catch (e) {
    out({ success: false, app_id: null, message: e.message });
    process.exit(1);
  }
})();
