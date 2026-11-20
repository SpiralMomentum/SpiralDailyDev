# FANTASY 채널 문체 리서치 (궁전의 공주 화자)

조사일: 2026-11-19. 도구: WebSearch(검색 스니펫), WebFetch(공개 페이지 본문). 로그인 필요 페이지는 시도하지 않았다.

표기 규칙
- 인용은 원문 그대로이며, 짧은 스니펫만 옮겼다. 번역 요약만 가능했던 경우는 "(요약)"으로 표시했다.
- `[F]` = 본문 fetch 성공, `[S]` = 검색 스니펫만 확인, `[X]` = fetch 실패(사유 기재)
- **추론** = 근거 자료가 직접 말하지 않고, 내가 자료를 조합해 판단한 부분
- 출처 수는 서로 다른 도메인(독립 출처) 기준으로 셌다.

## 전체 한계 (먼저 읽을 것)
- 실제 독자 댓글(카카오페이지, 네이버 시리즈, 리디 리뷰, 디시 로판갤, reddit, 晋江 댓글, 豆瓣)은 거의 확보하지 못했다. reddit은 WebFetch가 차단했고(`unable to fetch from old.reddit.com`), 미러 사이트는 SSL 오류가 났다. pixiv百科, ニコニコ大百科, Royal Road, thewiki는 403이었고, 晋江 목록은 GB18030 인코딩이 깨져서 읽을 수 없었다.
- 그래서 커뮤니티를 대신해 커뮤니티가 함께 쓰는 위키(나무위키, ja.wikipedia, TV Tropes 계열), 랭킹 페이지(小説家になろう), 작가·독자 포럼(Mythic Scribes, Nathan Bransford 등)을 근거로 삼았다. 장르 독자의 "체감"을 대신하는 증거로는 약하다.

---

## KO (로맨스 판타지 / 로판)

### 확인한 커뮤니티
| 대상 | URL | 상태 |
|---|---|---|
| 나무위키 로맨스 판타지/클리셰 | https://namu.wiki/w/로맨스 판타지/클리셰 | [F] |
| 나무위키 영애 | https://namu.wiki/w/영애 | [F] |
| 나무위키 하오체 | https://namu.wiki/w/하오체 | [F] |
| 나무위키 그대 | https://namu.wiki/w/그대 | [F] |
| 나무위키 전하(호칭) | https://namu.wiki/w/전하(호칭) | [F] |
| 나무위키 경 | https://namu.wiki/w/경 | [F] (요약으로만 받음) |
| 리디 <클리셰의 여왕> 리뷰 | https://ridibooks.com/books/1250041373 | [F] |
| 여성시대(다음카페) K-로판 패러디 | https://m.cafe.daum.net/subdued20club/ReHf/5447308 | [F] |
| 디시 로판/연애 갤러리 | https://gall.dcinside.com/m/lovestory/4603 | [S] 장르 논쟁 글이라 문체 정보 없음 |
| thewiki 로판 | https://thewiki.kr/w/로판 | [X] 403 |
| 카카오페이지·네이버 시리즈 댓글, 조아라 | - | 시도 안 함(앱/JS 렌더링·로그인 필요) |

### 근거 스니펫
- 호칭 영애: "호칭도 ~영애, ~영식 등이 흔하지만 해당 표현은 ~의 딸/아들을 표현하는 간접어이기에 실제 부르는 호칭으로 쓰이는 건 오류이다." / "하도 흔하게 퍼진 터라 아는 독자들 중에서도 지적하지 않고 넘어가는 일도 많다." (namu 로맨스 판타지/클리셰)
- 자칭 영애 오류: "본인이 스스로를 소개하면서 "저는 마리아 영애입니다."라고 하면 자기가 자기의 딸이라는 의미가 되어버린다." (namu 영애)
- 공녀: "로판 장르에서는 공작의 딸만 공녀라고 부르고 다른 작위는 '아무개 영애' 하는 식으로 부르는 것이 워낙 흔하긴 하지만" (namu 클리셰)
- 하오체: "중·근세를 모티브로 한 판타지 작품 등에서도 등장인물의 대사가 하오체로 번역되기도 한다." / "그 중에서도 대개 남성의 말투로 쓰인다." / "중년 이하의 사람이 하오체를 사용하면 매우 어색하게 느껴진다." (namu 하오체)
- 그대: "주로 하오체와 하게체의 고전적인 문체에서 쓴다." / "사용이 점차 줄어 노래 가사에 자주 쓰인다." (namu 그대)
- 전하/폐하: "전하보다 격이 높은 표현으로 폐하(陛下) 등이 있고" (namu 전하(호칭))
- 경: "그러나 경은 엄밀히 말해서 군주가 신하에게 쓰는 말이고, sir는 아랫사람이 불러주는 경칭이다." (namu 경)
- 사이다 말싸움: "보통 주인공이 말싸움에서 상대를 발라버리는 것을 통해 사이다를 의도하는 경우가 많다." / "대사를 잘 못 쓰면 유치하게 보이거나 허수아비 때리기처럼 보일 수 있는 위험성이 있지만" (namu 클리셰)
- 독자 피로: "노잼 클리셰로 짜집기한 수준입니다" (리디 리뷰 ssr***), "클리셰만 모아서 나름 자연스럽게 스토리가 진행되네욤" (리디 리뷰 smk***)

