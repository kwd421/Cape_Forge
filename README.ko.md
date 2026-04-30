# Cape Forge

[English README](README.md)

Cape Forge는 Windows 커서 파일과 커서팩(`.cur`, `.ani`)을 Mousecape 호환 `.cape` 파일로 변환하는 macOS 앱입니다.

![Cape Forge 미리보기](docs/assets/capeforge-preview.png)

위 이미지는 Cape Forge에 커서팩을 불러온 적용 예시입니다. 예시에 사용된 멋진 픽셀 마우스 커서를 만들어준 **blz**에게 감사드립니다. 출처: [BLZ_pixel on X](https://x.com/BLZ_pixel/status/1873630058981835066)

## 중요한 Mousecape 안내

Cape Forge는 `.cape` 파일을 만듭니다. 이 커서 테마를 실제 macOS에 적용하려면 Mousecape 또는 `.cape` 파일을 적용할 수 있는 앱이 필요합니다.

**macOS Tahoe 이후 버전**에서는 기존 Mousecape 앱으로 커서 테마가 정상 작동하지 않을 수 있습니다. Tahoe 이상 사용자는 아래 Tahoe 대응 Mousecape 빌드를 사용해야 합니다.

[Mousecape-TahoeSupport releases](https://github.com/AdamWawrzynkowskiGF/Mousecape-TahoeSupport/releases)

Tahoe 이전 macOS에서는 기존 [Mousecape](https://github.com/alexzielenski/Mousecape)로도 충분할 수 있습니다.

## 주요 기능

- 폴더 안의 `.cur`, `.ani` 커서 파일 불러오기
- 일반적인 커서 역할 자동 매핑
- 내보내기 전에 애니메이션 커서를 포함한 각 커서 미리보기
- 개별 커서 역할 수동 교체
- 내보낼 커서 크기 조절
- 커서 폴더와 개별 커서 파일 드래그 앤 드롭 지원
- 추가 Mousecape 커서 슬롯은 직접 지정하지 않으면 macOS 기본 커서 유지
- 긴 애니메이션 커서를 Mousecape 호환성이 더 좋도록 다운샘플링
- Mousecape에서 사용할 수 있는 `.cape` 파일 내보내기

## 사용 방법

1. Cape Forge를 엽니다.
2. `폴더 선택...`을 눌러 `.cur` 또는 `.ani` 파일이 들어 있는 폴더를 선택합니다.
3. 왼쪽 목록에서 자동 매핑된 커서 역할을 확인합니다.
4. 필요하면 역할을 선택한 뒤 `커서 파일 변경...`으로 직접 교체합니다.
5. 제작자명을 입력합니다.
6. 필요하면 내보내기 크기를 조정합니다.
7. `.cape 파일로 내보내기...`를 누릅니다.
8. 내보낸 `.cape` 파일을 Mousecape에서 열고 적용합니다.

## 팁

- `Normal`, `Text`, `Link`, `Busy`, 크기 조절 커서처럼 흔한 이름을 가진 커서팩이 가장 잘 매핑됩니다.
- 추가 커서는 선택 사항입니다. 직접 지정하지 않으면 macOS 기본 커서가 그대로 사용됩니다.
- 애니메이션 `.ani` 커서는 미리보기에서 재생되므로 내보내기 전에 움직임을 확인할 수 있습니다.
- 커서 폴더를 앱에 끌어다 놓으면 바로 불러올 수 있습니다.
- 단일 `.cur` 또는 `.ani` 파일을 앱에 끌어다 놓으면 현재 선택한 커서 역할을 교체할 수 있습니다.
- 24프레임을 넘는 애니메이션 커서는 Mousecape 적용 문제를 피하기 위해 균형 잡힌 24프레임 버전으로 내보냅니다.

## 요구 사항

- macOS Sequoia 15.6 이상
- 내보낸 `.cape` 파일을 시스템 커서 테마로 적용하려면 Mousecape 필요
- macOS Tahoe 이상에서는 위에 링크한 Tahoe 대응 Mousecape 빌드 필요
