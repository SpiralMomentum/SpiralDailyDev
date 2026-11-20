# WUXIA 채널 문체 리서치 (ko / en / ja / zh)

작성일: 2026-11-19. 대상: self_eval_sim 결과 화면 "백발의 검객" 마무리 한 줄.
원문 HTML/텍스트는 `research/raw/` 에 보관(재검증용).

## 0. 수집 방법과 한계 (먼저 읽을 것)

- 공개 페이지만 열람, 로그인 없음. 도구: curl(일반 브라우저 UA) + WebFetch + WebSearch.
- **robots.txt 준수 관련 공개**: 아래 두 곳은 robots.txt를 *사후에* 확인했다.
  - `namu.wiki` robots.txt: `User-agent: * / Disallow: /` (전 크롤러 차단). 문서 약 30개를 단건 조회한 뒤 이를 확인했고, 이후로는 더 조회하지 않았다. 아래 표에 [N]으로 표시한다. 엄격히 robots 기준만 적용하려면 [N] 근거는 빼고 보면 된다. 그러면 ko 근거가 약해지며, 해당 행에는 "N 제외 시" 출처 수를 따로 적었다.
  - `gall.dcinside.com` robots.txt: `User-agent: ClaudeBot / Disallow: /`. 무협 갤러리(id=heroism) 목록 페이지를 몇 번 불러온 뒤 이를 확인했다. **DC 본문 내용은 근거로 쓰지 않았다.**
- robots에 막혀 열지 않은 곳(검색 스니펫만 썼거나 아예 쓰지 않음): reddit(old.reddit `Disallow: /`), TVTropes(`ClaudeBot Disallow`), MetaFilter, pixiv百科(`ClaudeBot` 차단), baike.baidu(`Disallow: /`), jinyongbook(`ClaudeBot Disallow`).
- 403이나 Cloudflare 차단으로 열지 못한 곳: NovelUpdates 포럼(전체), 百度贴吧, ニコニコ大百科, 萌娘百科, arca.live.
- JS 렌더링 때문에 본문이 없던 곳: 문피아 강호정담. 조아라와 네이버 시리즈 댓글은 확인하지 못했다(동적 페이지, 조아라 robots는 `/book/comment/`, `/freeboard/` 차단).
- **"[S]" 표시는 검색엔진 스니펫이다.** 검색 도구가 요약한 문장이 섞여 있을 수 있으므로 원문 대조 전에는 팩트로 쓰지 않는다. 인용 부호 안 문장은 원문에서 그대로 따온 것이다(fetched 표시가 있는 경우).
- "추론"으로 표시한 줄은 출처가 없는 필자 판단이다.

---

## 1. 한국어 (ko)

### 1.1 확인한 커뮤니티/페이지

| ID | URL | 상태 |
|---|---|---|
| K1 | https://namu.wiki/w/무협물/용어 | fetched [N] |
| K2 | https://namu.wiki/w/하오체 | fetched [N] |
| K3 | https://namu.wiki/w/하게체 | fetched [N] |
| K4 | https://namu.wiki/w/경지 | fetched [N] |
| K5 | https://namu.wiki/w/천외천 | fetched [N] |
| K6 | https://namu.wiki/w/매화검수 | fetched [N] |
| K7 | https://namu.wiki/w/무림에서%20경계해야%20할%20자들 | fetched [N] |
| K8 | https://namu.wiki/w/무틀딱 (디시 무협갤 독자 문화 설명) | fetched [N] |
| K9 | https://namu.wiki/w/판협지 | fetched [N] |
| K10 | https://m.ruliweb.com/community/board/300779/read/40248504 (루리웹, 무협 공식 조롱글) | fetched |
| K11 | https://m.ruliweb.com/community/board/300143/read/58146000 (루리웹, 무협 말투 고충) | fetched |
| K12 | https://www.korean.go.kr/nkview/nklife/2016_4/26_0416.pdf (국립국어원『새국어생활』 2016-4, 「몇몇 웹 소설을 읽고」) | fetched |
| K13 | https://gall.dcinside.com/board/lists/?id=heroism (디시 무협 갤러리) | robots가 ClaudeBot 차단, 내용 미사용 |
| K14 | https://gall.dcinside.com/mgallery/board/view/?id=tgijjdd&no=786476 ("노인 말투 팁 있음?") | [S]만 확인, 미사용 |
| K15 | 문피아 강호정담 https://www.munpia.com/page/j/view/w/ganghoJungdam | JS 렌더링, 본문 없음 |
| K16 | 조아라, 네이버 시리즈 댓글 | 확인 못 함 |

### 1.2 문체 규칙 (LLM 프롬프트용)