### 문체 규칙 (LLM 프롬프트용)
1. 공주는 사용자에게 해요체를 쓴다("~이에요", "~지요"). 하오체("~하오")는 쓰지 않는다. 근거: 하오체는 "대개 남성의 말투"이고 젊은 화자가 쓰면 "매우 어색하게 느껴진다"(namu 하오체). 해요체로 정한 것 자체는 **추론**이며, 고정 문장 "같은 분이에요"와도 맞춘 선택이다.
2. 2인칭은 "당신"으로 한다. "그대"는 한 결과에 많아야 한 번 쓰고, 운율이 필요한 마지막 줄에만 쓴다. 근거: "그대"는 고전 문체이고 지금은 "노래 가사에 자주 쓰인다"(namu 그대). 횟수 제한은 **추론**이다.
3. 사용자를 "○○ 영애"라고 부르지 않는다. 오류라는 지적이 있고(namu 영애, namu 클리셰), 사용자의 성별을 모르기 때문이다.
4. "경"은 군주가 신하를 부르는 말이다(namu 경). 성기사 결과에서만 직함과 함께 "나의 기사"처럼 쓸 수 있고, 남발하지 않는다.
5. 공주 자신을 "전하"로 지칭하지 않는다. 전하는 남이 부르는 경칭이다(namu 전하(호칭)). 자칭은 "나"로 한다. "본 황녀", "짐"은 피한다(**추론**: 짐은 황제 자칭이다).
6. 문장은 짧게 쓰고, 한 줄에 판단 하나만 담는다. 남을 깎아내려 사용자를 높이는 "사이다" 말싸움 구조는 쓰지 않는다. 근거: "유치하게 보이거나 허수아비 때리기처럼 보일 수 있는 위험성"(namu 클리셰).
7. 판결·임명 문형은 "당신의 자리는 ~예요", "~을 맡기겠어요"처럼 해요체 선언으로 쓴다(**추론**. 장르 내 임명 대사 원문은 확보하지 못했다).
8. 마지막 줄은 고전 속담이나 고사를 그대로 인용하지 않는다. 공주의 말로 한 번 풀어 쓴다(**추론**: 원문을 그대로 붙이면 교훈조가 된다).

### 상투 표현 표
| 표현 | 의미 | 기원 | 출처 수 | URL |
|---|---|---|---|---|
| 영애/영식 | 귀족의 딸/아들(장르에서는 호칭처럼 쓰임) | 일본식 한자어를 장르에 맞게 쓴 용법 | 2 | namu 영애, namu 로맨스 판타지/클리셰 |
| 공녀 | 공작의 딸(장르 관행) | 한자어 公女 | 2 | namu 영애, namu 클리셰 |
| 전하 / 폐하 | 왕족 경칭 / 군주 경칭 | 동아시아 궁정 경칭 | 1 (namu 전하) + 검색 다수 | https://namu.wiki/w/전하(호칭) |
| 경(卿) | 군주가 신하를 부르는 말 | 한자어 | 1 | https://namu.wiki/w/경 |
| 나에게만 다정한 ~ | 소문과 달리 주인공에게만 다정한 인물 | 장르 내부 클리셰 | 1 | namu 클리셰 |
| 유비무환 | 준비가 있으면 근심이 없다 | 좌전 襄公11년에 인용된 『書』 | 2 | https://www.itwiki.kr/w/유비무환 , https://oggi.jp/6783648 |
| 말 한마디로 천 냥 빚을 갚는다 | 말의 힘 | 한국 전래 속담 | 3+ | https://www.korean.go.kr/nkview/nknews/200409/74_6.html , https://brunch.co.kr/@initssun/400 , https://www.seoul.co.kr/news/2016/07/13/20160713029009 |
| 벼는 익을수록 고개를 숙인다 | 실력 있을수록 겸손 | 한국 전래 속담(문헌 기원 미확인) | 3 | https://k-cultureguide.tistory.com/13 , https://content.library.pdx.edu/files/PDXScholar/Korean/63/ , https://knnews.co.kr/news/articleView.php?idxno=225266 |
| 열 길 물속은 알아도 한 길 사람 속은 모른다 | 사람 속은 헤아리기 어렵다 | 순오지 등(水深可知 人心難知) | 1 (검색 요약) | https://sgsg.hankyung.com/article/2019101175531 [S] |

