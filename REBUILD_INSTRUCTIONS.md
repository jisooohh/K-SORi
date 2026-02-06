# 🔧 사운드 파일 에러 해결 방법

## 문제
```
❌ 사운드 파일을 찾을 수 없음: rhythm_3
❌ 사운드 파일을 찾을 수 없음: voice_3
```

## 원인
Xcode가 오래된 빌드 캐시를 사용하고 있습니다.

## 해결 방법

### 1단계: Clean Build Folder
1. Xcode 메뉴에서: **Product > Clean Build Folder** (⇧⌘K)
2. 또는 단축키: **Shift + Command + K**

### 2단계: Derived Data 삭제 (더 강력한 방법)
1. Xcode 메뉴: **Window > Devices and Simulators**
2. 시뮬레이터 우클릭 > **Delete All Content and Settings**
3. 또는 터미널에서:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```

### 3단계: 프로젝트 재시작
1. Xcode 완전히 종료
2. 다시 열기:
   ```bash
   open "/Users/hongjisoo/Library/Mobile Documents/iCloud~com~apple~Playgrounds/Documents/KSORi.swiftpm"
   ```

### 4단계: 빌드 및 실행
1. **Product > Build** (⌘B)
2. **Product > Run** (⌘R)

## 확인 사항

콘솔에서 다음 메시지가 나와야 정상입니다:
```
✅ 사운드 파일 찾음: /path/to/Resources/sound0.wav
🎵 재생 시작: sound0 (Loop: ♾️)
```

## 현재 파일 구조

```
Resources/
├── sound0.wav
├── sound1.wav
├── sound2.wav
├── sound3.wav
├── sound4.wav
├── sound5.wav
├── sound6.wav
├── sound7.wav
├── sound8.wav
├── sound9.wav
├── sound10.wav
├── sound11.wav
├── sound14.wav
└── sound20.wav
```

## 5x5 그리드 매핑

```
Row 0: sound0, sound1, sound2, sound3, sound4
Row 1: sound5, sound6, sound7, sound8, sound9
Row 2: sound10, sound11, sound14, sound20, sound0
Row 3: sound1, sound2, sound3, sound4, sound5
Row 4: sound6, sound7, sound8, sound9, sound10
```