1. **2인칭은 "너", 해라체로 통일한다.** 고정 reveal 문장("너는 {title} 같은 사람이다.")이 이미 해라체이므로 마무리 줄에서 하게체("자네")나 하오체("그대 ~하오")로 바꾸지 않는다. (근거: 고정 문장 형식. 하게체/하오체가 무협에서 쓰인다는 사실 자체는 K2, K3에 있음. 혼용 금지는 추론)
   - 참고: 하게체는 "자신의 권위를 드러내면서도 격식을 차리기 좋은 말투"(K3), 하오체는 "무협물에서도 예스러우면서도 위엄있어 보이는 느낌 때문에 상당히 자주 보인다"(K2). 하게체 문서에도 같은 취지의 문장이 있다: "무협물 에서도 예스러우면서도 위엄있어 보이는 느낌 때문에 상당히 자주 보인다"(K3).
2. **종결은 단정형(-다, -느니라, -는 법이다)과 명령형(-거라, -하지 마라)만 쓴다.** "-것 같다" 같은 추측형은 쓰지 않는다. (추론. 고수가 경지를 판정하는 장면은 서열을 단정하는 어법이다. K4 "삼류 → 이류 → 일류 → 절정 → 초절정 → 화경 → 현경 → 생사경")
3. **한 문장, 대략 20~45자.** 쉼표로 앞뒤 대구를 만들고("A는 ~하나, B는 ~한다") 뒷절에서 판정한다. (추론)
4. **번역투를 피한다.** "~한 성질의 것", "~한 종류의 것", "~의 ~의" 겹침, "~를 필요로 하다"는 쓰지 않는다. 국립국어원 글은 무협 웹소설 예문을 들며 "'성질의 것', '종류의 것'으로 묶어서 말하는 버릇"을 "군더더기"라고 지적했다(K12).
5. **현대 인터넷 말투를 섞지 않는다.** 작가 커뮤니티에서도 "K네티즌식 말투 싫어해서 최대한 담담하게 쓰는데도 되게 현대판타지 같네"라는 고충이 나온다(K11). 담담하게 쓴다.
6. **한자어 성어는 한 줄에 하나만**, 그리고 풀어 쓴 우리말 구절로 넣는다(예: "유능제강" 대신 "부드러움이 굳셈을 누른다"). 국립국어원 글이 꼽은 무협의 걸림돌은 "그 세계에서 노는 말들이 좀 낯설고"였다(K12). 풀어 쓰자는 처방 자체는 추론이다.
7. **장르 어휘는 강호, 경지, 검, 한 수, 고수 정도만 쓴다.** 내공 수치나 혈도 명칭 같은 설정 용어(K1에 수십 개)는 마무리 줄에 넣지 않는다. (추론: 성격 결과에 설정 용어가 들어가면 의미가 흐려진다)
8. **유파 고정관념에 맞춘다.** 화산은 매화(K6: "매화꽃 형상이 피어오른다는 설정"), 당문은 암기(zh 근거 C3: "唐门主要的特色，在于“暗器”与“毒药”"), 무당은 태극과 유(柔)(K1의 묘리 항목 "유(柔): 상대의 힘을 흘러보내거나 역이용하는 묘리"), 낭인은 "떠돌이 무인"(K1).

### 1.3 상투 표현 표

| 표현 | 뜻 | 기원 | 출처 수 | URL / 인용 |
|---|---|---|---|---|
| 강호(江湖) | 무인들의 세계 | 『장자』 "相忘於江湖" (en.wiktionary 江湖) | 4 (N 제외 시 3) | K6 [N] "강호의 중역이 될 수는 있다" / https://en.wiktionary.org/wiki/江湖 "From: Zhuangzi" / https://en.wikipedia.org/wiki/Jianghu / K12 예문 제목 ≪강호 제일 해결사≫ |
| 경지(境地) | 무공의 성취 단계 | 중국어 境界의 한국식 대응 | 2 (N 제외 시 1) | K4 "무림인의 실력이나 성취를 표현하는 개념. 중국어로는 '경계(境界)'" / https://www.wuxiaworld.com/page/glossary (영어권 "Realm" 단계표) |
| 천외천(天外天) / 산 위에 산 | 위에는 늘 더 높은 고수가 있다 | 民間 성어 | 2 (N 제외 시 1) | K5 "절정 고수의 위에 또 다른 규격 외 고수가 있다" / https://zh.wiktionary.org/wiki/天外有天 (404, 미확인) → 실질 1~2 |
| 후생가외(後生可畏) | 젊은이는 두려워할 만하다 | 『논어』 자한 | 3 | https://en.wiktionary.org/wiki/後生可畏 "From the Analects, Book 9" / https://zh.wiktionary.org/wiki/后生可畏 / https://ja.wikipedia.org/wiki/後生畏るべし "『 論語 』の子罕篇" |
| 청출어람(靑出於藍) | 제자가 스승을 넘어섬 | 『순자』 권학 | 2 | https://zh.wiktionary.org/wiki/青出于蓝 "源自《 荀子 · 勸學 》" / [S] https://sgsg.hankyung.com/article/2019082324851 |
| 유능제강(柔能制剛) / 이유극강 | 부드러움이 굳셈을 이김 | 『삼략』, 『도덕경』 | 3 | https://ja.wikipedia.org/wiki/柔よく剛を制す "『 三略 』という 兵法書 から来ている" / https://zh.wiktionary.org/wiki/以柔克刚 (成語) / [S] https://m.cafe.daum.net/Noja/2NZ5/1151 |
| 사량발천근(四兩撥千斤) | 넉 냥으로 천 근을 튕겨냄 | 태극권보(권경) | 3 (N 제외 시 2) | https://namu.wiki/w/태극권 [N] "사량발천근 은 4량 힘으로 1000근을 상대한다는 뜻" / https://en.wikipedia.org/wiki/Tai_chi "\"4oz moves 1000lbs\" (四两拨千斤)" / https://en.wiktionary.org/wiki/四兩撥千斤 (Idiom) |
| 명창이타 암전난방(明槍易躲 暗箭難防) | 드러난 창은 피해도 숨은 화살은 막기 어렵다 | 민간 속담(諺語) | 2 | https://en.wiktionary.org/wiki/明槍易躲，暗箭難防 (Proverb) / https://zh.wiktionary.org/wiki/明枪易躲，暗箭难防 (諺語) |
| 지피지기 백전불태 | 상대와 나를 알면 위태롭지 않다 | 『손자』 모공 | 2 | https://en.wiktionary.org/wiki/知己知彼，百戰不殆 "From The Art of War" / https://zh.wiktionary.org/wiki/知己知彼，百战不殆 |
| 상선약수(上善若水) | 최고의 선은 물과 같다 | 『도덕경』 8장 | 1 (사전) | https://en.wiktionary.org/wiki/上善若水 "From the Tao Te Ching" (장르 내 사용 근거는 미확보) |
| 노인/아이/여인을 조심하라 | 겉보기 약자를 얕보지 마라 | 장르 내 관습(현대) | 1 [N] | K7 "흔히들 무림에서는 노인, 아이, 여인, 장애인을 조심하라고 하며" |

