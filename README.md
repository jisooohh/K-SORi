# Gugak MIDI Pad

**The Sound of Korea, Finding Rest**

An iOS app that brings Korean traditional music (Gugak) to your fingertips through an intuitive MIDI pad interface

## 프로젝트 개요

Gugak MIDI Pad는 한국 전통 음악의 미학을 현대적인 인터페이스로 재해석한 iOS 앱입니다. 전통 기와(Giwa) 모양의 패드를 터치하여 국악 사운드를 연주하고, 자신만의 전통 음악을 창작할 수 있습니다.

### 디자인 컨셉

- **인트로 화면**: "여백(Yeobaek)의 미" - 한지 배경과 수묵화 느낌의 전통적이고 고요한 분위기
- **메인 화면**: "현대적 전통" - 밤 하늘을 배경으로 빛나는 기와 패드, 몰입감 있는 어두운 테마

## 기술 스택

- **SwiftUI**: 모던한 UI 구현
- **AVFoundation**: 오디오 재생 및 녹음
- **Core Haptics**: 촉각 피드백
- **AudioKit**: 고급 오디오 처리 (추후 통합 예정)

## 프로젝트 구조

```
KSORi.swiftpm/
├── DesignSystem.swift           # 디자인 시스템 (오방색, Giwa 모양, 스타일)
│
├── Models/
│   ├── Sound.swift              # 사운드 데이터 모델
│   ├── SoundPad.swift           # 5x5 사운드 패드 구성
│   └── RecordedMusic.swift      # 녹음된 음악 모델
│
├── Views/
│   ├── IntroView.swift          # 인트로 화면 (여백의 미, 한지 배경)
│   ├── MainView.swift           # 메인 화면 (Giwa MIDI 패드)
│   ├── SoundPadView.swift       # 레거시 사운드 패드 UI
│   ├── WaveVisualizationView.swift  # AI 파동 분석 (호흡 리듬)
│   └── MusicListView.swift      # 제작 음악 리스트
│
├── Services/
│   ├── AppState.swift           # 앱 전역 상태 관리
│   ├── AudioManager.swift       # 오디오 재생 관리
│   ├── HapticManager.swift      # 햅틱 피드백 관리
│   └── RecordingManager.swift   # 녹음 기능 관리
│
├── Utilities/
│   └── Constants.swift          # 레거시 상수 정의
│
├── MyApp.swift                  # 앱 진입점
├── ContentView.swift            # 루트 뷰
└── Package.swift                # Swift Package 설정
```

## 디자인 특징

### 화면 1: 인트로 뷰 (Intro View)

**컨셉**: "여백(Yeobaek)의 미" - 자연스럽고, 전통적이며, 고요한 분위기

**비주얼 스타일**:
- **배경**: 한지(Hanji) 텍스처와 수묵화 스타일의 은은한 산 이미지
- **타이포그래피**: 세리프 폰트(New York/명조체)와 깔끔한 Sans-Serif 조합
- **컬러**: 따뜻한 베이지(배경), 다크 차콜(텍스트), 차분한 빨강(테두리)

**레이아웃**:
- 헤더: "The Sound of Korea, Finding Rest" (중앙 정렬, 대형, 볼드)
- 섹션 1: 국악의 아름다움 - '한'과 '흥'의 설명
- 섹션 2: 국악 사운드 패드 기능 - 기와 모양 버튼 소개
- 구분선: 전통 매듭(매듭) 아이콘
- 시작 버튼: 전통 액자 스타일의 이중 테두리

### 화면 2: 메인 뷰 (Main View)

**컨셉**: "현대적 전통" - 몰입감 있는 밤 분위기

**비주얼 스타일**:
- **배경**: 어두운 차콜/네이비 톤의 기와 패턴
- **조명**: 어두운 밤을 배경으로 빛나는 요소들
- **색상**: 오방색(Obangsaek) - 청(남색), 적(벽돌색), 황(겨자색), 백(아이보리), 흑(차콜)

**컴포넌트**:

1. **상단 컨트롤 바** (Glassmorphism 스타일)
   - File 버튼 (회색)
   - Transport 컨트롤: Record(빨강 원), Stop(회색 사각), Play(초록 삼각)
   - 타이머 (모노스페이스 폰트, 화이트)