### 오글/과용 목록 (피할 것)
- 사용자를 "영애"라고 부르거나, 자칭 "○○ 영애입니다"라고 하는 것 (namu 영애)
- 상대를 깎아내리는 사이다 말싸움 (namu 클리셰: "유치하게 보이거나")
- 공주의 하오체("~하시오", "~이오"). 남성 말투라 어색하다 (namu 하오체)
- 한 결과 안에서 "그대"를 반복하는 것 (namu 그대: 가사체)
- "나에게만 다정한", "생존", 회귀·빙의 독백 같은 장르 내부 밈 (namu 클리셰). 성격 결과와 관계없는 패러디로 읽힌다(**추론**).

### 마무리 문장 초안 (창작, 해요체)
- 새벽의 성기사
  1. 새벽은 가장 먼저 깨어 있는 이에게 먼저 와요. 내 곁의 첫 자리는 당신 거예요.
  2. 방패는 칭찬받지 못할 때 가장 단단하지요. 그래서 나는 당신에게 등을 맡겨요.
  3. 바람이 거셀수록 곧은 풀이 보이는 법이에요. 나는 오늘 당신을 보았어요.
- 별을 읽는 대마법사
  1. 별은 계속 묻는 사람에게만 길을 보여 줘요. 멈추지 말고 물으세요.
  2. 당신이 넘긴 책장 하나가 언젠가 이 왕국의 지도를 고쳐 그릴 거예요.
  3. 옛 기록을 아는 눈이 내일을 먼저 읽지요. 탑의 열쇠는 당신에게 둘게요.
- 그림자 정찰자
  1. 깊은 물은 소리 없이 흘러요. 당신의 침묵이 이 궁을 지켜 왔다는 걸 알아요.
  2. 모두가 지나친 것을 당신은 이미 보았지요. 그 눈을 내게 빌려주세요.
  3. 그림자는 빛을 등지지 않아요. 당신도 그렇다는 걸 나는 믿어요.
- 떠돌이 음유시인
  1. 말 한마디로 천 냥 빚을 갚는다지요. 당신의 노래는 그보다 값져요.
  2. 닫힌 성문도 웃음소리 앞에서는 빗장을 풀어요.
  3. 어디를 떠돌든, 이야기만은 이 궁으로 가져와 주세요.

---

## EN (r/Fantasy, Royal Road, otome/villainess 독자권)

### 확인한 커뮤니티
| 대상 | URL | 상태 |
|---|---|---|
| r/Fantasy, r/RoyalRoad, r/OtomeIsekai | old.reddit.com, 미러 lr.eu.psf.lt | [X] 차단 / SSL 오류. 검색 결과 제목만 확인 |
| Royal Road 작품 페이지 | https://www.royalroad.com/fiction/80467 | [X] 403 |
| Thoughts on Fantasy (archaism) | https://thoughtsonfantasy.com/2014/08/18/the-ye-olde-in-epic-fantasy-6-more-archaisms-and-why-authors-use-them/ | [F] |
| All The Tropes: Ye Olde Butcherede Englishe | https://www.allthetropes.org/wiki/Ye_Olde_Butcherede_Englishe | [F] (요약) |
| TV Tropes YeOldeButcheredEnglish | https://www.tvtropes.org/pmwiki/pmwiki.php/Main/YeOldeButcheredEnglish | [X] 403 |
| Mythic Scribes / Nathan Bransford / Michael A. Tate 블로그 | https://mythicscribes.com/community/goto/post?id=22731 , https://nathanbransford.com/blog/2007/04/thy-dialogue-dost-sound-strange/comment-page-1 , https://forums.nathanbransford.com/viewtopic.php?p=41355 , https://michaelatate.blogspot.com/2011/09/anachronistic-dialogue-in-fantasy.html | [S] |
| Wikipedia Royal and noble styles | https://en.wikipedia.org/wiki/Royal_and_noble_styles | [F] |
| English Heritage / royal.uk 기사 서임 | https://english-heritage.org.uk/visit/inspire-me/5-things-you-might-not-know-about-knights , https://www.royal.uk/knighthoods-and-damehoods | [S] |
| ANN Answerman (villainess 유행 기원) | https://admin.animenewsnetwork.com/answerman/2022-12-09/.192423 | [S] |

