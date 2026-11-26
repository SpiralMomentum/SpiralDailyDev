# 폰트 출처와 라이선스

조회일: 2026-11-25. 모두 SIL Open Font License 1.1(OFL). OFL은 폰트를 수정하지 않고 앱에 번들해 재배포하는 것을 허용한다(폰트 단독 판매만 금지). 원본 파일을 수정하지 않고 그대로 번들한다. 각 라이선스 원문은 같은 폴더의 파일을 본다.

| family | 파일 | 출처 | 라이선스 원문 |
|---|---|---|---|
| Pretendard | Pretendard-Regular.otf, Pretendard-Bold.otf | https://github.com/orioncactus/pretendard/releases/download/v1.3.9/Pretendard-1.3.9.zip (public/static/) | OFL-Pretendard.txt (https://raw.githubusercontent.com/orioncactus/pretendard/main/LICENSE) |
| StoicSerif | NanumMyeongjo-Regular.ttf, NanumMyeongjo-Bold.ttf | https://raw.githubusercontent.com/google/fonts/main/ofl/nanummyeongjo/ | OFL-NanumMyeongjo.txt (같은 경로 OFL.txt) |
| WitRounded | Jua-Regular.ttf (Jua, 둥근 고딕) | https://raw.githubusercontent.com/google/fonts/main/ofl/jua/Jua-Regular.ttf | OFL-Jua.txt (같은 경로 OFL.txt) |

## 확인 사항
- 세 라이선스 파일 모두 원문에 "SIL OPEN FONT LICENSE Version 1.1"과 번들/재배포 허용 조항이 있음을 대조했다.
- Reserved Font Name(Pretendard, Nanum 계열)이 있으므로 파일을 수정하거나 개명 배포하지 않는다. pubspec의 family 이름은 앱 내부 참조명일 뿐 폰트 파일 이름은 그대로다.
- Jua는 Regular 한 굵기만 제공한다. 위트 말투의 제목/잔고 숫자는 Jua로 쓰고, 합성 굵기를 피하기 위해 FontWeight.w400만 쓴다.
- 합계 약 11.4MB(Pretendard 2 + Myeongjo 2 + Jua 1 굵기).
