# ANIMAL 채널 문체 리서치: 숲의 늙은 올빼미 (ko / en / ja / zh)

조사일: 2026-11-19. 조사 방법: WebSearch + WebFetch (공개 페이지만, 로그인 필요 페이지는 시도하지 않음).

## 0. 공통 메모 (가져오기 상태)

- **Project Gutenberg 전체가 HTTP 503**을 반환했다 (Retry-After 21600). 대상: gutenberg.org/files/236 (Jungle Book), /2781 (Just So Stories), /28 (Jacobs Aesop), /21 (Townsend Aesop). 그래서 같은 퍼블릭 도메인 텍스트를 Wikisource, Standard Ebooks, 미국 의회도서관 read.gov/aesop에서 읽었다.
- 맘카페, 네이버 카페, 豆瓣 小组, 5ch, Reddit은 로그인 또는 robots 제한이 걸릴 수 있어서 직접 가져오지 않았다. 해당 항목은 검색 스니펫으로만 참고했고, 아래 표에 "스니펫"이라고 표시했다.
- 이 문서에서 "추론"은 출처가 직접 말한 내용이 아니라 내가 내린 판단이다.
- 출처 수는 이번 세션에서 실제로 본, 서로 독립적인 도메인의 수를 센 것이다.

### 관찰한 공통 구조 (4개 언어)
1. 우화의 교훈은 **이야기 끝에 붙는 한 문장**이다. 짧고 일반화된 현재형 진술이다. 근거: Standard Ebooks에서 교훈은 라벨 없이 이탤릭 독립 행으로 붙는다 ("Each moral is a `<p>` inside a `<footer>`... no label"). 교훈 길이는 read.gov 기준 3~9단어다 ("A kindness is never wasted.", "In unity is strength.", "The race is not always to the swift.").
2. 동물 성격테스트 결과는 **"[형용사 3개] + 행동 한 문장"** 공식을 따른다. 언어가 달라도 같은 문장이 번역만 되어 있다 (miniwebtool ko/zh, jobcannon ko/en). 이 공식이 바로 "개발자가 쓴 듯 밋밋한" 느낌의 원천이다 (추론).

---

## 1. 한국어 (ko)

### 확인한 곳
| URL | 가져옴 여부 | 용도 |
|---|---|---|
| https://ko.wikisource.org/wiki/호랑이_형님 | 가져옴 | 방정환(1926, 『어린이』) 전래동화 구연체 |
| https://ko.wikisource.org/wiki/꼬부랑_할머니 | 가져옴 | 방정환(1929) 반복·리듬 |
| https://ko.wikisource.org/wiki/4월_그믐날_밤 | 가져옴 | 방정환(1924) 밤·자연 배경 |
| https://ko.wikisource.org/wiki/분류:동화 | 가져옴 | 퍼블릭 도메인 동화 목록 (21편) |
| https://m.cafe.daum.net/fm2ss/9V4I/41 | 가져옴 (공개 카페 글) | 속담 풀이 모음 |
| https://www.koreanwikiproject.com/wiki/달도_차면_기운다 | 가져옴 | 속담 |
| https://en.wikipedia.org/wiki/Korean_proverbs | 가져옴 | 동물 속담 |
| https://ko.wikiquote.org/wiki/한국_속담 | 가져옴 | 범 속담 6개 |
| https://ko.wiktionary.org/wiki/여우 | 가져옴 | 여우의 비유 의미 |
| https://miniwebtool.com/ko/영혼-동물-테스트/ | 가져옴 | 동물테스트 결과 문체 |
| https://jobcannon.io/ko/tests/inner-animal-personality-test | 가져옴 | 동물테스트 결과 문체 |
| https://confusingtimes.tistory.com/1045 | 스니펫 | 여우를 피하니 호랑이를 만난다 |
| https://elon.io/grammar/korean/texts/proverb-baekjijangdo-matdeulmyeon , https://sublearn.com/learn/ko/phrases/ko-4840 | 스니펫 | 백지장도 맞들면 낫다 |
| https://pedia.watcha.com/ko/contents/bovqO2P | 스니펫 | 부엉이 그림책 『언제나 널 사랑한단다』 |
| https://oak.ulsan.ac.kr/bitstream/2021.oak/13246/2/200000805567.pdf | 스니펫 | 어미 '-구나'의 의미 |
| https://www.newsspace.kr/mobile/article.html?no=4155 , https://jann.wordreference.com/enko/wolf | 스니펫 | 늑대·여우의 부정적 함의 |
| 맘카페, 네이버 그림책 카페, 유튜브 전래동화 낭독 채널 | 가져오지 않음 | 로그인 또는 동영상이라 확인 불가 |

