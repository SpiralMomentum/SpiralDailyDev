# SpiralDailyDev

Fltter 기반의 Mono Repo 베이스, Clean Architecture 룰을 따르는 프로젝트입니다.

# Structure

![Flutter_MonoRepo_CleanArchitecture (1)](https://user-images.githubusercontent.com/50985133/217288717-f01c7bef-c035-43e6-9470-47a26572d4a4.svg)

app 목록
- Daily Memo App
- Delivery Map App

package 목록
- core_app_shell: GoRouter 기반 애플리케이션 런타임 구성 도우미
- core_di: 공용 GetIt 서비스 로케이터 래퍼
- core_navigation: GoRouter 라우팅을 공통 추상화한 패키지
- ui_components
- utils