### 근거 스니펫
- thou/thee 기피: 지금 에픽 판타지에서는 드물고, "a little too Shakespearian, or too jarring and evocative of religious texts." / "Some people will argue that archaisms in fantasy are cheesy or clumsy" / 독자 댓글 "The thing with thee/thou/thy and other archaic language is that they're confusing." (thoughtsonfantasy)
- 형용사 후치: "that simple shifting of an adjective can suddenly make something sound grander." (thoughtsonfantasy)
- 엉터리 고어: "-eth"/"-est"를 아무 동사에나 붙이고 "thee, thou, forsooth"를 뿌리는 방식. "Thou was the singular pronoun, and ye/you was the plural." (allthetropes, 요약 포함)
- 축약형 생략: 축약형만 빼도 현대식 대사가 예스럽게 들렸다는 작가 경험 (Nathan Bransford forum [S])
- 독자 반응: 딱딱한 판타지 대사가 "one of the main reasons I don't read fantasy"라는 댓글 (Nathan Bransford blog comments [S])
- 경칭: "Your Grace"(공작), "His/Her Majesty"(군주) (Wikipedia Royal and noble styles)
- 서임 문구: 중세에는 목에 가볍게 치는 동작과 함께 "'Be thou a knight'"를 선언했다 (English Heritage [S]). 현대 영국 왕실은 "the words 'Arise, Sir...' are not used" (royal.uk [S])

### 문체 규칙
1. 2인칭은 "you"만 쓴다. thee/thou/-eth/forsooth는 금지한다 (thoughtsonfantasy, allthetropes).
2. 축약형(I'm, you're)을 빼서 격식감을 낸다. 문법은 현대 영어 그대로 둔다 (Nathan Bransford forum [S]).
3. 웅장한 느낌은 어휘 수를 늘리지 말고 어순으로 낸다. 형용사 후치나 "I know it well" 같은 도치를 한 줄에 하나까지만 쓴다 (thoughtsonfantasy. 횟수 제한은 **추론**).
4. 사용자를 부를 때는 "my lady/my lord"가 아니라 결과 직함을 쓴다("my knight", "my archmage"). 사용자의 성별을 모르기 때문이다(**추론**).
5. 공주의 자칭은 "I"로 한다. royal "we"는 여왕/군주의 표지라 공주에게는 과하다(**추론**. TV Tropes Royal We는 군주 1인칭 복수로 정의하지만 직접 fetch는 하지 않았다).
6. 임명 문형은 "I name you…", "Your place is…", "I give you…"처럼 현재형 선언문으로 쓴다(**추론**). "Arise, Sir"는 현대 의식에서 쓰지 않는 영화식 클리셰이므로 피한다 (royal.uk [S]).
7. 문장은 12단어 이하로, 두 문장 이내로 쓴다(**추론**. 앱 말풍선 길이에 맞춘 값).

### 상투 표현 표
| 표현 | 의미 | 기원 | 출처 수 | URL |
|---|---|---|---|---|
| Your Highness / Your Majesty / Your Grace | 왕족 / 군주 / 공작 경칭 | 영국 궁정 관습 | 1 [F] + 검색 다수 | Wikipedia Royal and noble styles |
| Be thou a knight | 중세 서임 선언 | 중세 의식 | 1 [S] | english-heritage.org.uk |
| Arise, Sir … | 영화·대중문화식 서임 대사(실제 의식에서는 쓰지 않음) | 대중문화 | 2 [S] | royal.uk, jamaica-gleaner.com/article/sports/20251105/arise-sir-david |
| Still waters run deep | 조용한 사람이 속이 깊다 | 라틴 격언, 영어 기록 약 1400년 | 3 | https://en.wikipedia.org/wiki/Still_waters_run_deep , https://en.wiktionary.com/wiki/still_waters_run_deep , https://www.theidioms.com/still-waters-run-deep/ |
| Fortune favours the bold | 대담한 자에게 운이 따른다 | Virgil, Aeneid 10.284 "Audentis Fortuna iuvat"; Terence "Fortes fortuna adiuvat" | 3 | https://en.wikipedia.org/wiki/Fortune_favours_the_bold , https://www.phrases.org.uk/meanings/fortune-favours-the-bold.html , https://en.wiktionary.com/wiki/fortes_fortuna_adiuvat |
| Uneasy lies the head that wears a crown | 권력자의 무거운 책임 | Shakespeare, Henry IV Part 2, III.i (1597, 퍼블릭 도메인). "Heavy is the head"는 오인용 | 3 | https://phrases.org.uk/meanings/uneasy-lies-the-head-that-wears-the-crown.html , https://www.wiktionary.com/wiki/uneasy_lies_the_head_that_wears_a_crown , https://nosweatshakespeare.com/quotes/famous/heavy-is-the-head-that-wears-the-crown/ |