### 1.4 독자가 조롱하거나 식상해하는 것 (피할 것)

- "본회/본각/본련의 계획을 방해하다니" 식의 정체불명 단체 대사. K10: "" 본회의 ,본각의 ...본련의 계획을 방해하다니 " 이런걸로 의문의 단체 등장시키는데 한권소비함."
- 천편일률적인 회귀·망나니 공식. K10: "현재의 무협은 너무나 천편일률적으로 플롯이 똑같음.", 댓글: "무협 소설 자체가 너무 클리셰가 심한데"
- 양산형 판협지의 반복 묘사. K9 [N]: "술을 마셨다 하면 죽엽청 과 여아홍 뿐이요", "유사한 패턴 반복과 그로 인해 식상함을 느낀 독자들의 이탈"
- 번역투 군더더기("성질의 것", "종류의 것", "~를 필요로 하다"). K12에 근거.
- 정통파 독자(무틀딱)의 기준: 무협이 아닌 요소를 무협이라 우기면 반발한다. K8 [N]: "정통 무협과 괴리되는 내용이 나올 때마다 노호성을 터뜨리며". 시사점(추론): 현대 심리학 용어("MBTI", "자존감")를 사부 대사에 넣지 않는다.
- 한국 무협 고유 설정을 다른 언어로 그대로 옮기는 것. "매화검수"는 K6에 따르면 "한국의 무협지에서" 쓰는 용어이고, "낭인"은 K1에 따르면 "김용을 위시한 정통 무협의 용어가 아니며 … 일본 찬바라 의 영향"이다. zh/en 번역 시 주의(아래 4장).

### 1.5 마무리 줄 초안 (오리지널, 각 3개)

화산의 매화검수 (곧음)
1. 곧은 검은 쉬이 부러진다 하나, 휘는 검으로는 끝내 아무것도 베지 못한다.
2. 매화는 추위를 지나야 향이 나는 법이다. 네 고집도 겨울을 넘기면 향이 되리라.
3. 강하면 부러진다는 말을 두려워 말고, 부러지지 않을 만큼 강해지거라.

무당의 태극권사 (유연, 균형)
1. 물은 바위와 다투지 않으나 끝내 바위를 뚫는다. 네 부드러움을 약함이라 여기지 마라.
2. 넉 냥으로 천 근을 흘려보내는 자는 굳이 먼저 검을 뽑지 않는다.
3. 부드러움이 굳셈을 누르는 것은 버텨서가 아니라, 칼끝이 닿을 자리에 없어서다.

바람 같은 낭인 (자유)
1. 구름은 머물 곳을 묻지 않는다. 다만 비가 되어 내릴 자리만은 스스로 고르거라.
2. 강호는 넓다. 서로를 잊고 사는 것도 강호의 도리니라.
3. 매인 데 없는 발이 가장 멀리 간다. 돌아올 길 하나만은 잊지 마라.

당문의 암기술사 (계산, 전략)
1. 드러난 창은 피하기 쉬우나 숨은 화살은 막기 어렵다. 너는 늘 화살 쪽에 서 있구나.
2. 장막 안에서 수를 셈하는 자가 천 리 밖의 승부를 가르는 법이다.
3. 너는 검을 뽑기 전에 이미 상대를 다 읽었다. 이기는 싸움은 늘 그렇게 시작된다.

