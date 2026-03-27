# CapeForge

macOS에서 사용자 커서 세트를 불러와 비교, 매핑하고 Mousecape 호환 `.cape` 파일로 내보내는 Swift 기반 도구입니다.

현재 기본 실행 경로는 Swift 메뉴바 앱입니다.

- 사용자가 선택한 폴더에서 `.ani` 또는 `.cur` 파일을 읽습니다.
- 폴더 안의 커서 파일을 역할별로 자동 매핑합니다.
- 기본 커서와 적용 커서를 설정창에서 비교할 수 있습니다.
- 역할별로 커서 파일을 수동 재지정할 수 있습니다.
- `ani` 내부의 PNG 프레임과 핫스팟을 직접 파싱합니다.
- Mousecape가 읽을 수 있는 `.cape` 파일로 내보낼 수 있습니다.
- 패키징된 `.app`에서 로그인 시 실행용 LaunchAgent를 켜고 끌 수 있습니다.

한계:

- 오버레이 기반 미리보기/실험 기능은 남아 있지만, 시스템 전체 커서 교체 품질은 보장하지 않습니다.
- 실제 시스템 커서 교체는 현재 앱 내부가 아니라 Mousecape 같은 별도 적용기와 함께 쓰는 방향이 더 안정적입니다.
- 로그인 시 실행은 패키징된 `.app`에서만 지원합니다.

## 실행

```bash
./run_mac_mouse_cursor.command
```

## 패키징

```bash
./package_mac_mouse_cursor.command
open "./dist/CapeForge.app"
```

## 참고

현재 기준 실행 경로와 배포 경로는 모두 Swift 앱입니다.
리포지토리에는 내부 진단용 `CursorDiagnostics` 타깃도 포함되어 있습니다.
