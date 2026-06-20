# 생활 플래너 앱 — Claude Code 작업 목록 (tasks.md)

> `planner-app-spec.md`(기능 정의), `techspec.md`(아키텍처 결정) 기반의 구현 작업 목록.
> 순서: Phase 0(셋업) → Phase 1(데이터 레이어) → Phase 2(핵심 로직) → Phase 3(기능별 UI) → Phase 4(알림 연동) → Phase 5(보류, 네이티브)
> 각 작업은 완료 판단 기준(verify)을 함께 표기.

---

## Phase 0. 프로젝트 셋업

- [x] Flutter 프로젝트 생성 (안드로이드+iOS 타겟) — verify: `flutter run` 정상 실행
- [x] 패키지 설치: `flutter_riverpod`, `drift`, `sqlite3_flutter_libs`, `flutter_local_notifications`, `flutter_colorpicker`, `intl` — verify: `flutter pub get` 성공
- [x] 기본 폴더 구조 설정 (data / domain / presentation 등) — verify: 빈 폴더 구조 커밋
- [x] Drift DB 연결 골격 작성 (빈 데이터베이스 클래스) — verify: 앱 실행 시 DB 파일 생성 확인

---

## Phase 1. 데이터 레이어 (Drift 스키마)

`techspec.md` 5번(데이터 모델 설계 원칙) 기준.

- [ ] `Blocks` 테이블 정의 (타임블록, 1단계 자기참조) — verify: CRUD 단위 테스트 통과
- [ ] `ChecklistItems` 테이블 정의 (무제한 자기참조 + 블록 연결) — verify: 3단계 중첩 생성/조회 테스트
- [ ] `Tags`, `BlockTags`(N:M) 테이블 정의 — verify: 태그 추가/조회 테스트
- [ ] `TimerSessions` 테이블 정의 — verify: 세션 시작/종료 기록 테스트
- [ ] `RecurrenceRules` 테이블 정의 — verify: 규칙 생성 테스트
- [ ] `Templates`, `TemplateBlocks` 테이블 정의 — verify: 템플릿 저장/조회 테스트
- [ ] `DeadlineTasks` 테이블 정의 — verify: 마감일 기준 정렬 쿼리 테스트
- [ ] `MoodLogs` 테이블 정의 — verify: 날짜별 단일 레코드 제약 테스트
- [ ] DB 마이그레이션/버전 관리 설정 — verify: 스키마 변경 시 마이그레이션 통과

---

## Phase 2. 핵심 로직

- [ ] 타이머 상태머신 구현 (실행중 / 자동일시정지 / 수동정지 3상태) — verify: 상태 전이 단위 테스트, 특히 "수동정지 중 포그라운드 전환은 무반응" 케이스
- [ ] `AppLifecycleState` 연동 (resumed/paused → 자동 정지/재시작 트리거) — verify: 백그라운드 전환 시뮬레이션 테스트
- [ ] 방치 알림 트리거 로직 (수동정지 N분 경과 시 알림) — verify: 타이머 기반 알림 발송 테스트
- [ ] 반복 인스턴스 생성 로직 (`RecurrenceRule` → 실제 `Block` row 생성, 향후 N일치) — verify: 매주 반복 규칙으로 4주치 인스턴스 생성 테스트
- [ ] 타임블록 중첩 깊이 검증 로직 (1단계 초과 방지) — verify: 2단계 중첩 시도 시 거부 테스트
- [ ] 시간 겹침 검사 로직 — verify: 겹치는 두 블록 생성 시 경고 반환 테스트
- [ ] 목표 대비 실제 시간 비율 계산 로직 (블록 시간 vs `TimerSessions` 합계) — verify: 샘플 데이터 비율 계산 테스트
- [ ] 체크리스트 달성률 계산 로직 (오늘 기준) — verify: 샘플 데이터 비율 계산 테스트
- [ ] 잔디(출석) 데이터 계산 로직 (날짜별 완료 데이터 집계) — verify: 특정 날짜 집계 결과 테스트
- [ ] 마감 작업 상태 계산 로직 (진행중 / 마감지남) — verify: 마감일 경과 케이스 테스트

---

## Phase 3. 기능별 UI

- [ ] 계획표 캘린더 뷰 (일/주/달/년 전환, 블록 배치) — verify: 각 기간 단위 전환 동작 확인
- [ ] 블록 드래그 앤 드롭 배치 — verify: 드래그로 시간대 변경 동작 확인
- [ ] 블록 시각적 크기 비례 렌더링 (시간 길이 ↔ 크기) — verify: 1시간/2시간 블록 크기 비교 확인
- [ ] 블록 겹침 경고 UI — verify: 겹치는 블록 생성 시 경고 표시 확인
- [ ] 블록 생성/편집 화면 (제목, 색상, 태그) — verify: 생성 후 캘린더 반영 확인
- [ ] 자식 블록(타임블록/체크리스트) 추가 UI — verify: 부모 블록에 자식 추가 후 표시 확인
- [ ] 습관 스태킹 UI (블록 체인 연결) — verify: 연결된 블록 순서 표시 확인
- [ ] 타이머 화면 (시작/정지 버튼, 상태 표시) — verify: 3상태 전환이 UI에 반영되는지 확인
- [ ] 뽀모도로 모드 설정 화면 (온/오프, 시간 설정) — verify: 설정값 저장/적용 확인
- [ ] 출석 잔디 뷰 (달력형 그리드, 클릭 시 상세) — verify: 잔디 클릭 시 해당일 활동 표시 확인
- [ ] 목표/통계 대시보드 (달성률 시각화) — verify: 퍼센트 그래프 렌더링 확인
- [ ] "아직 끝내지 못한 일" 섹션 UI — verify: 미완료 항목 목록 표시, 완료/삭제 동작 확인
- [ ] 반복 설정 UI — verify: 반복 규칙 생성 후 캘린더 반영 확인
- [ ] 템플릿 저장/불러오기 UI (하루/주 단위) — verify: 템플릿 적용 시 블록 일괄 생성 확인
- [ ] 회고 메모 입력 UI (블록 단위) — verify: 메모 저장/조회 확인
- [ ] 오늘의 기분 이모지 선택 UI — verify: 날짜별 1개 저장 확인
- [ ] 마감 작업(데드라인 태스크) 생성/관리 화면 — verify: 생성, 캘린더 마커 표시, 완료/삭제 확인
- [ ] 마감 작업 → 타임블록 전환 기능 — verify: 전환 후 데이터 일관성 확인

---

## Phase 4. 알림 연동

- [ ] 로컬 알림 권한 요청 플로우 — verify: 권한 요청 다이얼로그 표시 확인
- [ ] 뽀모도로 알림 연동 — verify: 설정 시간 도달 시 알림 발송 확인
- [ ] 방치 알림 연동 — verify: 수동정지 N분 후 알림 발송 확인

---

## Phase 5. 보류 (2차, 네이티브 의존) ⏸

- [ ] 홈 화면 위젯 (안드로이드 `AppWidgetProvider` + iOS `WidgetKit`) — verify: 위젯에 현재 활동 표시 확인
- [ ] 잠금화면 타이머 (안드로이드 포그라운드 서비스 알림 / iOS Live Activity) — verify: 잠금화면에서 정지/완료 버튼 동작 확인
- [ ] 가로모드 상시 디스플레이 모드 — verify: 화면 유지 중에도 타이머 정상 동작 확인