---

## 2. English (en)

### 2.1 Communities / pages checked

| ID | URL | Status |
|---|---|---|
| E1 | https://wuxiawanderings.substack.com/p/taiwan-wuxia-fiction-cliches (translated Chinese critique of formula wuxia) | fetched |
| E2 | https://wuxiasociety.com/seniority/ (WuxiaSociety, translator/reader community wiki) | fetched |
| E3 | https://wuxiasociety.com/jianghu/ | fetched |
| E4 | https://wuxiasociety.com/xia/ , https://wuxiasociety.com/codes-of-conduct/ | fetched |
| E5 | https://www.wuxiaworld.com/page/introduction-to-chinese-webnovel-genres-wuxia-suspense-and-realist | fetched |
| E6 | https://www.wuxiaworld.com/page/general-faq , https://www.wuxiaworld.com/page/glossary | fetched |
| E7 | https://www.chinadaily.com.cn/a/201609/16/WS5a2b79a4a310eefe3e9a0708.html ("Speak like a swordsman") | fetched |
| E8 | https://en.wikipedia.org/wiki/Wuxia , /Jianghu , /Tai_chi | fetched |
| E9 | https://forum.novelupdates.com/threads/most-used-phrases.4572/ , https://forum.novelupdates.com/threads/your-preferred-idiom-in-wuxia-xianxia-xuanhuan-is.82307/ | 403 (Cloudflare), [S] only |
| E10 | https://www.reddit.com/r/ProgressionFantasy/comments/1g4znex/ (courting-death thread), https://www.reddit.com/r/ProgressionFantasy/comments/1e4cwti/ ("xianxia without the how dare you") | robots blocks, [S] only |
| E11 | r/Xianxia, r/noveltranslations | robots blocks; search found no relevant thread |
| E12 | en.wiktionary idiom entries (cited in tables) | fetched |

### 2.2 Style rules