### 문체 규칙 (LLM 프롬프트용)
1. **해라체 반말을 쓴다. 다정한 일러주기 어미는 `-단다 / -란다`, 새로 알아본 것을 감탄할 때는 `-구나`, 권유는 `-거라`.** '-구나'는 "새로 알게 되거나 새롭게 인지한 것"을 나타내는 감탄 어미다 (울산대 논문 스니펫). '-란다' 어미는 부엉이 그림책 제목 『언제나 널 사랑한단다』(왓챠피디아 스니펫)에서 확인했다. 합니다체나 해요체는 섞지 않는다 (아래 cringe 1 참조).
2. **부르는 말은 `얘야`를 문장 중간에 한 번만 쓴다.** 근거: 방정환 「호랑이 형님」에서 늙은 호랑이가 사람에게 "아이고, 얘야, 그래 어머니께선 지금도 안녕히 계시냐?"라고 말한다 (ko.wikisource). `아가`, `꼬마야`는 출처에서 확인하지 못했다. 쓴다면 추론이다.
3. **도입과 배경은 옛이야기 공식을 짧게 빌린다.** 근거: "옛날 호랑이 담배 먹을 적 일입니다." (「호랑이 형님」). 마무리 줄에서는 공식 자체보다 그 시간감, 곧 "아주 오래전부터 숲에서는"만 가져온다 (추론).
4. **자연물(달, 나무, 별, 밤)을 화자가 실제로 보고 있는 배경으로 쓴다.** 근거: "높은 하늘에는 별만이 반짝반짝 아무 소리도 없는 고요한 밤중이었습니다." (「4월 그믐날 밤」). 올빼미가 달빛 아래 있으므로 달과 나무를 비유 재료로 우선 쓴다.
5. **반복과 의성·의태어 리듬.** 근거: "‘꼬부랑 깽깽’ ‘꼬부랑 깽깽’ 하면서 달아났습니다." (「꼬부랑 할머니」). 마무리 줄은 한 문장이므로 대구(A는 ~, B는 ~)로 리듬만 살린다 (추론).
6. **속담은 "~라 했지/~라는 말이 있단다" 식으로 인용한 뒤, 곧바로 그 아이에게 적용하는 한 구절을 붙인다.** 속담만 던지면 교훈 설교가 된다 (추론).
7. **마무리 줄 길이는 25~45자, 한두 문장.** 근거는 우화 교훈 길이(3~9단어, read.gov)의 한국어 환산이다 (추론).
8. **결과 판정에서 동물의 부정적 함의를 피한다.** 여우는 "매우 간사하고 꾀가 많은 사람"의 비유이고 관용구 "여우 짓", "여우 방정"이 있다 (ko.wiktionary). 늑대는 "남자는 다 늑대"처럼 여성을 노리는 남자의 비유로 쓰인다 (newsspace 칼럼 스니펫). 그래서 '꾀', '간사', '능구렁이' 어휘는 쓰지 말고 '눈치', '눈이 밝다', '재빠르다'를 쓴다.

### 상투 표현 표
| 표현 | 의미 | 기원 | 출처 수 | URL |
|---|---|---|---|---|
| 달도 차면 기운다 | 가득 차면 다시 쇠한다 | 민간 속담 (유래 미확인) | 3 | koreanwikiproject.com/wiki/달도_차면_기운다 ("Even the moon wanes when it is full."), m.cafe.daum.net/fm2ss/9V4I/41, en.wikipedia.org/wiki/Korean_proverbs (검색 결과에 등장) |
| 백지장도 맞들면 낫다 | 쉬운 일도 함께하면 낫다 (협동) | 민간 속담 | 3 | m.cafe.daum.net/fm2ss/9V4I/41, elon.io/...baekjijangdo..., sublearn.com/learn/ko/phrases/ko-4840 |
| 될성부른 나무는 떡잎부터 알아본다 | 될 사람은 어려서부터 보인다 | 민간 속담 | 1 (스니펫 수준 2) | m.cafe.daum.net/fm2ss/9V4I/41 |
| 가지 많은 나무 바람 잘 날 없다 | 식구가 많으면 걱정이 끊이지 않는다 | 민간 속담 | 1 | m.cafe.daum.net/fm2ss/9V4I/41 |
| 원숭이도 나무에서 떨어질 때가 있다 | 잘하는 이도 실수한다 | 민간 속담 | 1 | m.cafe.daum.net/fm2ss/9V4I/41 |
| 호랑이는 죽어서 가죽을 남기고 사람은 죽어서 이름을 남긴다 | 좋은 이름을 남겨라 | 민간 속담 | 2 | m.cafe.daum.net/fm2ss/9V4I/41, ko.wikiquote 계열 범 속담 |
| 하룻강아지 범 무서운 줄 모른다 | 철없는 이가 겁 없이 덤빈다 | 민간 속담 | 3 | ko.wikiquote.org/wiki/한국_속담, m.cafe.daum.net/fm2ss/9V4I/41, yugacrew.com 위키 |
| 토끼 죽으니 여우 슬퍼한다 | 같은 처지의 불행을 슬퍼한다 | 민간 속담 (狐死兔悲) | 2 | en.wikipedia.org/wiki/Korean_proverbs ("When the rabbit dies, the fox mourns"), 검색 요약 |
| 여우를 피하니 호랑이를 만난다 | 작은 화를 피하려다 큰 화를 만난다 | 민간 속담 | 1 (스니펫) | confusingtimes.tistory.com/1045 |
| 호가호위(狐假虎威) | 남의 권세를 빌려 위세를 부린다 | 『전국책』 | 3 (ja/zh와 공통) | 아래 zh 표 참조 |
| 장님 코끼리 만지기 / 군맹무상 | 일부만 보고 전체를 판단한다 | 불교 설화 | 2 | 검색 요약(ko), doc.surf/wiki/blind-men-and-an-elephant |

