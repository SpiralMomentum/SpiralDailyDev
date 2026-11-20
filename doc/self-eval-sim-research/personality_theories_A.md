# 성격 이론 조사 A 그룹 (무협 캐릭터별 판정 이론 후보)

조사일: 2026-11-20

표기 규칙
- 인용은 실제로 가져온 페이지의 원문 그대로다. 학술 초록은 OpenAlex/Crossref API(`https://api.openalex.org/works/doi:<DOI>`)로 받은 초록 텍스트이고, 출처는 DOI URL로 적는다.
- [S]: 검색 결과 요약(스니펫)으로만 본 내용이다. 원문으로 확인하지 못했으므로 사실로 쓰지 않는다.
- PMC(pmc.ncbi.nlm.nih.gov)는 robots.txt가 `Disallow: /`라서 쓰지 않았다. PubMed는 쿠키/봇 차단 때문에 본문을 받지 못했다. europepmc.org와 hull-repository는 Anthropic 계열 에이전트를 차단해서 쓰지 않았다. angeladuckworth.com도 `anthropic-ai`를 차단해서 가져오지 않았다.
- 조회수는 사람이 본 조회(user agent)만 센 것이다. 기간은 2025-11 ~ 2026-10 월별 합계이고, Wikimedia REST pageviews API로 받았다.

## 요약 표

| 이론 | 결과 경우의 수 | 근거 강도 | 위키 조회수 en / ko (12개월) | 라이선스 | 적합도 1-5 |
|---|---|---|---|---|---|
| Big Five (FFM) | 5요인 연속. 고/저 2^5=32, 고/중/저 3^5=243 | 강: 56개국 구조 재현, 152개 종단연구 메타분석 | 604,017 / 6,346 | IPIP 퍼블릭 도메인. NEO-PI-R은 상용 | 5 |
| HEXACO | 6요인(25 facet). 2^6=64 | 강: N=100,318 표본에서 위계구조 확인. 단 Big Five보다 연구량이 적음 | 48,319 / 90 (ko는 3개월치만 있음) | HEXACO-PI-R은 비영리 학술용만 무료이고 공개 앱 배포는 금지. IPIP-HEXACO 대안 있음 | 5 |
| Eysenck PEN | E·N·P(+L). 2^3=8 | 중: 34개국 요인 비교. P 척도 신뢰도 낮음 [S] | EPQ 15,540 (Hans Eysenck 41,756) / 한스 아이젠크 409 | EPQ는 출판사 저작물. IPIP 목록에 없음 | 3 |
| Cloninger TCI | 기질 4 + 성격 3 = 7차원. 2^7=128 (3+3 조합이면 8x8) | 약~중: 7요인 구조 재현 실패 보고가 반복됨 | 14,136 / 1,147 (ko 7개월치) | 저작권 보유, 배포는 서면 허가 필요 [S]. IPIP-TCI 있음 | 3 |
| Gray RST (BIS/BAS) | 고전 BIS x BAS = 4사분면. 개정판 RST-PQ는 6요인 | 중: 이론 기반 강함. 측정도구가 개정 이론을 반영 못 함 | 5,716 / 없음 | Carver-White BIS/BAS는 IPIP 대응 척도 있음 | 4 |
| Dark Triad / SD3 | 3특성 2^3=8. 한국판은 2요인 | 중: 메타분석은 있으나 세 특성의 변별성에 의문. 한국에서 3요인 재현 실패 | 455,200 / 1,499 | SD3 허가조건 확인 못 함. IPIP 목록에 없음 | 2 (윤리 문제) |
| Zuckerman 감각추구 | SSS-V 4하위척도 2^4=16. BSSS는 단일차원 | 중: 이탈리아 SSS-V는 2요인만 나옴, 알파 "marginal" | 20,736 / 없음 | 확인 못 함 | 4 |
| 성인 애착 (ECR-R) | 2차원(불안·회피) -> 4유형 | 중~강: 알파 .90 이상, 3주 공유분산 85%. 저자가 유형 분류에 반대 | Attachment in adults 116,377 (Attachment theory 332,365) / 성인 애착 2,257 | 학술지에 공개. 상업적 사용은 허가 필요 | 2 (민감성, 유형화 반대) |
| Rotter 통제소재 | 1차원(내/외). 2~3 | 중: 직장 메타분석 있음. 단일차원 가정에 반론 | 103,799 / 782 | 확인 못 함 | 4 |
| Snyder 자기감시 | 1차원(고/저). 2 | 약~중: 척도가 다요인이라는 논쟁. 메타분석 136표본 | 15,399 / 583 | 확인 못 함 | 4 |
| Duckworth 그릿 | 2 facet(노력 지속, 관심 일관성). 2^2=4 | 약~중: 메타분석에서 고차구조 미확인, 성실성과 매우 높은 상관 | 64,975 / 4,550 | 비영리 무료, 상업적 사용 금지 [S] | 3 (성실성과 중복) |