1. **Address the reader as "you". Never use "thou/thee" or archaic verb forms.** China Daily says wuxia lingo in modern use "is akin to walking around a English town shouting "where art thou?"", meaning it reads as a joke (E7).
2. **Self-reference is "I". Avoid literal "this old man" / "this one".** A fan wiki renders 老夫 "which might be translated as this old man" ([S] https://jiu-xing-ba-ti-jue-nine-star-hegemon-body-art.fandom.com/wiki/Translations). WuxiaSociety flattens the humble form: "晚辈 flatten to I" (E2). Treating the literal forms as stilted is 추론.
3. **Do not call the user "Junior", and don't have the master say "Senior".** E2: "The obvious rendering is "Senior" and "junior", and it is the one to avoid … readers … have been trained to read Senior Brother as shixiong".
4. **Keep wuxia human-scale, not xianxia.** Leave out "cultivation realm", "dao heart", "heaven-defying" and "immortal". Wuxiaworld: wuxia's power system "does not exceed the scope of the "human"" (E5). The Wuxiaworld glossary's realm ladder ("Comprehend the Grand Dao") belongs to xianxia titles (E6).
5. **Use the moral vocabulary readers know: righteousness, honour, keeping one's word, the jianghu.** E3: "the jianghu maintains its own moral codes emphasising loyalty, righteousness, and honour". E4: "Xin represents trustworthiness—keeping promises". E8: heroes "right and redress wrongs".
6. **Verdict tone: the master sizes the person up directly and without hedging.** E7: "characters are constantly judging each other on their martial arts prowess, and they're certainly not afraid to brag." Keep it to one or two clauses, plain diction, at most one image (추론).
7. **At most one Chinese loanword per line (jianghu, or none).** WuxiaSociety keeps culture-bound terms in pinyin "when they carry cultural weight" ([S] https://wuxiasociety.com/reading-tips-for-wuxia-translations). Fetched text: "They represent concepts without direct English equivalents (e.g., jianghu, xia)".
8. **Proverbs are welcome if they are classical and paraphrased smoothly**, e.g. "four ounces moves a thousand pounds" (E8 Tai chi: "the famous aphorism that "4oz moves 1000lbs" (四两拨千斤)").

### 2.3 Stock expressions

| Expression | Meaning | Origin | Sources | URLs / snippet |
|---|---|---|---|---|
| jianghu / "rivers and lakes" | the martial underworld | Zhuangzi (相忘于江湖) | 4 | E3; E5 "taking the "jianghu" (江湖) as the field of action"; E8 Jianghu; https://en.wiktionary.org/wiki/江湖 "From: Zhuangzi" |
| xia / chivalry | the hero's code | Han Feizi, Shiji 游侠列传 | 3 | E4; E5 "what a "xia" (侠, chivalrous hero) ought to be"; E8 Wuxia "code of xia" |
| Elder (前辈) | respectful address to a senior | jianghu etiquette | 2 | E2 "Elder, this one was mistaken." / https://chinese-web-lit.blogspot.com/p/terms-of-address.html "qiánbèi … a term of address for members of an elder generation" |
| washing hands in the golden basin | retiring from the jianghu | genre convention (金盆洗手) | 2 | E8 Jianghu "washing hands in the golden basin" ( 金盆洗手 ) / https://zh.wikipedia.org/zh-cn/江湖 (fetched; 金盆洗手 present) |
| four ounces deflect a thousand pounds | soft redirection beats force | Taiji classics (打手歌) | 2 | E8 Tai chi; https://en.wiktionary.org/wiki/四兩撥千斤 "Literally: "four ounces yields 1000 catties "" |
| have eyes but fail to recognize Mount Tai | failing to recognise a master | folk idiom (有眼不識泰山) | 2 | https://en.wiktionary.org/wiki/有眼不識泰山 "Literally: "to have eyes but fail to recognize Mount Tai "" / [S] https://wuxiawanderings.substack.com/p/working-on-lately (essay on the idiom's translation) |
| the youth deserve awe | young ones may surpass elders | Analects 9 | 2 | https://en.wiktionary.org/wiki/後生可畏 "From the Analects, Book 9" / https://ja.wikipedia.org/wiki/後生畏るべし |
| Know the enemy and yourself… | strategy | Sunzi | 2 | https://en.wiktionary.org/wiki/知己知彼，百戰不殆 "From The Art of War" / zh.wiktionary |
| The highest good is like water | yielding virtue | Daodejing 8 | 1 | https://en.wiktionary.org/wiki/上善若水 "From the Tao Te Ching" |

### 2.4 Cringe / overused list (avoid)

- **"You are courting death!"** The most-voted "most used phrase" on the NovelUpdates poll: [S] ""You are courting death" 20 vote(s) 44.4%" (E9). Reddit [S]: "a stock line in a ton of chinese cultivator stories, or used to be. Might be a cliche even for them at this point." (E10)
- **"A toad lusting after swan meat"**: [S] ""A toad wishing to eat swan meat!" 5 vote(s)" (E9 idiom poll).
- **"How dare you…?!"**: a reader asked for xianxia without it, thread title [S] "looking_for_a_xianxia_without_the_how_dare_you" (E10).
- **"Do you know who my father is?" / young-master arrogance**: [S] https://www.webnovels.com/story/33557990908823905/90103095224232449 lists it with "Courting death!".
- **Formula phrases from mass-market Taiwan wuxia** (E1, fetched): "the language used to write them is also clichéd, stuff like "if it's a blessing it's not a disaster, if it's a disaster you can't avoid it", "felt like ghosts were everywhere", "a rare bud of the martial world"". Also: "the manual left behind will definitely have the words "left for one who is fated to receive it"". → Avoid "fated one", "rare talent of the martial world", "unmatched under the heavens".
- **Mixing in xianxia vocabulary** (dao heart, realms, heavenly tribulation). This is a genre-boundary violation per E5 (추론 that wuxia readers notice).

### 2.5 Draft closing lines (original)

Plum Blossom Swordsman of Mount Hua (straight)
1. A straight blade may break, but a bent one never cuts true.
2. Plum blossoms save their fragrance for the coldest days; so will your stubbornness.
3. Stand as straight as you like, only learn where the stone lies before you strike it.

Taiji Adept of Wudang (yielding)
1. Water does not argue with the rock. It simply outlasts it.
2. Four ounces can turn a thousand pounds. Your hands already know it, even if your pride does not.
3. The soft overcomes the hard, not by resisting, but by never being where the blow lands.

Wind-like Wanderer (free)
1. The jianghu is wide enough for two friends to forget each other and both be well.
2. Clouds keep no address. Go, but choose for yourself where you fall as rain.
3. No banner, no sect, no debt. Travel light, and the road will remember you.

Tang Clan Hidden-Weapon Master (calculating)
1. A spear in daylight is easy to dodge, and you were never the one holding the spear.
2. Know yourself, know the other. You had won this duel before you drew.
3. Plans laid inside the tent decide battles a thousand li away. Keep yours folded.

---

## 3. 日本語 (ja)

### 3.1 確認したコミュニティ/ページ

| ID | URL | 状態 |
|---|---|---|
| J1 | https://kakuyomu.jp/tags/武侠 (カクヨム「武侠」タグ、人気順) | fetched, 51作品を表示 |
| J2 | https://yomou.syosetu.com/search.php?word=武侠&order=hyoka (なろう検索) | fetched |
| J3 | https://yomou.syosetu.com/search.php?word=中華風&order=hyoka | fetched |
| J4 | https://ja.wikipedia.org/wiki/老人語 | fetched |
| J5 | https://ja.wikipedia.org/wiki/役割語 | fetched |
| J6 | https://ja.wikipedia.org/wiki/武侠 (武俠小説) | fetched |
| J7 | https://ja.wikipedia.org/wiki/柔よく剛を制す , https://ja.wikipedia.org/wiki/後生畏るべし | fetched |
| J8 | https://ja.wiktionary.org/wiki/江湖 , /能ある鷹は爪を隠す , /井の中の蛙大海を知らず | fetched |
| J9 | pixiv百科事典 武侠 / ニコニコ大百科 武侠小説 | 403。pixivはrobotsでClaudeBotを拒否しているため不使用 |

注: 日本の武侠読者コミュニティは小さい。J1の該当作品は51件。J6には「日本では武侠…」の受容規模を示す数値はない。韓国語K1の脚注13には「일본은 무협물 자체에 관심을 그다지 갖지 않는다」[N]とある。

### 3.2 文体ルール

1. **老剣客は「老人語」の役割語で話す。一人称は「わし」、語尾は「〜じゃ」「〜ぬ」。** J4:「一人称「わし」や語尾「じゃ」、打消し「ぬ（ん）」といった特定の言い回しが、しばしば用いられる」(金水敏の役割語論)。ただし「じゃ」は1文に1回までにする(推論: 多用すると戯画になる)。
2. **二人称は「お前」に統一する**(推論: reveal文を「お前は{title}のような者だ」と訳す前提。「そなた」は武士語寄り。K2[N]で「'そなた(그대)'…武士語」と説明されている)。
3. **「〜ある」「〜あるよ」の中国人役割語は使わない。** J5:「ステレオタイプな 中国人 を表現する際には、語尾「ある」…などの特徴を持つ役割語が用いられる」。
4. **「江湖」は単独で使わず、文脈で意味が伝わる形にする。** 日本語の辞書義は「世の中。世間。」(J8)。武侠的な意味は自明ではない(推論)。
5. **四字熟語や故事成語は日本で定着している読み下しの形を使う**(柔よく剛を制す、後生畏るべし、井の中の蛙大海を知らず)。J7とJ8に出典つきで掲載されている。
6. **語彙は時代小説・任侠小説寄りにする。** J6:「日本の 時代小説 や任俠小説と多くの共通点を持っている」。剣・一手・道・修行は通じる。「境界」「剣気」はなろうタグの集計で0件(J1/J2の語数集計、下表)。
7. **一文20〜40字程度。読点で対句を作り、句点で断定して終える**(推論)。

なろう/カクヨムの頻度(取得ページ内の出現数、J1/J2): 侠 110/31、天下 6/1、天魔 6/6、江湖 5/0、内功 3/2、武林 3/1、修行 0/6、わし 1/1。J1のタグ共起: 武術11、中華ファンタジー10、中華9、中華風ファンタジー6、仙侠5、武功5。
「天魔神教」(J1の作品名)は韓国武協由来の設定だと推論する。日本のWeb武侠は韓国ウェブ小説の影響を受けている可能性がある(推論、未検証)。

### 3.3 定番表現

| 表現 | 意味 | 出典 | 出典数 | URL / 引用 |
|---|---|---|---|---|
| 柔よく剛を制す | 柔が剛に勝つ | 『三略』、老子 | 3 | J7「古代中国の『 三略 』という 兵法書 から来ている」/ zh.wiktionary 以柔克刚 / en.wikipedia Tai chi(四两拨千斤) |
| 後生畏るべし | 若者は侮れない | 『論語』子罕 | 3 | J7「『 論語 』の子罕篇」/ en.wiktionary 後生可畏 / zh.wiktionary 后生可畏 |
| 井の中の蛙大海を知らず | 狭い見識 | 『荘子』秋水 | 1 | J8「「 荘子 　秋水篇」より」 |
| 能ある鷹は爪を隠す | 実力者は爪を見せない | 日本のことわざ | 1 | J8「優れた 能力 のある人はそれを 無駄 に ひけらかし たりしないということの たとえ」 |
| わし／〜じゃ | 老人・師匠の役割語 | 江戸上方語由来の役割語 | 2 | J4 / J5 |
| 彼を知り己を知れば百戦殆うからず | 戦略 | 『孫子』 | 2 | en/zh.wiktionary(知己知彼) |

### 3.4 避けるべきもの

- 「〜ある」口調の似非中国語(J5)。
- 「江湖」「武林」「内功」の羅列。読者層が小さく、意味が通じない恐れがある(J8の辞書義、推論)。
- 仙侠用語(境界、天劫、道心)。武侠は「人間」の範囲にとどまる(E5)。
- 「〜でござる」(侍語)。中華の剣客に日本の武士語が混ざる(推論。K2[N]の武士語説明を参照)。

### 3.5 締めの一言 案 (オリジナル)

梅花剣士 (まっすぐ)
1. まっすぐな剣は折れやすい。じゃが、曲がった剣では何も斬れぬ。
2. 梅は寒さをくぐってこそ香る。お前の頑固さも、いずれ香りになろう。
3. 剛きは折れると人は言う。ならば、折れぬほどに鍛えればよい。

太極拳士 (しなやか)
1. 柔よく剛を制す。お前の柔らかさは、弱さではない。
2. 水は岩と争わぬ。じゃが、いつの間にか穿っておる。
3. 四両で千斤を流す者は、自ら先に剣を抜かぬものじゃ。

風のような浪人 (自由)
1. 雲は行き先を問わぬ。ただ、雨となって落ちる場所だけは己で選べ。
2. 世は広い。互いを忘れて生きるのも、また一つの道じゃ。
3. 縛られぬ足ほど遠くへ行く。帰る道ひとつだけは、忘れるでないぞ。

唐門の暗器使い (計算)
1. 表の槍は避けやすく、陰の矢は防ぎがたい。お前はいつも矢の側に立っておる。
2. 能ある鷹は爪を隠す。袖の内の一手は、最後まで取っておけ。
3. 彼を知り己を知れば、百戦殆うからず。お前は剣を抜く前に勝っておったな。

---

## 4. 中文 (zh)

### 4.1 检查过的社区/页面

| ID | URL | 状态 |
|---|---|---|
| C1 | https://zh.wikipedia.org/zh-cn/江湖 | fetched |
| C2 | https://www.gcores.com/articles/109885 (机核 GCORES 社区长文《江湖何在》) | fetched |
| C3 | https://zh.wikipedia.org/zh-cn/唐门 , /武当派 , /太极拳 , /华山派 , /游侠 | fetched |
| C4 | https://book.douban.com/review/9542547/ (豆瓣书评，标题"人在江湖身不由己") | fetched |
| C5 | zh.wiktionary 成語/諺語条目 (见下表) | fetched |
| C6 | https://www.chinadaily.com.cn/a/201609/16/WS5a2b79a4a310eefe3e9a0708.html | fetched (中英对照) |
| C7 | https://wuxiawanderings.substack.com/p/taiwan-wuxia-fiction-cliches (中文评论英译) | fetched |
| C8 | 百度贴吧 武侠吧 https://tieba.baidu.com/f?kw=武侠 | 403，未取 |
| C9 | 豆瓣 金庸小组 | 豆瓣 /search 被 robots 禁止，未检索 |
| C10 | 起点/晋江 武侠标签 | 未检查 |
| C11 | jinyongbook.com 论坛、thenewslens | robots 禁止 ClaudeBot，未使用 |

### 4.2 文体规则

1. **长辈对晚辈称"你"，不用"阁下"。** "阁下"是对平辈或陌生人的敬称。C6:"Others should be referred to as géxià (阁下)… akin to m'lord or m'lady"。自称可以省略，偶尔用"老夫"([S] fan wiki 将老夫译作 "this old man")。
2. **文白夹杂，四字为骨。** 前半句用成语或俗语，后半句用白话点评。C6 列举的武侠腔"在下A，敢问阁下高姓大名？""久仰久仰"都是四字节奏(规则化属推论)。
3. **评语直截了当。** C6:"characters are constantly judging each other on their martial arts prowess"。可用的判语框架有"孺子可教"(C5,《史記·留侯世家》中老父试张良)、"后生可畏"(《論語》)、"青出于蓝"(《荀子》)。
4. **价值词用侠、义、信、江湖规矩。** C2:"他们必须遵守江湖上的道义"、"形成了一套自己的江湖规矩"。C3 游侠:"路见不平，拔刀相助"。
5. **门派意象要对上读者常识。** 唐门:"唐门主要的特色，在于“暗器”与“毒药”"(C3)。武当太极:"以阴柔阳刚、刚柔两仪四象而创太极三功"(C3 太极拳)。华山:剑法。英文社区称其 "elegant swordplay"(https://wuxiasociety.com/huashan-school/)。华山与梅花的关联主要见于韩国武侠(K6),中文读者未必认"梅花剑手"(推论)。
6. **"浪人"一词在中文偏日本味,建议用"游侠/浪子/江湖散人"。** 依据是 K1[N]:낭인 "정통 무협의 용어가 아니며 … 일본 찬바라 의 영향 … 중국 본토에서는 유협, 유민이라는 말을 주로 썼다"。具体替换词属推论。
7. **一句 15–30 字,可用破折号或分号作顿。** 避免网络流行语(推论)。

### 4.3 常用表达

| 表达 | 含义 | 出处 | 来源数 | URL / 引用 |
|---|---|---|---|---|
| 人在江湖，身不由己 | 处世不由自主 | 民间俗语(諺語) | 4 | C1 "人在江湖，身不由己 ，情仇难却，恩怨无尽。" / C2 "2.人在江湖身不由己" / C4 书评标题 "人在江湖身不由己" / https://zh.wiktionary.org/wiki/人在江湖，身不由己 (諺語) |
| 相忘于江湖 | 各自安好,不必相守 | 《庄子·大宗师》 | 2 | C1 "转身相忘于江湖的过客" / https://en.wiktionary.org/wiki/江湖 "From: Zhuangzi" |
| 路见不平，拔刀相助 | 侠义 | 民间俗语 | 2 | C6 "(路见不平，拔刀相助; …)" / C3 游侠 "路见不平，拔刀相助" |
| 金盆洗手 | 退出江湖 | 武侠惯例 | 2 | C1 / https://en.wikipedia.org/wiki/Jianghu |
| 以柔克刚 / 柔能克刚 | 柔胜刚 | 《三略》《道德经》 | 3 | zh.wiktionary 以柔克刚(成語)、柔能克刚 / J7 |
| 四两拨千斤 | 巧劲胜蛮力 | 太极拳谱 | 3 | https://zh.wiktionary.org/wiki/四两拨千斤 (俗語) / en.wikipedia Tai chi / namu 태극권 [N] |
| 明枪易躲，暗箭难防 | 暗处之敌难防 | 民间諺語 | 2 | zh/en.wiktionary |
| 后生可畏 | 年轻人可敬畏 | 《論語·子罕》 | 3 | https://zh.wiktionary.org/wiki/后生可畏 "出自《 論語·子罕 》" / en.wiktionary / J7 |
| 孺子可教 | 这孩子可以教 | 《史記·留侯世家》 | 1 | https://zh.wiktionary.org/wiki/孺子可教 "出自《史記·卷五五·留侯世家》" |
| 青出于蓝 | 弟子胜师 | 《荀子·勸學》 | 2 | zh.wiktionary / [S] 한경 |
| 运筹帷幄 | 谋定于内 | 《史記》 | 1 | https://zh.wiktionary.org/wiki/运筹帷幄 "出自《 史記 · 太史公自序 》" |
| 宁折不弯 / 宁为玉碎，不为瓦全 | 刚直不屈 | 成语(后者见《北齐书》，未核实) | 1 | zh.wiktionary 条目存在(釋義页) |
| 闲云野鹤 | 无拘无束 | 成语 | 2 | zh.wiktionary / en.wiktionary 閒雲野鶴 (Idiom) |
| 在下 / 阁下 / 久仰 | 江湖寒暄 | 武侠惯例 | 1 | C6 |

### 4.4 读者吐槽或须避开的

- **台湾流水线武侠的套话** (C7, 中文原评论的英译): "if it's a blessing it's not a disaster, if it's a disaster you can't avoid it"(即"是福不是祸，是祸躲不过",回译属推论)、"a rare bud of the martial world"(武林奇葩/奇才)、"left for one who is fated to receive it"(留赠有缘人)。
- **"找死!" / courting death**:英文社区投票第一(E9 [S] 44.4%)。中文原句为"找死"(推论,依 [S] "a direct translation of "seeking death"")。
- **"骨骼精奇，万中无一的练武奇才"**:未找到可引用的吐槽原文(检索无结果),**未核实**,仅凭推论列为风险。
- **直接引用当代作家名句**,如"侠之大者，为国为民"(金庸)。C2 引用了它,说明流传很广,但它属于现代作者原句,按规则不得使用。

### 4.5 结尾句草案 (原创)

华山梅花剑手 (刚直)
1. 剑直易折；可剑若弯了，便什么也斩不断。
2. 梅花香自苦寒来——你这股倔劲，熬过冬天便是香。
3. 宁折不弯固然可敬，只是要先把自己炼到折不断。

武当太极拳师 (柔和)
1. 水不与石争，却终究把石头磨穿。
2. 能四两拨千斤的人，从不急着先出手。
3. 以柔克刚，不在硬挡，而在让那一击落了空。

如风游侠 (自由)
1. 相忘于江湖，未必薄情；你本就不属于哪一处。
2. 闲云野鹤，来去由心，只记得给自己留一条回来的路。
3. 云不问归处；落成雨的地方，你自己选。

唐门暗器高手 (算计)
1. 明枪易躲，暗箭难防——而你，从来都站在暗处。
2. 运筹帷幄之中，你那一手，留到最后再发。
3. 知己知彼，你在拔剑之前便已赢了。

---

## 5. 언어 공통 결론 (요약)

- 4개 언어 모두에서 가장 넓게 확인된 장르 공용어는 江湖/강호/jianghu였다(ko·en·zh 각 2곳 이상, ja는 의미가 통하지 않을 수 있음).
- 마무리 줄에 넣기 좋은 고전 성어는 유형별로 하나씩 고르면 된다. 각 성어의 출처 수와 기원은 위 표에 있다.
  - 무당: 四兩撥千斤(3곳), 柔能制剛(3곳)
  - 당문: 明槍易躲暗箭難防(2곳), 知己知彼(2곳)
  - 낭인: 相忘於江湖(2곳, 『장자』)
  - 화산: 梅花香自苦寒來. 출처를 확인하지 못했고(zh.wiktionary 404), 민간 격언으로 알려져 있으나 **미검증**이다.
- 판정 어투에 쓸 수 있는 고전 근거는 後生可畏(3곳)와 孺子可教(1곳)다.
- 공통으로 피할 것은 courting death/找死, 선협(仙俠) 용어, 번역투, 현대 작가 명대사, 일본어의 「〜ある」.
- 현지화 주의: "매화검수"와 "낭인"은 한국 무협 고유 또는 일본 유래 용어다(K6, K1). zh·en에서는 의미를 풀어 옮겨야 한다.