### 오글/과용 목록
- thee/thou/-eth/forsooth를 뿌린 가짜 고어 (allthetropes, thoughtsonfantasy: "cheesy or clumsy")
- "Arise, Sir …" (실제 의식에서는 쓰지 않음, royal.uk)
- "Heavy is the head that wears the crown" 오인용 (phrases.org.uk / nosweatshakespeare)
- 장황하고 신탁 같은 대사. "less like human beings and more like gods in an ancient Greek play" (thoughtsonfantasy.com/2016/04/04/10-common-mistakes-i-see-in-epic-fantasy-writing/ [S])
- 왕자가 뒤늦게 반성하며 매달리는 villainess 전개. 지친 트로프로 언급된다 (Royal Road 리뷰 [S]. 스토리 요소라 문체와는 직접 관련이 없다)

### 마무리 문장 초안 (창작)
- Knight of the Dawn
  1. Dawn comes first to those who keep watch. The place at my right hand is yours.
  2. No one thanks a shield, and still it holds. I know you will.
  3. Hard winds show which grass stands firm. Today, I saw you stand.
- Archmage Who Reads the Stars
  1. The stars answer only those who keep asking. Do not stop.
  2. Every page you turn redraws the map of my kingdom.
  3. Fortune favours the bold, and a bold mind most of all.
- Shadow Scout
  1. Still waters run deep, and none in this court run deeper than you.
  2. What others pass by, you have already seen. My halls sleep safer for it.
  3. Keep your silence sharp. I will listen for it.
- Wandering Bard
  1. A kind word opens gates no army could. You carry many.
  2. A court without laughter is only a cold hall. Be its warmth.
  3. Wander where you will, but bring the songs home to me.

---

## JA (なろう 異世界恋愛 / 悪役令嬢, 乙女ゲーム)

### 확인한 커뮤니티
| 대상 | URL | 상태 |
|---|---|---|
| 小説家になろう 日間 異世界〔恋愛〕ランキング | https://yomou.syosetu.com/rank/genrelist/type/daily_101/ | [F] |
| なろう 悪役令嬢 작품 페이지(검색 결과) | https://ncode.syosetu.com/n2247my , https://ncode.syosetu.com/n0545ih | [S] |
| ja.wikipedia お嬢様言葉 | https://ja.wikipedia.org/wiki/お嬢様言葉 | [F] |
| pixiv百科 悪役令嬢 / お嬢様言葉 | https://dic.pixiv.net/a/悪役令嬢 | [X] 403 |
| ニコニコ大百科 悪役令嬢 | https://dic.nicovideo.jp/a/悪役令嬢 | [X] 403 |
| 「君を愛することはない」 관련 작품과 앤솔로지 | https://ncode.syosetu.com/n4483jt , https://bookwalker.jp/series/448541 | [S] |
| 役割語(金水敏), 王様語 논문 | https://Www.wikipedia.org/wiki/Yakuwarigo , https://seika.repo.nii.ac.jp/record/2000007/files/%E7%B4%80%E8%A6%8157_85-90.pdf | [S] |

### 근거 스니펫
- 1인칭: 「一人称には「わたくし」「あたくし」が典型的に用いられる。」 (ja.wikipedia)
- 어미: 「お蝶夫人は「〜て（よ）」「動詞＋わ」「名詞＋ですわ」といった語形を多用する」 (ja.wikipedia)
- 역할어로서의 놀이성: 「金水は、役割語には人物像を演じて楽しむ「遊び」の側面があることを指摘している」 (ja.wikipedia)
- 소도구 정형화: 「口元を隠し笑みを見せないのは、悪役令嬢のたしなみですものね」, 「ふふふ……いよいよこの時がやってきましたわね!」 (ncode n2247my [S])
- 랭킹 상위 20개 제목(2026-11-19 fetch) 중 '令嬢' 5개, '公爵' 2개, '婚約破棄' 1개, '王太子' 1개, '殿下' 0개였다. 상위 제목은 대사 인용형이 많다: 「「君を愛することはない」と初夜に言われたので「わたしもです」と答えたら…」, 「「膝をつけば赦してやる」と王太子は言った。」, 「白い結婚のご通達、まことにありがとうございます。」
- 「君を愛することはない」는 정형구로 자리 잡았다: 「初代「君を愛することはない」の誕生から、はや二十数年。」라는 패러디 (ncode n4483jt [S]), 앤솔로지 띠지 「「君を愛することはない」って…言いましたよね!?」 (bookwalker [S])
- 王様語: 一人称「余」, 「〜ておる」, 「〜じゃ」 (住田哲郎, 京都精華大学紀要57 [S])