조회수 비교 기준: Big Five 604K, Dark triad 455K, Attachment theory 332K가 상위다. RST(5.7K)는 대중 인지도가 매우 낮다.

---

## 1. Big Five / Five-Factor Model

1. **구조**: 개방성, 성실성, 외향성, 친화성, 신경성의 5개 연속 차원이다. 하위 facet은 BFI-2 기준 15개, NEO 기준 30개다. 결과는 고/저로 나누면 32가지, 고/중/저면 243가지다.
2. **과학적 근거**
   - 재검사 안정성 메타분석: "From 152 longitudinal studies, 3,217 test-retest correlation coefficients were compiled ... trait consistency increased from .31 in childhood to .54 during the college years, to .64 at age 30, and then reached a plateau around .74 between ages 50 and 70" (https://doi.org/10.1037/0033-2909.126.1.3, Roberts & DelVecchio 2000, OpenAlex 초록)
   - 문화 간 재현: "the BFI was translated from English into 28 languages and administered to 17,837 individuals from 56 nations ... The five-dimensional structure was robust across major regions of the world." (https://doi.org/10.1177/0022022106297299, Schmitt et al. 2007)
   - 유전율 메타분석: "The average effect size was .40, indicating that 40% of individual differences in personality were due to genetic" (https://doi.org/10.1037/bul0000017, Vukasović & Bratko 2015)
   - 예측력: Wikipedia에 따르면 "an estimated population correlation of 0.26 between conscientiousness and supervisory ratings" (https://en.wikipedia.org/wiki/Big_Five_personality_traits)
   - 비판: "Attempts to replicate the Big Five have succeeded in some countries but not in others." / "the Openness factor is particularly unsupported in Asian countries" / "The main criticism of the Big Five traits is that they do not explain enough of human personality" (같은 Wikipedia 페이지). 한국 사용자 대상이므로 개방성 요인은 측정 신뢰도가 낮을 수 있다는 점을 고려해야 한다.
   - 내적일관성 알파는 원문 수치를 확보하지 못했다. BFI-2 초록에는 "reliable and valid"라는 정성적 서술만 있다 (https://doi.org/10.1037/pspp0000096).
3. **인기도**: en 604,017 / ko "5가지 성격 특성 요소" 6,346
4. **문항/라이선스**: IPIP는 "The items and scales are in the public domain"이고 "without asking permission and without paying a fee"라고 명시한다. 문항 수는 "The 3,320 IPIP items", 척도는 "over 250 scales"다 (https://ipip.ori.org/). IPIP는 NEO-PI-R 도메인과 facet 대응 척도를 제공한다 (https://ipip.ori.org/newMultipleconstructs.htm). NEO-PI-R/NEO-FFI는 상용 도구(PAR 출판)지만 공식 상표 등록 여부는 확인하지 못했다. 내부에서 "Big Five"라는 이론명을 쓰는 것은 상표 문제가 없을 것으로 보이지만 확인하지는 않았다. NEO 같은 도구명은 쓰지 않는 편이 안전하다.
5. **적합도 (5)**: 차원마다 행동 상황(갈등, 모험, 계획, 사교)을 만들기 쉽고, 누적 점수 방식과 잘 맞는다. 윤리 부담이 낮다. 다만 신경성 "고"는 부정 낙인으로 읽힐 수 있으니 결과 문구를 중립적으로 쓴다(예: 섬세함). **아키타입**: 첫 만남 상대인 평민(객잔 주인). 사람을 두루 보는 기본 잣대 역할이다.

## 2. HEXACO

1. **구조**: 정직-겸손(H), 정서성(E), 외향성(X), 친화성(A), 성실성(C), 개방성(O)의 6요인이다. "each of which contains four "facets"" 외에 "25th narrow facet, called altruism"이 있다 (https://en.wikipedia.org/wiki/HEXACO_model_of_personality_structure). 고/저로 나누면 64가지다.
2. **과학적 근거**
   - "The new model is consistent with the cross-culturally replicated finding of a common six-dimensional structure" (https://doi.org/10.1177/1088868306294907, Ashton & Lee 2007)
   - HEXACO-100 심리측정(N=100,318): "the hierarchical structure of the HEXACO-100 was clearly supported ... only one pair of scales (Honesty-Humility and Agreeableness) having an absolute correlation above .20 in self-report data ... strong self/observer convergent correlations" (https://doi.org/10.1177/1073191116659134, Lee & Ashton 2018)
   - 비판: "De Raad et al. argue that "only three personality traits have fully replicated"" (Wikipedia HEXACO)
   - Dark Triad와의 관계: dark triad 특성은 "predominantly related to the Big Five personality factor of agreeableness and the HEXACO factor of honesty-humility" (https://doi.org/10.1177/1745691616666070). 따라서 H 차원으로 Dark Triad의 핵심을 비낙인적으로 다룰 수 있다.
   - 알파 수치는 확보하지 못했다.
3. **인기도**: en 48,319 / ko "HEXACO 성격 구조 모델" 90. ko 문서는 최근에 생겨서 3개월치 데이터만 있다.
4. **문항/라이선스**: 공식 사이트 원문은 "You can download any of these forms free of charge, but only for the purpose of non-profit academic research."이고 "we do not allow researchers to collect data through an online survey site or an app accessible by the general public."이다 (https://hexaco.org/hexaco-inventory). 공식 문항을 앱에 쓰는 것은 명시적으로 금지된다. 자체 문항만 쓴다는 계획이면 문제 없고, 대안으로 IPIP 목록에 "Lee and Ashton's (2004) HEXACO-PI"가 있다 (https://ipip.ori.org/newMultipleconstructs.htm). "HEXACO"의 상표 등록 여부는 확인하지 못했다.
5. **적합도 (5)**: Big Five와 같은 장점에 정직-겸손 차원이 더해져 무협의 의리, 탐욕, 협(俠) 서사와 직접 맞물린다. Big Five와 같은 캐릭터 축에 놓으면 중복되므로, 둘 중 하나를 기본 축으로 쓰고 다른 하나를 가중치 변형으로 쓰는 것이 폴백 방식에 맞다. **아키타입**: 정파 명문 장문인. 의(義)와 정직을 따지는 인물이다.

## 3. Eysenck PEN (EPQ)

1. **구조**: 외향성(E), 신경성(N), 정신병적 경향성(P)에 허위척도(L)가 붙는다. "two biologically based independent dimensions of temperament"(E, N) 다음에 P가 추가됐다. EPQ-R은 "100 yes/no questions in its full version"이고 단축형은 48문항이다 (https://en.wikipedia.org/wiki/Eysenck_Personality_Questionnaire). 고/저로 나누면 8가지다. E x N 2x2는 고전적인 4기질(다혈/담즙/점액/우울)과 대응한다.
2. **과학적 근거**
   - 문화 간 비교: "the factorial similarity of P, E, N, and L across 34 countries" (Wikipedia EPQ). 표준화 프로젝트는 "over some 25 years"에 걸쳐 진행됐다 (https://doi.org/10.1016/j.paid.2012.09.022).
   - P 척도 신뢰도: [S] 원판 EPQ-R의 알파는 남성 기준 P .78 / E .90 / N .88, 단축형 P는 0.33-0.52, 포르투갈판 P는 0.55로 보고된다. 원문 확인은 못 했다. 방향(P가 가장 낮음)은 여러 출처에서 일치한다.
3. **인기도**: en EPQ 15,540, Hans_Eysenck 41,756, Psychoticism 11,175 / ko "한스 아이젠크" 409 (EPQ 단독 문서는 ko에 없음)
4. **문항/라이선스**: 매뉴얼은 Hodder and Stoughton 출판(1975)이다 (Wikipedia). IPIP의 다중구성개념 목록에는 EPQ가 없다(위 IPIP 페이지에서 확인). 이론명을 내부에서 쓰는 데 상표 문제가 있는지는 확인하지 못했다.
5. **적합도 (3)**: E와 N은 Big Five와 겹친다. 고유한 축은 P뿐인데 P는 "psychotic episode" 소인과 연결된 이름이고 신뢰도도 낮아서 낙인과 측정 양면에서 약하다. 쓴다면 4기질(E x N)만 차용하는 편이 낫다. **아키타입**: 맥과 체질을 보는 의원(의선). 다혈/담즙/점액/우울 4체질 진단 프레임과 맞는다.

## 4. Cloninger TCI (기질 및 성격 검사)

1. **구조**: 기질 4개(새로움 추구 NS, 위험 회피 HA, 보상 의존 RD, 인내 P)와 성격 3개(자기주도성 SD, 협동성 C, 자기초월 ST)다. "a 240-item questionnaire"이고 TCI-R은 5점 척도다 (https://en.wikipedia.org/wiki/Temperament_and_Character_Inventory). 고/저로 나누면 2^7=128가지다. NS/HA/RD 3축 8유형 x SD/C/ST 3축 8유형 = 64 조합도 가능하다(Cloninger의 8유형 명명은 이번 조사에서 원문 확인 못 함).
2. **과학적 근거**
   - 원저: "Data on 300 individuals from the general population support the reliability and structure of these seven personality dimensions." 성격 차원은 "mature in adulthood"한다 (https://doi.org/10.1001/archpsyc.1993.01820240059008, Cloninger et al. 1993)
   - 비판: "Collectively, these studies failed to replicate Cloninger's structure and their internal consistency remained low." 같은 논문의 자체 TPQ 알파는 NS 0.63, HA 0.82, RD 0.61이고 하위척도 NS1은 0.35까지 내려간다 (https://www.frontiersin.org/articles/10.3389/fpsyt.2024.1436121/full, Sawalma et al. 2024. 대상은 TCI의 전신인 TPQ)
   - [S] BLSA 표본 연구(2000)에서 "hypothesized phenotypic structure"가 나오지 않았다는 보고가 있다. 원문 미확인.
   - 신경전달물질 가설(DAT1, DRD4)은 Wikipedia에서도 "citation needed" 표시가 붙어 있다.
3. **인기도**: en 14,136 / ko "기질 및 성격 검사" 1,147 (ko는 7개월치. 한국 임상/상담 현장에서 쓰이는 것으로 알려져 있으나 수치로 확인하지는 않음)
4. **문항/라이선스**: [S] TCI-R 양식에 Cloninger 저작권과 Washington University Center for Well-Being 배포 허가가 표기돼 있고, 배포에는 "express written permission"이 필요하다고 한다. 원문은 미확인이다. IPIP에는 "Temperament and Character Inventory (TCI; Cloninger, et al., 1994)" 대응 세트가 있다 (https://ipip.ori.org/newMultipleconstructs.htm). 상용 검사이므로 이름과 문항 모두 외부 노출을 피한다.
5. **적합도 (3)**: "타고난 기질 vs 수양으로 성숙하는 성격"이라는 구도는 무협 서사와 잘 맞는다. 다만 구조 재현성이 약하고 7차원이라 회당 4~6문항으로는 수렴이 느리다. 차원 몇 개만 골라 쓰는 방식을 권한다. **아키타입**: 은둔 고수. 타고난 근골(기질)과 닦은 심법(성격)을 따로 보는 사부다.

## 5. Gray 강화 민감성 이론 (RST, BIS/BAS)

1. **구조**: 고전판은 BIS(처벌/불안)와 BAS(보상/접근)이다. 개정판(2000)은 FFFS가 추가된 3체계다. "These critiques led to a major revision and renaming of the theory in 2000." (https://en.wikipedia.org/wiki/Reinforcement_sensitivity_theory). Carver-White BAS는 Reward Responsiveness, Drive, Fun Seeking의 3하위척도다. RST-PQ는 "a robust 6-factor structure: ... FFFS ... BIS ... and 4 behavioral approach system (BAS) factors (Reward Interest, Goal-Drive Persistence, Reward Reactivity, and Impulsivity)" (https://doi.org/10.1037/pas0000273, Corr & Cooper 2016). 결과 단위는 BIS x BAS 4사분면이 가장 단순하다.
2. **과학적 근거**
   - Carver & White 1994 초록: "Ss high in BIS sensitivity (assessed earlier) were more nervous than those low in BIS sensitivity ... Ss high in BAS sensitivity (Reward Responsiveness and Drive scales) were happier ... In each case the new scales predicted better than an alternative measure." 피인용은 8,541회다 (OpenAlex 기준) (https://doi.org/10.1037/0022-3514.67.2.319)
   - 비판: "the boundary between FFS (threat response system) and BIS (punishment system) was difficult to define empirically". 기존 척도에 대해서는 "These definitions were not updated to reflect the revised RST model" (Wikipedia RST)
   - 알파와 재검사 수치는 확보하지 못했다.
3. **인기도**: en 5,716 / ko 문서 없음. 그룹 내 최저라 대중 인지도 조건에 미달한다.
4. **문항/라이선스**: IPIP에 "Behavioral Inhibition/Activation Systems (BIS/BAS; Carver & White, 1994)" 대응 세트가 있다 (https://ipip.ori.org/newMultipleconstructs.htm). Carver의 무료 사용 안내 페이지는 404라서 확인하지 못했다.
5. **적합도 (4)**: "위험이 보일 때 멈추는가, 보상이 보일 때 달려드는가"를 선택지 1개로 깔끔하게 태깅할 수 있어 상황형 문항에 매우 잘 맞는다. 윤리 부담도 낮다. 약점은 인기도다. **아키타입**: 병법가(군사). 진격과 퇴각의 성향을 읽는 인물이다.

## 6. Dark Triad / Short Dark Triad (SD3)

1. **구조**: 마키아벨리즘, 나르시시즘, 사이코패시의 3특성이다. SD3는 "27-item test, with 9 questions measuring each trait"이고 Dirty Dozen은 12문항이다 (https://en.wikipedia.org/wiki/Dark_triad). 고/저로 나누면 8가지다.
2. **과학적 근거**
   - SD3 원저: "Four studies (total N = 1,063) ... structural analyses yielded three factors with the final 27 items loading appropriately" (https://doi.org/10.1177/1073191113514105, Jones & Paulhus 2014, Crossref 초록)
   - 메타분석 비판: "We question whether dark triad traits are sufficiently distinct and argue that the way they are currently measured is too simple" (https://doi.org/10.1177/1745691616666070, Muris et al. 2017)
   - 한국판: "yielded two factors of Machivellianism-Psychopathy (Ma-Psy) and Narcissism in Korea and did not suport the 3-factor solution of the original SD3" (https://doi.org/10.24230/kjiop.v34i3.511-539, 2021). 한국 사용자에게 3유형으로 결과를 나누는 것은 근거가 약하다.
   - 구조 연구: "Machiavellianism as it is currently measured is an aspect of psychopathy" (https://doi.org/10.1007/s12144-018-9834-6)
   - Wikipedia: 저자들도 "rely on an overall SD3 score rather than interpreting individual subscales"를 권고한다.
3. **인기도**: en 455,200 / ko "다크 트라이어드" 1,499. 영어권 인기도는 Big Five 다음으로 높다.
4. **문항/라이선스**: SD3 사용 허가 조건은 Paulhus 홈페이지에 명시가 없어 확인하지 못했다. IPIP 다중구성개념 목록에는 없다.
5. **적합도 (2)**: 윤리 문제가 크다. Wikipedia에도 용어가 "being stigmatizing, sensationalistic, and potentially offensive"라는 비판이 있다고 적혀 있다. 사용자에게 "사이코패스 성향"을 판정하는 것은 부정 낙인이다. 대안은 HEXACO의 정직-겸손(낮음 = 야망·실리 추구)으로 같은 영역을 중립적으로 다루는 것이다. 굳이 쓴다면 단일 총점("어둠에 대한 친화도")과 긍정 프레이밍("목적을 위해 수단을 가리지 않는 결단력")으로 제한한다. **아키타입**: 마교 교주(최종 보스). 사용자 안의 "마(魔)의 소질"을 보는 인물로, 결과는 긍정 프레임으로 쓴다.

## 7. Zuckerman 감각추구 (Sensation Seeking)

1. **구조**: 4하위척도(원문 정의). Thrill and adventure seeking "Desire for outdoor activities involving unusual sensations and risks", Experience seeking, Disinhibition, Boredom susceptibility "intolerance of repetition or boring people" (https://en.wikipedia.org/wiki/Sensation_seeking). 고/저로 나누면 16가지이고, BSSS(8문항)는 단일 점수다.
2. **과학적 근거**
   - 이탈리아 SSS-V(N=1,530): "Exploratory factor analysis highlighted a 2-factor structure, Thrill and Adventure Seeking (TAS) and Disinhibition (Dis) ... Internal consistency of the subscales was marginally supported" (https://doi.org/10.5964/ejop.v9i2.500, 2013)
   - Wikipedia는 최신판이 "moderately valid and reliable"하다고만 적고 수치는 없다.
   - [S] BSSS 알파 0.76(Hoyle et al. 2002), 페루 청소년 BSSS-8 .745. 원문 미확인이다.
3. **인기도**: en 20,736 / ko 문서 없음
4. **문항/라이선스**: 확인하지 못했다. IPIP 다중구성개념 목록에는 없다.
5. **적합도 (4)**: 상황형 선택(위험한 길 vs 안전한 길, 낯선 무공 시험)으로 만들기 매우 쉽고 무협 장르와 궁합이 좋다. 4하위척도는 재현성이 약하므로 TAS와 Dis 2축 정도로 줄이는 것을 권한다. **아키타입**: 떠돌이 낭인 검객 또는 표국 표사. 위험을 즐기는지 보는 인물이다.

## 8. 성인 애착 (ECR / ECR-R)

1. **구조**: 2차원(애착 불안, 애착 회피). ECR-R은 36문항(18+18)이다. 2x2를 Bartholomew의 4유형(secure, preoccupied, dismissing, fearful)에 대응시킨다 (https://labs.psychology.illinois.edu/~rcfraley/measures/ecrr.htm).
2. **과학적 근거**
   - 내적일관성: "The commonly used estimate of internal consistency reliability tends to be .90 or higher for the two ECR-R scales." (Fraley ECR-R 페이지)
   - 안정성: "the ECR-R provided highly stable indicators of latent attachment during a 3-week period (85% shared variance)" (https://doi.org/10.1177/0146167205276865, Sibley et al. 2005)
   - 차원 vs 유형: Fraley 페이지는 분류법 분석이 "suggest that variation in attachment is best modeled with dimensions rather than categories"라고 하고, 저자는 "strongly recommend[s] against classifying people on the basis of their continuous scores"라고 쓴다. 분류법 메타분석(317개 결과)도 "Findings supporting dimensional models outnumbered those supporting taxonic models five to one" (https://doi.org/10.1017/s003329172000183x)
   - Wikipedia 안정성: "Around 70–80% of people experience no significant changes in attachment styles over time." (https://en.wikipedia.org/wiki/Attachment_in_adults)
   - 맥락 의존성: 일기 연구에서 "30% to 40% of the between-person variation ... with a romantic partner and only 5% to 15% of that in interactions with family and friends" (Sibley et al. 2005). ECR-R은 연인관계에 특화된 도구라서 사제나 의형제 관계로 옮기면 타당도가 떨어질 수 있다.
3. **인기도**: en Attachment_in_adults 116,377, Attachment_theory 332,365 / ko "성인 애착" 2,257
4. **문항/라이선스**: Fraley 페이지는 "The scales were published in a scientific journal for use in the public domain."이라고 하면서도 "You may _not_ use the scales for commercial purposes without permission."이라고 명시한다. 자체 문항만 쓰면 도구 라이선스와는 무관하지만, 상업 앱이므로 원 문항 차용은 절대 피해야 한다.
5. **적합도 (2)**: 대중 인기는 높지만(연애 심리 콘텐츠), 친밀 관계는 민감한 영역이다. 개발자 본인이 유형 분류에 반대한다는 점이 "유형 결과" 콘셉트와 정면으로 충돌한다. 연인관계 특화라 무협 상황으로 옮기기도 어렵다. 쓴다면 "경향" 문구와 2차원 점수만 쓰고 불안정 애착을 결함으로 표현하지 않는다. **아키타입**: 의형제나 사형(사매). 신뢰와 거리두기를 묻는 인물이다.

## 9. Rotter 통제소재 (Locus of Control)

1. **구조**: 내적-외적의 단일 차원이다. 원척도는 "the 23-item (plus six filler items), forced-choice scale of Rotter (1966)" (https://en.wikipedia.org/wiki/Locus_of_control). 결과는 2~3단계다.
2. **과학적 근거**
   - 메타분석: "internal locus was positively associated with favorable work outcomes, such as positive task and social experiences, and greater job motivation" (https://doi.org/10.1002/job.416, Ng et al. 2006). 효과크기 수치는 초록에 없다.
   - 비판: "Rotter's assumption of uni-dimensionality has been challenged." (Wikipedia)
   - 문화차: 일본인은 미국인보다 "tend to be more external in locus-of-control orientation" (Wikipedia). 동아시아 사용자에게는 외적 통제 쪽 응답이 많을 수 있다.
   - Rotter 1966 원저는 피인용 28,666회다(OpenAlex 기준, 초록 없음).
   - 알파와 재검사 수치는 확인하지 못했다.
3. **인기도**: en 103,799 / ko "통제위치" 782
4. **문항/라이선스**: 확인하지 못했다. IPIP 다중구성개념 목록에는 없다.
5. **적합도 (4)**: "운명 vs 노력"이라는 무협의 단골 주제(천명, 기연)와 바로 연결되고 상황형 문항으로 만들기 쉽다. 단일 차원이라 결과의 다양성은 낮으니 다른 이론과 결합하는 보조 축에 적합하다. **아키타입**: 점술가나 관상가. 천명을 믿는지, 스스로 길을 여는지 보는 인물이다.

## 10. Snyder 자기감시 (Self-Monitoring)

1. **구조**: 고/저 자기감시의 단일 차원이다. 원척도는 "twenty five true or false statements"이다 (https://en.wikipedia.org/wiki/Self-monitoring). 18문항 개정판은 원문으로 확인하지 못했다. 결과는 2가지다.
2. **과학적 근거**
   - 메타분석: "136 samples; total N = 23,191 ... self-monitoring has relevance for understanding many organizational concerns, including job performance and leadership emergence" (https://doi.org/10.1037/0021-9010.87.2.390, Day et al. 2002)
   - 논쟁: "the Self-Monitoring Scale, are surrounded by controversy generated by conflicting answers to the critical question, Is self-monitoring a unitary phenomenon?" (https://doi.org/10.1037/0033-2909.126.4.530, Gangestad & Snyder 2000). Wikipedia는 요인분석에서 "the structure of most items on the Self-Monitoring Scale was multifactorial"(Acting, Extraversion, Other-Directedness)라고 쓴다.
   - 부작용: "self-monitoring has potential downsides" (https://doi.org/10.1002/job.2346)
   - 알파 수치는 확인하지 못했다.
3. **인기도**: en 15,399 / ko "자기감시" 583
4. **문항/라이선스**: 확인하지 못했다.
5. **적합도 (4)**: "좌중에 따라 얼굴을 바꾸는가, 한결같은가"는 상황형 선택지로 만들기 쉽고 양 극단 모두 긍정 프레이밍이 가능하다(처세술 vs 일관성). 대중 인지도는 낮다. **아키타입**: 변장술의 대가이자 첩보 조직 수장, 또는 기루 주인.

## 11. Duckworth 그릿 (Grit)

1. **구조**: 2 facet(노력의 지속성, 관심의 일관성)이다. 척도는 "the Short Grit Scale (Grit–S) and 12-item self-report measure of grit (Grit–O)" (https://en.wikipedia.org/wiki/Grit_(personality_trait)). 고/저로 나누면 4가지다.
2. **과학적 근거**
   - 원저: "grit accounted for an average of 4% of the variance in success outcomes ... Grit did not relate positively to IQ but was highly correlated with Big Five Conscientiousness" (https://doi.org/10.1037/0022-3514.92.6.1087, Duckworth et al. 2007)
   - 메타분석: "584 effect sizes from 88 independent samples representing 66,807 individuals indicate that the higher order structure of grit is not confirmed, that grit is only moderately correlated with performance and retention, and that grit is very strongly correlated with conscientiousness ... the primary utility of the grit construct may lie in the perseverance facet." (https://doi.org/10.1037/pspp0000102, Credé et al. 2017)
   - Wikipedia: 성실성과 "r = 0.77 ... r = 0.73"의 상관이 있고 유전상관은 0.86이다.
   - Grit-S 초록은 내적일관성과 재검사 안정성의 근거를 "present"한다고만 하고 수치는 없다 (https://doi.org/10.1080/00223890802634290).
3. **인기도**: en 64,975 / ko "그릿" 4,550. ko 조회수는 그룹 내 2위로, 한국에서는 번역서 영향이 있을 것으로 추정한다(확인 안 함).
4. **문항/라이선스**: [S] 비영리 연구와 교육용은 무료이고 상업적 사용, 출판, 광범위한 공개 배포는 금지다. 원문은 robots 차단으로 미확인이다. 자체 문항만 쓰면 무관하다. "Grit"은 일반 영어 단어라 내부 이론명으로 쓰는 데 문제가 없을 것으로 보이지만 확인하지는 않았다.
5. **적합도 (3)**: 다회 만남 누적 구조(수련, 포기 유혹)와 서사적으로 가장 잘 맞는다. 하지만 성실성과의 중복이 커서 독립 이론으로서의 변별력이 낮다. Big Five 성실성의 가중치 변형(폴백 방식)으로 구현하는 편이 근거에 맞다. "노력 지속" facet만 쓸 것을 권한다. **아키타입**: 수련 사부 또는 대장장이 장인. 십 년 같은 담금질을 견디는지 보는 인물이다.

---

## 종합 관찰

- 인기도와 근거를 모두 충족하는 것은 Big Five(en 604K, 근거 강)뿐이다. Dark Triad(455K)와 애착(332K)은 인기가 높지만 윤리와 유형화 문제로 적합도가 낮다.
- 실제로 독립적인 캐릭터 축을 만들 수 있는 조합: Big Five(또는 HEXACO), RST(BIS/BAS), 감각추구(TAS/Dis), 통제소재, 자기감시. 서로 개념 중복이 상대적으로 적고, 모두 상황형 선택 하나에 태그 1~2개를 붙이기 쉽다.
- 그릿과 EPQ의 E/N은 Big Five와 겹치므로 폴백(같은 이론, 다른 가중치)으로 처리하는 것이 근거에 맞다.
- 측정 방식 주의: 선택지마다 서로 다른 특성 태그를 붙이는 강제선택 구조는 점수가 ipsative(상대적)가 되기 쉽다. 이 문헌은 이번 조사 범위 밖이라 미검증이다. 한 문항에 같은 차원의 고/저 선택지를 두는 설계가 해석상 더 안전하다.
