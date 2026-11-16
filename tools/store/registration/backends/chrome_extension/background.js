// content.js의 fetch 요청을 대신 처리한다.
// background service worker는 페이지 CSP 영향을 받지 않는다.

chrome.runtime.onMessage.addListener((msg, _sender, sendResponse) => {
  if (msg.type !== 'fetch') return;

  const { url, method = 'GET', body } = msg;
  const opts = {
    method,
    headers: { 'Content-Type': 'application/json' },
    cache: 'no-store',
  };
  if (body) opts.body = body;

  fetch(url, opts)
    .then(r => r.json())
    .then(data => sendResponse({ ok: true, data }))
    .catch(e  => sendResponse({ ok: false, error: e.message }));

  return true; // 비동기 응답
});