동물 속담 결핍: 늑대, 코끼리, 돌고래가 나오는 한국 전통 속담은 4개 출처 어디에서도 찾지 못했다 ("No proverbs in the article mention elephant, wolf, owl, moon..." 영문 위키). 그래서 한국어 마무리 줄은 **달, 나무, 숲 속담과 협동 속담**을 동물 이미지와 결합해 쓰는 것이 사실에 맞다.

### Cringe 목록 (피할 것)
1. **테스트 결과 문체를 그대로 쓰는 것.** "당신은 혼자 에너지를 충전하고 ... 충직하게 곁을 지켜요."(jobcannon ko, 해요체)나 "충직하고 직감이 뛰어나며 보호 본능이 강합니다."(miniwebtool ko, 합니다체)처럼 쓰면 올빼미 화자와 레지스터가 충돌한다.
2. **"[형용사, 형용사, 형용사]하며 ~합니다" 3연 나열** (miniwebtool의 모든 동물에 같은 공식이 쓰임). 이 공식이 바로 "generic"하게 읽히는 원인이다 (추론).
3. **여우와 늑대의 부정적 함의를 건드리는 어휘**: 여우 짓, 간사, 꾀돌이, 늑대 같은 남자 (ko.wiktionary, newsspace 스니펫).
4. **"이 이야기가 주는 교훈은 ~입니다" 식의 명시적 설교 라벨.** zh 쪽 증거와 같은 문제다 (아래 참조, 추론).
5. **'영혼의 동물'이라는 말.** spirit animal을 직역한 것이고, 영어권에서 원주민 문화 전유 논쟁이 있다 (en 섹션 참조).
6. 출처가 없는 '전 세계 공통 지혜'를 속담처럼 포장하는 것. 예: "부엉이가 지혜로운 이유는 밤에만 나오기 때문이다"는 tistory 글조차 "특정 국가에서 유래된 것이 아니"라고 밝힌다 (tradelandcompany.tistory.com/30 스니펫).

### 마무리 줄 초안 (독창, 각 3개)
**달 아래 늑대**
1. 백지장도 맞들면 낫다 했지. 얘야, 네가 먼저 손을 내미는 아이라는 걸 숲은 다 알고 있단다.
2. 달빛은 하나여도 그 빛을 나눠 받는 들판은 넓단다. 네가 지키는 이들이 곧 네 숲이란다.
3. 무리를 아끼는 늑대는 제 발소리보다 뒤따라오는 발소리를 먼저 듣는단다.

**꼬리 긴 여우**
1. 눈 밝은 여우는 길을 많이 아는 게 아니라, 막힌 길을 먼저 알아보는 거란다.
2. 얘야, 보이는 걸 다 말하지 않아도 괜찮단다. 아껴 둔 한마디가 더 멀리 가는 법이거든.
3. 재빠른 눈은 쓸 때보다 거둘 때를 아는 게 더 어렵단다. 너는 그걸 배워 갈 아이구나.

**기억하는 코끼리**
1. 느린 걸음이 남긴 발자국은 비가 와도 쉬이 지워지지 않는단다.
2. 달도 차면 기운다지만, 다시 차오르는 길을 아는 건 오래 기억하는 이란다.
3. 얘야, 네가 기억해 둔 작은 일들이 언젠가 누군가에겐 큰 나무 그늘이 될 거란다.

**파도 타는 돌고래**
1. 물결은 혼자 일지 않는단다. 네 웃음이 번지는 곳마다 밤바다도 조금 밝아지는구나.
2. 즐거움을 나눠 주는 아이는 빈손으로 돌아오는 법이 없단다.
3. 파도는 멈추지 않아도 서두르지 않는단다. 얘야, 네 장난기도 그렇게 오래 가거라.

---

## 2. English (en)

### 확인한 곳
| URL | 가져옴 여부 | 용도 |
|---|---|---|
| https://www.gutenberg.org/files/236, /2781, /28, /21 | 실패 (HTTP 503) | 아래 미러로 대체 |
| https://en.wikisource.org/wiki/Just_So_Stories/The_Elephant%27s_Child | 가져옴 | Kipling 화자 공식 |
| https://en.wikisource.org/wiki/The_Second_Jungle_Book/The_Law_of_the_Jungle | 가져옴 | 숲의 법 공식 |
| https://standardebooks.org/ebooks/aesop/fables/v-s-vernon-jones/text/single-page | 가져옴 (0~200k자) | Aesop 교훈 형식 |
| https://read.gov/aesop/ (005, 007, 010, 025, 040, 106, 113) | 가져옴 | The Aesop for Children 교훈 |
| https://en.wikipedia.org/wiki/A_Wise_Old_Owl , https://www.rhymes.org.uk/a_wise_old_owl.htm | 스니펫 | 올빼미 동요 |
| https://www.phrases.org.uk/bulletin_board/6/messages/923.html , https://listserv.linguistlist.org/pipermail/ads-l/2021-April/159629.html , https://knowyourphrase.com/an-elephant-never-forgets | 스니펫 | 코끼리 기억 속담의 기원 |
| https://jobcannon.io/tests/inner-animal-personality-test/results/curious-fox | 가져옴 | 퀴즈 결과 문체 |
| https://miniwebtool.com/spirit-animal-quiz/ , https://jobcannon.io/tests/spirit-animal/results | 스니펫 | 퀴즈 결과 문체 |
| https://ca.news.yahoo.com/why-appropriation-native-spirit-animal-culturally-insensitive-200336538.html , https://www.wellandgood.com/?p=545975 , https://studybreaks.com/culture/everyones-spirit-animal-should-be-cultural-sensitivity | 스니펫 | "spirit animal" 논쟁 |
| r/Fantasy, r/childrensbooks | 가져오지 않음 | Reddit은 비로그인 접근 제한 가능성이 있어 생략 |