2. **AI 파동 분석 시각화**
   - 라벨: "AI Wave Analysis"
   - 비주얼: 호흡하는 듯한 리듬의 파동 애니메이션 (보라/파랑 그라디언트)
   - 컨테이너: Glassmorphism 스타일

3. **MIDI 패드 그리드** (5x5)
   - **버튼 모양**: 기와(Giwa) - 윗부분은 사각형, 아래는 둥글게 곡선
   - **버튼 텍스처**: 도자기/돌 텍스처, 3D 깊이감
   - **버튼 색상**: 오방색 랜덤 배치
   - **패턴**: 각 버튼에 전통 문양 (연꽃, 구름, 매듭, 도깨비)
   - **인터랙션**:
     - 활성 상태: 황금빛 글로우 효과
     - 애니메이션: 터치 시 살짝 축소

## 주요 기능

### 1. 전통 미학 기반 UI/UX
- 한지와 기와 등 한국 전통 요소 활용
- 오방색 컬러 시스템
- 전통 매듭과 문양 디자인

### 2. 5x5 Giwa MIDI Pad
- 25개의 기와 모양 사운드 패드
- 오방색 색상으로 구분된 버튼
- 터치 시 황금빛 글로우 효과
- 전통 문양 각인

### 3. AI 사운드웨이브 시각화 (실시간 오디오 분석)

Swift의 네이티브 기술만을 사용한 아름다운 실시간 오디오 시각화:

**기술 구현**:
- `AVAudioPlayer.isMeteringEnabled`: 실시간 오디오 레벨 측정
- `updateMeters()`: 60 FPS로 진폭 업데이트
- `averagePower` & `peakPower`: dB 값을 선형 진폭으로 변환
- `TimelineView(.animation)`: 부드러운 60fps 애니메이션
- `Canvas`: 고성능 커스텀 그래픽 렌더링

**시각화 레이어**:
1. **Circular Wave (원형 파동)**
   - 중앙에서 확장되는 동심원
   - 글로벌 진폭에 반응하는 크기 변화
   - 보라색 그라디언트 글로우 효과

2. **Frequency Bars (주파수 바)**
   - 8개의 주파수 밴드 시뮬레이션
   - 각 바의 높이가 진폭에 반응
   - 보라→파랑 그라디언트
   - 상단 글로우 효과

3. **Waveform (파형)**
   - 유기적으로 흐르는 사인파
   - 다층 레이어로 깊이감 표현
   - 실시간 진폭 변화 반영

4. **Particles (파티클)**
   - 20개의 움직이는 파티클
   - 진폭에 따른 크기 변화
   - 시간 기반 궤적 애니메이션

**특징**:
- 외부 라이브러리 없이 Swift 기본 기능만 사용
- 사운드 패드 버튼 터치 시 실시간 반응
- 녹음된 음악 재생 시에도 작동
- 보라/파랑 그라디언트로 전통과 현대 조화

### 4. Transport 컨트롤
- 녹음 (Record)
- 정지 (Stop)
- 재생 (Play)
- 실시간 타이머

### 5. 햅틱 피드백
- 카테고리별 맞춤 진동 패턴
- 터치 시 즉각적인 촉각 반응

### 6. 음악 관리
- 녹음된 음악 저장
- 리스트 관리 (재생/편집/삭제)

## 디자인 시스템 (DesignSystem.swift)

### 색상 팔레트

**인트로 뷰 (여백의 미)**:
- `hanjiBeige`: 따뜻한 베이지 (RGB: 242, 237, 224)
- `darkCharcoal`: 다크 차콜 (RGB: 51, 51, 51)
- `mutedRed`: 차분한 빨강 (RGB: 179, 77, 77)
- `inkGray`: 잉크 회색 (RGB: 102, 102, 102)

**메인 뷰 (현대적 전통)**:
- `darkNight`: 어두운 밤 (RGB: 26, 31, 38)
- `glassBackground`: 글라스모피즘 배경 (투명도 60%)

**오방색 (Obangsaek)**:
- `obangsaekBlue`: 청 - 남색 (RGB: 38, 64, 115)
- `obangsaekRed`: 적 - 벽돌색 (RGB: 166, 77, 64)
- `obangsaekYellow`: 황 - 겨자색 (RGB: 217, 179, 77)
- `obangsaekWhite`: 백 - 아이보리 (RGB: 242, 237, 224)
- `obangsaekBlack`: 흑 - 차콜 (RGB: 64, 64, 71)