### 문체 규칙
1. 공주의 1인칭은 「わたくし」로 한다 (ja.wikipedia).
2. 2인칭은 「あなた」로 한다. 「貴方」 한자 표기와 「そなた」는 쓰지 않는다(**추론**: 「そなた」는 時代劇·王様語 색이 강하고, 사용자를 낮춰 부르는 것처럼 들릴 수 있다).
3. 「ですわ」「〜ますの」「〜てよ」는 결과 하나당 1~2회까지만 쓴다. 나머지는 です・ます로 쓴다. 근거: 이 어미들은 현실 말투가 아니라 역할어 「遊び」이고(ja.wikipedia), 과용하면 悪役令嬢 패러디가 된다(**추론**).
4. 「わらわ」「〜じゃ」「余」는 쓰지 않는다. 王様語·老人語와 겹친다 (住田 논문 [S]).
5. 판정·임명 문형은 「あなたに〜を任せます」「あなたの席は〜です」처럼 정중체 선언으로 쓴다. 「〜に任ずる」 같은 문어체는 한 번만 쓴다(**추론**. 장르 원문 미확보).
6. 고전 속담은 「〜と申しますでしょう」「〜と言いますもの」로 받아 공주의 말로 만든다(**추론**).
7. 한 문장은 40자 안팎, 두 문장 이내로 쓴다(**추론**). 상위 랭킹 제목처럼 대사형 문장은 짧고 반전이 하나 있다.

### 상투 표현 표
| 표현 | 의미 | 기원 | 출처 수 | URL |
|---|---|---|---|---|
| わたくし / ですわ / 〜てよ | 귀족 영애 역할어 | 메이지기 てよだわ言葉 → 山の手言葉 → 역할어 | 2 | ja.wikipedia お嬢様言葉, ncode n2247my |
| 扇で口元を隠す / 高笑い | 悪役令嬢의 소도구·동작 | 장르 정형 | 2 [S] | ncode n2247my, ncode n0545ih |
| 婚約破棄 | 파혼 선언 | 장르 정형 | 2 | なろう ランキング, ANN Answerman |
| 「君を愛することはない」 | 정략결혼 첫날밤의 거절 대사 | 장르 정형(현대 웹소설) | 3 [S] | ncode n4483jt, bookwalker 448541, ncode n6909ji |
| 白い結婚 | 형식뿐인 결혼 | 장르 정형 | 2 | なろう ランキング #9 #18 |
| 能ある鷹は爪を隠す | 실력자는 드러내지 않는다 | 일본 속담(北条氏直 유래설은 미확인) | 3 | https://precious.jp/articles/-/44807 , https://serai.jp/living/1200685 , https://eleschool-compass.com/contents/kotoba/kotowaza/nouarutakahatsumeokakusu.php |
| 備えあれば憂いなし | 준비하면 근심이 없다 | 『書経』(有備無患). 좌전 인용으로 확인 | 2 | https://oggi.jp/6783648 , https://www.itwiki.kr/w/유비무환 |
| 芸は身を助ける | 재주가 몸을 돕는다 | 江戸いろはかるた | 2 | https://oggi.jp/7253822 , https://eleschool-compass.com/contents/kotoba/kotowaza/geihamiotasukeru.php |
| 温故知新 | 옛것을 익혀 새것을 안다 | 『論語』為政 (이번 검색에서는 출처 미확인. 일반 지식) | 0 (미검증) | - |

### 오글/과용 목록
- 매 문장 「ですわ」, 「おーっほっほ」 같은 고笑い. 悪役令嬢 패러디 기호다 (ncode n2247my [S]. 패러디로 읽힌다는 것은 **추론**)
- 「君を愛することはない」, 「婚約破棄だ!」, 「白い結婚」 같은 장르 밈 문형. 이미 패러디 대상이다 (ncode n4483jt: 「はや二十数年」)
- 「わらわ」「〜じゃ」 (王様語·老人語)
- 「ざまぁ」식 복수 쾌감 문형 (**추론**. 이번 랭킹에서는 0건이었다)

### 마무리 문장 초안 (창작)
- 夜明けの聖騎士
  1. 夜明けは、誰より早く目覚める者のもとへ訪れます。わたくしの隣は、あなたの席ですわ。
  2. 備えあれば憂いなし、と申しますでしょう。あなたがいるから、この城は眠れるのです。
  3. 強い風の日にこそ、まっすぐな草がわかるもの。今日、わたくしはあなたを見ました。