### 문체 규칙
1. **어린 상대를 부르는 호칭은 애칭 하나를 정해 반복한다.** 근거: Kipling에서 Baloo가 "Come, Little Brother!", Bagheera가 "Come along, Little Brother"라고 부른다 (검색 스니펫, Mowgli's Brothers). 화자가 자기 무리 밖의 어린 존재에게 쓰는 "Man-cub"도 있다. 올빼미 화자에게는 "little one"이 같은 기능을 한다. 다만 "little one"이라는 형태 자체는 출처에서 확인하지 못했다 (추론).
2. **청자를 부르는 말을 문장 중간 쉼표 사이에 끼운다.** 근거: "In the High and Far-Off Times the Elephant, O Best Beloved, had no trunk." (Wikisource, The Elephant's Child)
3. **숲의 법은 오래되고 참되다는 공식에 대구 반복을 쓴다.** 근거: "Now this is the Law of the Jungle—as old and as true as the sky;" / "For the strength of the Pack is the Wolf, and the strength of the Wolf is the Pack." (Wikisource). 단, 이 문장들은 Kipling 개인의 문장이므로 그대로 쓰지 말고 **A of B is C, and C of B is A** 같은 교차 대구 구조만 빌린다.
4. **교훈은 짧은 일반 현재형 금언이고 2인칭을 쓰지 않는다.** 근거: "A kindness is never wasted." (read.gov/aesop/007), "In unity is strength." (040), "The race is not always to the swift." (025). 마무리 줄은 금언 한 문장에 little one을 향한 짧은 꼬리 한 구절을 더한다 (추론).
5. **교훈 앞에 라벨("Moral:")을 붙이지 않는다.** 근거: Standard Ebooks의 교훈은 라벨 없이 이탤릭 독립 행으로 붙는다.
6. **반복 리프레인으로 성격을 각인한다.** 근거: "And still he was full of 'satiable curtiosity!" (Elephant's Child). 성격 설명 4줄에서 핵심 형용사를 한 번 되풀이하는 데 쓸 수 있다 (추론).
7. **올빼미의 지혜는 말을 아끼고 듣는 데 있다.** 근거: 동요 A Wise Old Owl은 Punch(1875)에 처음 실렸다 (en.wikipedia 스니펫). 내용은 "the more he saw the less he spoke" 계열이다. 이 대목은 원문을 직접 확인하지 않았고 스니펫과 기억에 의존했다 (추론).
8. **어휘는 고풍스럽되 쉽게.** Kipling의 "-eth" 형태("runneth")는 노출이 1회일 때만 허용한다. 어린이 대상 Aesop(read.gov)은 현대 평문이다.

### 상투 표현 표
| 표현 | 의미 | 기원 | 출처 수 | URL |
|---|---|---|---|---|
| In unity is strength. | 함께하면 강하다 | Aesop, The Bundle of Sticks | 1 (원문) + 일반 상식 | read.gov/aesop/040.html |
| The race is not always to the swift / Slow and steady wins the race | 느려도 꾸준하면 이긴다 | Aesop, Hare & Tortoise | 2 | read.gov/aesop/025.html, standardebooks.org (Vernon Jones: "Slow and steady wins the race.") |
| Look before you leap | 뛰기 전에 살펴라 | Aesop, Fox & Goat | 1 | standardebooks.org (Vernon Jones, 원문 표기 "Look before your leap.") |
| A kindness is never wasted. | 친절은 헛되지 않다 | Aesop, Lion & Mouse | 1 | read.gov/aesop/007.html |
| Take warning from the misfortunes of others. | 남의 불행에서 배워라 | Aesop, Old Lion & Fox | 1 | read.gov/aesop/106.html |
| sour grapes | 못 가진 것을 깎아내림 | Aesop, Fox & Grapes | 2 | read.gov/aesop/005.html, standardebooks.org (본문) |
| There is nothing worth so much as liberty. | 자유가 가장 귀하다 | Aesop, Wolf & House Dog | 1 | read.gov/aesop/113.html |
| the strength of the Pack is the Wolf... | 무리와 개인은 서로를 지탱한다 | Kipling, 1895 (퍼블릭 도메인, 단일 저자) | 1 | en.wikisource.org/wiki/The_Second_Jungle_Book/The_Law_of_the_Jungle |
| A wise old owl (lived in an oak) | 말을 아끼는 지혜 | 동요, Punch 1875 | 2 | en.wikipedia.org/wiki/A_Wise_Old_Owl, rhymes.org.uk/a_wise_old_owl.htm |
| An elephant never forgets | 기억력이 좋다 | 19세기 이후. 그리스 낙타 속담에서 왔다는 설이 있음 | 3 | phrases.org.uk/...923.html, listserv.linguistlist.org ads-l 2021-04, knowyourphrase.com |
| wolf in sheep's clothing | 위선자 | Aesop | 2 | read.gov/aesop/022 (색인), 검색 결과(zh 대조 목록) |

주의: Kipling 문구는 출처가 2개 이상이 아니라 **한 근대 작가의 단일 출처**다. 지시에 따라 문장을 그대로 쓰지 않고 구조만 참고한다.

### Cringe 목록
1. **"spirit animal".** 원주민(Anishinaabe 등) 신앙에서 온 개념을 가볍게 쓴다는 비판이 있다. 검색 요약 인용: "Indigenous people are fighting back against the use of the term 'spirit animal' as shorthand for 'I really like this thing.'" (Yahoo/Well+Good 계열). 앱 문구에 쓰지 않는다.
2. **퀴즈식 심리 용어.** 예: "Your superpower is moving between contexts...", "Boredom is your kryptonite; novelty is your fuel." (jobcannon curious-fox). 대중문화 은유와 자기계발 문체라서 우화 톤을 깬다.
3. **"Moral: ..." 라벨과 2인칭 설교.** 우화 교훈은 3인칭 일반 금언이다 (규칙 4·5).
4. **"Elephants never forget" 그대로 쓰기.** 3개 출처에서 확인될 만큼 흔하다. 그대로 쓰면 진부하게 읽힌다 (추론). 비틀어 쓴다.
5. **"lone wolf".** 이 앱의 늑대는 무리 지향형이라 의미가 충돌한다. ja의 一匹狼도 같은 문제다 (maquia: "一匹狼という言葉のとおり、他人との馴れ合いが嫌い").
6. 과도한 고어("thou art", "verily"). Kipling에서도 "-eth"는 드물고, read.gov 어린이판은 평문이다 (추론).

### Closing line drafts (original)
**Wolf under the moon**
1. The moon lights every wolf alike, little one, and you have always made sure no one runs in the dark.
2. A pack is only as warm as the one who waits for the slowest paw. That has always been you.
3. Strong legs carry one wolf far; a faithful heart brings the whole pack home.

**Long-tailed fox**
1. Quick eyes find the trap, little one; wise ones find the way around it.
2. Not every clever thing needs saying. Keep a few tucked under your tail.
3. The fox does not fight the river. It finds the stone, and it waits.

**Elephant who remembers**
1. Slow feet leave the deepest paths, little one, and others will walk them after you.
2. What you remember, you carry; and what is carried kindly grows light.
3. The forest forgets the storm, but it remembers who stood still and sheltered the small ones.

**Wave-riding dolphin**
1. Joy given away comes back on the next wave, little one.
2. A glad heart is a strong one too. Never let anyone tell you play is idle.
3. Laughter travels farther than any current, and it always finds its way back to shore.

---

## 3. 日本語 (ja)

### 확인한 곳
| URL | 가져옴 여부 | 용도 |
|---|---|---|
| https://www.jpf.go.jp/j/project/japanese/teach/tsushin/reserch/201302.html | 스니펫 | 役割語・老人語 (金水敏) |
| https://serve.repo.nii.ac.jp/record/492/files/2083.pdf , https://clrd.ninjal.ac.jp/lrw/lrw2025/o07.pdf | 스니펫 | 博士語「わし」 |
| https://k-rain.repo.nii.ac.jp/record/440/files/kokugakuinzasshi_119_11_021.pdf | 스니펫 | 昔話の発端句・結末句 |
| https://ir.lib.hiroshima-u.ac.jp/53065/files/42874 | 스니펫 | 語り収め |
| https://maquia.hpplus.jp/horoscope/doubutsu-uranai/wolf/ | 가져옴 | 動物占い結果の文体 |
| https://eleschool-compass.com/contents/kotoba/kotowaza/tsukinimurakumohananikaze.php , https://kaikki.org/... 月に叢雲花に風 | 스니펫 | 月に叢雲花に風 |
| https://eleschool-compass.com/contents/kotoba/kotowaza/yorabataijunokage.php , https://oggi.jp/7164587 , https://dime.jp/genre/2064562/ | 스니펫 | 寄らば大樹の陰 |
| https://eleschool-compass.com/contents/kotoba/kotowaza/toranoiokarukitsune.php , https://studychain.jp/media/kotowaza-tora/ , https://jpdb.io/vocabulary/2582980/虎の威を借る狐 | 스니펫 | 虎の威を借る狐 |
| https://precious.jp/articles/-/45632 , https://hugkum.sho.jp/485410 , https://dime.jp/genre/1139634/ | 스니펫 | 石の上にも三年 / 水魚の交わり |
| https://oggi.jp/6728962 , https://www.nihongomaster.com/dictionary/entry/38626/okuriookami | 스니펫 | 送り狼 / 狐につままれる |
| https://www.diqt.net/en/words/1968360 , https://www.hokkaido-np.co.jp/movies/detail/5701713568001/ | 스니펫 | フクロウ＝不苦労 |
| https://Www.Wikipedia.org/wiki/Kitsune_no_yomeiri , https://oggi.jp/7208686 | 스니펫 | 狐の嫁入り |
| kotowaza-allguide.com | 실패 (DNS ENOTFOUND) | |
| 絵本ナビ・5ch 昔話スレ | 가져오지 않음 | |

### 문체 규칙
1. **老人語(役割語)을 쓴다. 자칭은 `わし`, 문말은 `〜じゃ / 〜のう / 〜じゃよ / 〜ておる`.** 근거: "一人称代名詞「わし」や、文末表現「じゃ」などが老人ことばに該当する" (金水 2003, jpf.go.jp 스니펫).
2. **이인칭은 `お前さん`을 쓴다.** `坊や`는 남아를 가리키는 성별 함의가 있어 피한다. 이 판단은 출처에서 직접 확인하지 못했다 (추론). 금수(2016)는 役割語를 "言語共同体で知識として広く共有されている言葉づかい"로 정의한다. 그러므로 `じゃ/わし` 조합만으로도 "늙은 현자"로 즉시 인식된다.
3. **昔話의 定型性, 곧 発端句·結末句와 문말 반복을 의식한다.** 근거: "発端句や結末句（結句）を用いるなどして話の様式性や虚構性を重視する点を特徴" (國學院雜誌 119-11 스니펫). 마무리 줄은 結末句처럼 "이야기 세계에서 현실로 돌려보내는" 기능을 한다 (広島大 스니펫: "異世界から現実に戻ってくる必要がある").
4. **ことわざ는 「〜と言うてのう」로 끌어온 뒤 그 아이에게 적용한다.** 인용 동사를 노인어로 바꾸는 것("言うて")은 추론이다.
5. **동물점 라벨 체(「〜な人」「〜体質」「〜てください」)를 쓰지 않는다.** maquia 결과는 "マイペースで他人の評価を気にしない孤高の人", "自分の直感を信じて生きてください。"처럼 쓴다. 이는 정중체 3인칭 해설이라 올빼미 화자와 충돌한다.
6. **올빼미 화자는 길조 이미지와 맞는다.** フクロウ는 "知恵・学問・守護・不苦労(語呂合わせによる縁起物)"의 상징이다 (diqt 사전 스니펫). 마무리에 "苦労" 말장난을 직접 넣지는 않는다. 아재개그로 읽힐 수 있다 (추론).
7. 길이는 한 문장에 25~45자. 「のう」는 문장당 최대 한 번만 쓴다 (추론).

### 상투 표현 표
| 표현 | 의미 | 기원 | 출처 수 | URL |
|---|---|---|---|---|
| 月に叢雲花に風 | 좋은 일에는 방해가 끼기 쉽다 | 일본 ことわざ | 3 | eleschool-compass.com/...tsukinimurakumohananikaze.php, kaikki.org, oggi.jp/7759866 |
| 寄らば大樹の陰 | 기댈 바엔 큰 나무 그늘에 | 江戸초기 「立ち寄らば大木の蔭」 | 3 | eleschool-compass.com/...yorabataijunokage.php, oggi.jp/7164587, dime.jp/genre/2064562/ |
| 石の上にも三年 | 참고 이어 가면 이룬다 | ことわざ (달마 등 여러 설) | 3 | precious.jp/articles/-/45632, hugkum.sho.jp/485410, dime.jp/genre/1139634/ |
| 水魚の交わり | 떼려야 뗄 수 없는 친밀함 | 『三国志』蜀書 諸葛亮伝 | 3 (zh 포함) | dime.jp/genre/1139634/, oggi.jp/7165118, zdic.net/hant/魚水 |
| 虎の威を借る狐 | 남의 권세로 으스댐 (부정적) | 『戦国策』楚一 | 3 | eleschool-compass.com/...toranoiokarukitsune.php, studychain.jp/media/kotowaza-tora/, jpdb.io/vocabulary/2582980 |
| 狐の嫁入り | 여우비(햇빛 속 비) | 민속 | 3 | Wikipedia Kitsune_no_yomeiri, hyakumonogatari.com/2013/07/19/, oggi.jp/7208686 |
| 群盲象を評す | 부분만 보고 전체를 오판 | 불교 우화 | 2 | doc.surf/wiki/blind-men-and-an-elephant, 검색 요약 |
| 一匹狼 | 단독 행동하는 사람 | 관용어 | 1 | maquia.hpplus.jp/horoscope/doubutsu-uranai/wolf/ |
| 送り狼 / 狐につままれる | 위험한 남자 / 홀린 듯 어리둥절 | 관용어 | 2 | oggi.jp/6728962, nihongomaster.com/.../okuriookami |

### Cringe 목록
1. **送り狼.** 사전 정의가 "親切を装って女性を送っていき、途中で隙があれば乱暴を働こうとする危険な男"이다 (デジタル大辞泉 인용, 검색 스니펫). 늑대 결과 근처에 절대 쓰지 않는다.
2. **一匹狼.** 무리형 늑대와 의미가 충돌한다 (maquia).
3. **虎の威を借る狐 / 狐につままれる.** 둘 다 여우가 부정적이거나 당하는 쪽이다. 여우 결과에 쓰지 않는다.
4. **動物占い 라벨체**(「〜な人」「〜体質」「〜てください」). 위 규칙 5 참조.
5. **노인어 과잉**(「〜じゃ」를 문장마다 넣거나 「ふぉっふぉっふぉ」 같은 웃음 표기). 캐릭터 희화화로 읽힌다 (추론. 役割語가 스테레오타입이라는 점은 金水가 지적).
6. `坊や` 같은 성별 호칭 (추론).

### 締めの一言 草案 (オリジナル)
**月下の狼**
1. 群れを想う心はのう、月の光と同じで、分けても減りはせんのじゃ。
2. お前さんが守ってきたものは、ちゃんとお前さんのことも守っておるよ。
3. ひとりの遠吠えに返事がある。だから夜の森は怖くないんじゃよ。

**尾の長い狐**
1. 賢い狐はのう、近道よりも先に、帰り道を覚えておくもんじゃ。
2. 見えたことを全部言わんでもよい。黙っておくのも、また知恵じゃよ。
3. お前さんの目の速さは、誰かを助けるときにいちばん光るんじゃ。

**覚えている象**
1. 石の上にも三年と言うてのう。お前さんの歩みは、もう石を温めておる。
2. 覚えておることは重荷ではない。いつか誰かの道しるべになるんじゃ。
3. ゆっくりの足跡ほど、深く、長く残るものじゃよ。

**波乗りイルカ**
1. 水魚の交わりと言うてのう、お前さんにとって仲間は水そのものじゃ。
2. 笑い声は波と同じでのう、遠くまで届いて、また戻ってくるんじゃ。
3. 遊び心を忘れるでないぞ。それがいちばん丈夫な舵なんじゃから。

---

## 4. 中文 (zh)

### 확인한 곳
| URL | 가져옴 여부 | 용도 |
|---|---|---|
| https://zh.wikisource.org/wiki/水調歌頭_(明月幾時有) | 가져옴 (원문 인용은 도구가 거부, 내용만 요약) | 月有阴晴圆缺 |
| https://djangocas.dev/free-books/the-aesops-fables-for-children/016-the-stag-and-his-reflection-雄鹿和他的倒影.html | 가져옴 | 寓言 교훈 라벨 "寓意：" |
| https://book.douban.com/review/4503760/ | 가져옴 (공개 서평) | "这个故事说明" 공식 |
| https://www.toutiao.com/zixun/7496127678087088191/ | 스니펫 | 寓言은 说教적이라는 인식 |
| https://miniwebtool.com/zh-cn/守护灵兽测试/ | 가져옴 | 测试结果 문체 |
| https://www.sohu.com/a/952682353_122498367 | 가져옴 | 밈식 동물 유형 |
| https://en.5000yan.com/chinese-idioms/fox-borrows-tigers-might.html , https://chinesenotes.com/words/17217.html , https://www.digmandarin.com/chinese-idioms-chengyu-animals.html | 스니펫 | 狐假虎威 / 老马识途 / 狼狈为奸 |
| https://www.zdic.net/hant/魚水 , https://chinesemoment.com/?p=15246 , https://rpl-web.pages.dev/categories/culture/chinese-idiom-story-如鱼得水 | 스니펫 | 如鱼得水 |
| https://p8nda.com/dictionary/狐死首丘 , https://ctext.org/liji/ji-yi/zhs?en=on | 스니펫 | 狐死首丘 |
| https://hsklord.com/dictionary/独木不成林 , https://www.hanbook.com/...1799887 , https://baike.sogou.com/v7650664.htm | 스니펫 | 独木不成林 / 众人拾柴火焰高 |
| https://hbreader.org/words/1002491.html , kaweah.freedombox.rocks (Wiktionary 路遥知马力) | 스니펫 | 路遥知马力 |
| https://yoyochinese.com/blog/Useful-and-unique-Chinese-animal-related-expressions , https://www.lingoace.com/blog/fox-in-chinese-idioms/ , Wikipedia Fox spirit | 스니펫 | 白眼狼 / 狐狸精의 부정적 함의 |
| 豆瓣 绘本 小组 | 가져오지 않음 | 小组은 로그인이 필요할 수 있음. 공개 서평 1건만 확인 |

### 문체 규칙
1. **호칭은 `孩子`를 쓴다.** 문장 첫머리나 쉼표 뒤에 한 번 둔다. `小家伙`는 더 장난스럽다. 둘 다 이번 출처에서 노인 화자 용례를 확인하지 못했다 (추론).
2. **어기사 `呀 / 啊 / 哟`는 한 번만 써서 할아버지 말투의 따뜻함을 준다.** 과하게 쓰면 아동 프로그램 진행자 말투가 된다 (추론).
3. **성어와 谚语는 4자 성어 하나를 문장 앞에 놓고, 뒤에 "就是你/说的就是你" 식으로 아이에게 연결한다.** 성어 의미가 긍정적인 것만 고른다 (아래 cringe 참조).
4. **"这个故事说明 / 告诉我们", "寓意：" 라벨을 쓰지 않는다.** 근거: 伊索 번역 서평에 "这个故事说明，劳动是人类最好的宝物." 같은 공식이 반복된다 (豆瓣 4503760). 쌍어 교재는 "寓意：" 라벨을 쓴다 (djangocas). 寓言은 "比童话直白得多，也更偏向说教"라는 인식이 있다 (toutiao 스니펫). 올빼미는 설교하지 않고 축복으로 끝낸다.
5. **测试结果의 "[3형용사]，你..." 공식을 쓰지 않는다.** 근거: "忠诚、直觉敏锐且富有保护欲，你凭心引领，愿为伙伴赴汤蹈火。" (miniwebtool zh-cn, 狼).
6. **달 이미지는 苏轼 「水调歌头」의 圆缺 순환에서 빌린다.** 이 작품은 1076년 작이다 (zh.wikisource). 다만 구절을 통째로 인용하면 "중추절 카드"처럼 진부해지므로 `圆缺` 두 글자만 빌린다 (추론).
7. 길이는 18~35자, 쉼표 하나로 끊는 대구(前句 비유 + 後句 적용).

### 상투 표현 표
| 표현 | 의미 | 기원 | 출처 수 | URL |
|---|---|---|---|---|
| 月有阴晴圆缺 | 달도 차고 기우는 법 (인생 무상과 순환) | 苏轼 「水调歌头」(1076) | 2 | zh.wikisource.org/wiki/水調歌頭_(明月幾時有), 검색 요약(hbreader 등) |
| 路遥知马力，日久见人心 | 오래 겪어야 참된 힘과 마음을 안다 | 『增广贤文』 | 2 | hbreader.org/words/1002491.html, Wiktionary 미러 |
| 老马识途 | 경험 많은 이가 길을 안다 | 『韩非子·说林上』 | 2 | en.5000yan.com (스니펫), digmandarin.com |
| 如鱼得水 | 꼭 맞는 곳과 벗을 만남 | 『三国志·蜀书·诸葛亮传』 | 3 | zdic.net/hant/魚水, chinesemoment.com/?p=15246, rpl-web.pages.dev |
| 狐死首丘 | 고향과 근본을 잊지 않음 | 『礼记』·『楚辞』 | 2 | p8nda.com/dictionary/狐死首丘, ctext.org/liji |
| 独木不成林 | 혼자서는 숲을 이루지 못한다 | 谚语 | 2 | hsklord.com/dictionary/独木不成林, baike.sogou.com/v7650664.htm |
| 众人拾柴火焰高 | 모두 땔감을 보태면 불길이 높다 | 谚语 | 2 | hanbook.com/...1799887, baike.sogou.com |
| 狐假虎威 | 남의 위세를 빌림 (부정적) | 『战国策·楚一』 | 3 | en.5000yan.com, chinesenotes.com/words/17217.html, digmandarin.com |
| 狼狈为奸 | 결탁해 나쁜 짓을 함 (부정적) | 출처 논쟁 | 2 | en.5000yan.com/chinese-idioms/wolf-jackal-cahoots.html, paper.people.com.cn PDF |
| 盲人摸象 / 众盲摸象 | 일부만 보고 전체를 판단 | 불교 경전 | 2 | 검색 요약(ja·zh), doc.surf |

### Cringe 목록
1. **늑대와 여우의 부정 성어와 속어**: 白眼狼, 狼心狗肺, 狼狈为奸, 狐狸精, 狐朋狗友, 露出狐狸尾巴. 인용: "'白眼狼'与'狼心狗肺'都用来形容心肠极冷、残忍的人" (yoyochinese 검색 요약). 狐狸精은 "善于欺骗、会变成美女" 이미지다 (Fox spirit 위키). 결과 근처에서 연상되지 않게 한다.
2. **"这个故事告诉我们 / 说明" 설교 공식** (豆瓣 서평, toutiao 스니펫).
3. **밈 문체**: "独行侠，背影=“江湖再见”", "快乐源泉，跃出水面=“嗨～”" (sohu). 올빼미 톤과 정반대다.
4. **测试结果 3형용사 공식** (miniwebtool zh-cn).
5. 苏轼 구절을 통째로 인용하는 것 ("但愿人长久..."). 너무 유명해서 명절 문구처럼 읽힌다 (추론).

### 结尾句 草稿 (原创)
**月下之狼**
1. 孩子，独木不成林；你守着的那群伙伴，就是你的森林。
2. 月光照着每一只狼，不偏不倚，你待伙伴也是这样。
3. 跑得再远，也要回头听一听同伴的脚步声，你一直都记得。

**长尾狐狸**
1. 聪明的狐狸呀，不急着找近路，先记住回家的路。
2. 看得清，不必都说破，孩子；留一句，才有余味。
3. 机灵是一盏灯，用来照路的时候最亮。

**记得一切的大象**
1. 路遥知马力，孩子，你慢慢走，脚印会比谁都深。
2. 记得的事不是包袱，是将来给别人遮阴的大树。
3. 月有圆缺，可记得回来的路的，总是你。

**踏浪的海豚**
1. 如鱼得水，说的就是你回到伙伴身边的样子。
2. 笑声像浪花，孩子，送出去，总会再拍回岸边。
3. 爱玩的心不是轻浮，是最结实的船桨哟。

---

## 5. 한계
- 맘카페, 그림책 카페, Reddit, 豆瓣 小组, 5ch는 직접 확인하지 못했다. 그래서 "실제 독자 커뮤니티"의 반응 근거는 공개 서평 1건(豆瓣)과 공개 다음카페 글 1건에 그친다.
- Gutenberg 503 때문에 Jacobs와 Townsend 판의 교훈은 직접 대조하지 못했다. 대신 read.gov(The Aesop for Children)와 Standard Ebooks(Vernon Jones)로 대체했다.
- 표준국어대사전 '-단다' 뜻풀이는 가져오지 못했다. 사이트 검색 결과에 문법 항목이 나오지 않았다.
- "little one", "孩子", "お前さん"이 늙은 동물 화자의 호칭으로 쓰인 직접 용례는 확인하지 못했다. 모두 추론이다. 한국어 "얘야"만 퍼블릭 도메인 원문(방정환)으로 확인했다.