**효과 색상**:
- `goldenGlow`: 황금빛 글로우 (RGB: 255, 217, 102)
- `waveGradientPurple`: 파동 보라 (RGB: 128, 77, 179)
- `waveGradientBlue`: 파동 파랑 (RGB: 77, 128, 204)

### 커스텀 모양 (Custom Shapes)

1. **GiwaShape**: 기와 모양 (윗부분 사각형, 아래 곡선)
2. **TraditionalFrameShape**: 전통 액자 모양 (이중 테두리)
3. **MaedeupIcon**: 전통 매듭 아이콘

### 버튼 스타일

1. **TraditionalButtonStyle**: 전통 액자 스타일 버튼
2. **GiwaButtonStyle**: 기와 모양 패드 버튼

### 모디파이어

- `.glassmorphism()`: 글라스모피즘 효과 적용

## 사운드 구성

각 사운드는 다음과 같이 정의됩니다:
- 이름 (name)
- 파일명 (fileName)
- 카테고리 (category)
- 지속 시간 (duration)
- 그리드 위치 (position: 0-24)

현재는 임시 시스템 사운드를 사용하며, 실제 국악 음원을 추가하면 자동으로 재생됩니다.

### 이미지 에셋 요구사항

프로젝트에 다음 이미지를 추가하면 더욱 향상된 비주얼을 얻을 수 있습니다:
- `btn_blue`: 청색 기와 텍스처
- `btn_red`: 적색 기와 텍스처
- `btn_yellow`: 황색 기와 텍스처
- `btn_white`: 백색 기와 텍스처
- `btn_black`: 흑색 기와 텍스처
- `bg_pattern`: 기와 패턴 배경

## 다음 단계

### 1. 음원 추가
국립국악원에서 제공하는 음원 파일을 다음과 같이 추가하세요:
- 파일 형식: MP3 또는 WAV
- 파일명: `rhythm_1.mp3`, `percussion_1.mp3` 등
- 위치: 프로젝트 루트 디렉토리

음원 파일을 추가하려면:
1. Xcode에서 프로젝트 열기
2. 파일 추가 (File > Add Files to "KSORi"...)
3. "Copy items if needed" 체크
4. "Add to targets: KSORi" 체크

### 2. AudioKit 통합 (선택사항)
고급 오디오 처리를 위해 AudioKit을 추가하려면:
1. Package.swift에 AudioKit 의존성 추가
2. AudioManager에서 AudioKit 사용

### 3. AI 파동 시각화 개선
현재는 기본 사인파 시각화를 사용합니다. AI를 활용한 고급 시각화를 추가할 수 있습니다:
- Core ML 모델 통합
- 실시간 오디오 분석
- 주파수 기반 시각화

### 4. 테스트
실제 기기에서 테스트:
- iPhone (멀티터치 지원)
- iPad (더 큰 화면에서 패드 경험)
- 햅틱 피드백 테스트
- 녹음/재생 테스트

## 실행 방법

1. **Xcode에서 열기**
   ```bash
   open "KSORi.swiftpm"
   ```

2. **Swift Playgrounds 앱에서 열기**
   - iPad/Mac의 Swift Playgrounds 앱
   - 파일 열기 > KSORi.swiftpm 선택

3. **시뮬레이터 또는 실제 기기에서 실행**
   - Xcode: Product > Run (⌘R)
   - Swift Playgrounds: 재생 버튼

## 권한 설정

앱 실행 시 다음 권한이 필요합니다:
- **마이크 접근**: 녹음 기능
- **오디오 세션**: 오디오 재생

## 라이센스

음원 출처: 국립국악원 (사용, 변형, 상업적 이용 가능)

## 제작 동기

평소 스트레스나 불안을 느낄 때, 손을 움직이고 즉각적인 반응을 얻는 행위가 감정을 정리하는 데 도움이 된다는 것을 느껴왔습니다. 이 앱은 전통 음악을 배우거나 이해해야 하는 대상으로 두지 않고, 누구나 버튼을 누르는 것만으로 국악 사운드를 자연스럽게 만들어볼 수 있는 경험을 제공합니다.

전통은 멀리 있는 것이 아니라, 우리의 손끝에서 시작될 수 있다는 것을 보여주고 싶었습니다.