- 星を読む大魔法使い
  1. 星は、問い続ける者にだけ道を示します。どうか、問うことをやめないで。
  2. あなたがめくる一頁が、いつかこの国の地図を描き直すのでしょう。
  3. 古い記録を知る目は、明日を先に読むものです。塔の鍵は、あなたに預けますわ。
- 影の斥候
  1. 能ある鷹は爪を隠す、と言いますもの。あなたの沈黙を、わたくしは知っています。
  2. 皆が見過ごしたものを、あなたはもう見ている。それだけで、この宮は安らげます。
  3. 影は光に背を向けません。あなたもそうだと、信じていますわ。
- 流浪の吟遊詩人
  1. 芸は身を助ける、と申します。あなたの歌は、きっとこの国も助けますわ。
  2. 閉ざされた城門も、笑い声には案外弱いものです。
  3. どこへ旅をしても、物語だけはここへ持ち帰っていらして。

---

## ZH (晋江 宫廷/西幻, 百度贴吧, 豆瓣)

### 확인한 커뮤니티
| 대상 | URL | 상태 |
|---|---|---|
| 晋江 bookbase(태그 목록) | https://www.jjwxc.net/bookbase.php | [X] GB18030 인코딩 깨짐, 파싱 실패 |
| 豆瓣 / 百度贴吧 | - | [X] 검색에 관련 글 없음 (豆瓣 결과는 论语 서평 1건뿐) |
| 萌娘百科 翻译腔 | https://zh.moegirl.org.cn/翻译腔 | [X] 본문 없음(JS) |
| The World of Chinese "Royal Roast" (宫斗 용어의 밈화) | https://www.theworldofchinese.com/post/royal-roast/ | [F] |
| 界面 如懿传 대사 비판 | https://m.jiemian.com/article/11112932.html | [S] |
| 澎湃 古言 网文 분류(晋江 등) | https://www.thepaper.cn/newsDetail_forward_7811362 | [S] |
| 甄嬛传 「臣妾做不到啊」 | https://www.worldjournal.com/wj/amp/story/121233/8959494 , https://www.businessweekly.com.tw/management/blog/3017337 | [S] |
| B站/机核 西幻 套路 | https://www.bilibili.com/read/cv44350/ , https://www.gcores.com/articles/145348 | [S] |

### 근거 스니펫
- 宫斗 용어가 밈이 됨: "internet memes and pseudo-historic lingo"가 WeChat 글과 Taobao 고객 응대에 퍼졌다. 本宫은 권위를 드러내는 자칭이고, 爱卿은 친구를 황제처럼 부르는 농담이며, 朕은 고양이 밈에 쓰인다 (TWOC [F], 요약 포함)
- 반문반백 대사 비판: 《如懿传》의 반문반백 대사가 고전과 심정을 억지로 연출해 오히려 "寡淡啰嗦"하다는 평가 (界面 [S], 검색 요약)
- 「臣妾做不到啊」가 고전 명대사가 됨 (世界日报 [S])
- 西幻 套路: 骑士가 "保卫公主便是这一生所活的最终目标"라는 훈계를 받는 전개 (gcores [S])
- 古言 근거지: "晋江、红袖添香、潇湘书院是古言网文的主要阵地" (澎湃 [S])

