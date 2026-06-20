# CLAUDE.md

이 프로젝트(생활 플래너 앱)에서 작업할 때 아래 규칙을 따를 것.

## 참고 문서

- `planner-app-spec.md` — 기능 정의
- `techspec.md` — 기술 스택/아키텍처 결정
- `tasks.md` — 실행할 작업 목록 (Phase 단위)

## Git / GitHub 규칙

- 각 작업(Phase 단위) 완료 후 변경사항을 자동으로 커밋하고 push할 것
- 커밋 메시지는 **Conventional Commits** 형식 사용: `접두사: 설명`
  - `feat:` 새 기능 추가
  - `fix:` 버그 수정
  - `refactor:` 동작은 그대로, 코드 구조만 변경
  - `docs:` 문서 수정 (md 파일 등)
  - `style:` 포맷팅 등 동작에 영향 없는 변경
  - `test:` 테스트 코드 추가/수정
  - `chore:` 패키지 설치, 설정 파일 등 잡일
- 설명 부분은 한국어로 간결하게 작성 (예: `feat: 타이머 3상태 상태머신 구현`)