### 문체 규칙
1. 공주는 사용자를 「你」로 부른다. 신하가 공주를 부를 때는 「殿下」, 자칭은 「我」로 한다. 「本宫」「本公主」는 밈화된 자칭이라 쓰지 않는다 (TWOC: 本宫 밈. 자칭 선택은 **추론**).
2. 「爱卿」「卿」은 황제가 쓰는 말이고 농담 밈이기도 하므로 피한다 (TWOC).
3. 西幻 배경이므로 宫斗식 반문반백(「臣妾」「谢主隆恩」「小主」)을 섞지 않는다 (**추론**. 西幻와 宫斗 어휘가 섞이면 장르가 어긋난다).
4. 翻译腔 감탄사(「哦,我亲爱的」「我的上帝」)는 쓰지 않는다 (**추론**. 萌娘百科 본문 미확보, ifanr 기사 제목 "噢,上帝啊!翻译腔到底该不该死?"만 확인 [S] https://www.ifanr.com/1361161).
5. 마지막 줄은 4자 성어나 고전 구절 하나에 공주의 해석 한 구를 붙인다. 고전 구절은 한 결과에 하나까지만 쓴다 (**추론**).
6. 문장은 18자 이내 구절 2~3개로 끊는다 (**추론**).
7. 임명 문형은 「我把~交给你」「~的位置,留给你」 같은 백화 선언으로 쓴다. 「朕命你」식 칙령체는 쓰지 않는다 (**추론**).

### 상투 표현 표
| 표현 | 의미 | 기원 | 출처 수 | URL |
|---|---|---|---|---|
| 本宫 / 朕 / 爱卿 / 臣妾 / 小主 | 궁정 자칭·호칭 | 청대 등 궁정 제도, 宫斗剧 → 인터넷 밈 | 2 | TWOC royal-roast, https://www.thepaper.cn/newsDetail_forward_14235252 |
| 臣妾做不到啊 | 해낼 수 없다는 밈 | 《甄嬛传》(2011, 현대 드라마 대사. 수집 대상 아님) | 2 [S] | worldjournal, businessweekly |
| 疾风知劲草 | 역경에서 충절이 드러난다 | 《东观汉记·王霸传》, 광무제 | 3 | https://www.chinanews.com.cn/hwjy/2013/04-27/4772763.shtml , https://en.5000yan.com/chinese-idioms/strong-grass-gale.html , https://p8nda.com/dictionary/疾风知劲草 |
| 士为知己者死 | 알아준 이를 위해 목숨을 건다 | 《史记·刺客列传》 豫让 | 3 | https://www.thepaper.cn/newsDetail_forward_8342284 , https://www.chinatimes.com/cn/opinion/20220709000002-262107 , https://zh.moegirl.org.cn/刺客列传 |
| 腹有诗书气自华 | 배움이 기품을 만든다 | 苏轼《和董传留别》 | 3 | https://www.sohu.com/a/457367216_488646 , https://www.bjnews.com.cn/detail/1794784178019852.html , https://www.theworldofchinese.com/2019/01/the-best-of-su-dongpo |
| 知者不惑,仁者不忧,勇者不惧 | 지·인·용 | 《论语·子罕》 | 2 | https://zh.wikisource.org/wiki/論語/子罕第九 , https://www.aisixiang.com/data/175707.html |
| 大音希声 | 큰 소리는 들리지 않는다 | 《道德经》41장 | 3 | https://in.ncu.edu.tw/~phi/NRAE/newsletter/no65/05.pdf , https://lawdata.com.tw/tw/detail.aspx?no=355485 , https://vincentpoon.poonkwokkin.com/the-most-astounding-sound-is-not-audible.html |
| 言为心声 | 말은 마음의 소리 | 扬雄《法言·问神》"言,心声也" | 3 | https://www.zdic.net/hans/言 , https://chinesenotes.com/words/70463.html , https://xbzs.ecnu.edu.cn/CN/Y2014/V46/I5/10 |

### 오글/과용 목록
- 「本宫」「朕」「爱卿」「小主」 (밈화, TWOC)
- 「臣妾做不到啊」 같은 드라마 명대사 패러디 (世界日报 [S])
- 반문반백으로 고전미를 억지로 내는 대사. 《如懿传》 비판 사례 (界面 [S])
- 翻译腔 감탄사 「哦,我亲爱的」 (ifanr 제목 [S]. 근거 약함)

### 마무리 문장 초안 (창작)
- 黎明圣骑士
  1. 疾风知劲草。风越大,我越看得清你站在哪里。
  2. 黎明总先照向守夜的人。我身侧第一个位置,留给你。
  3. 盾从不被人称赞,却从未后退。我把后背交给你。
- 观星大法师
  1. 星辰只为不停发问的人指路。请一直问下去。
  2. 你翻过的每一页,终将改写这个王国的地图。
  3. 腹有诗书气自华。高塔的钥匙,我交给你保管。
- 暗影斥候
  1. 大音希声。你没说出口的,我都听见了。
  2. 别人错过的,你早已看见。王城因此安睡。
  3. 影子从不背弃光。我相信你也一样。
- 流浪吟游诗人
  1. 言为心声。你的歌,是这座宫廷最真的声音。
  2. 紧闭的城门,也会为笑声松开门闩。
  3. 无论走到哪里,记得把故事带回来给我。

---

## 언어 공통 결론 (추론)
- 네 언어 모두 "정중한 현대어 + 직함 호칭 + 고전 격언 하나"가 가장 덜 오글거린다. 각 언어 커뮤니티가 공통으로 조롱하는 대상은 가짜 고어(EN thee/thou, KO 하오체, JA ですわ 남발, ZH 本宫/翻译腔)와 장르 밈 대사였다.
- 격언은 결과 하나에 하나만 쓰고, 공주가 해석하는 구절을 붙이면 교훈조가 덜하다.
