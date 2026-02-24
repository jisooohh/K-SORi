# K-SORi · 소리

### *The Sound of Korea, in Your Hands*

> **💻 Swift Student Challenge 2025**
> Built with Swift Playgrounds · AVFoundation · SwiftUI

---

## 📖 About

**What problem is your app trying to solve, and what inspired you?**

국악(國樂)은 한국의 역사와 문화 속에서 형성된 고유한 음악입니다.
한(恨), 얼(魂), 흥(興)과 같은 깊은 정서를 담고 있는 청각 예술이지만,
여전히 접근성이 낮고 직접 만들어보거나 실험할 기회가 많지 않습니다.

최근 BLACKPINK, BTS 등 K-POP 아티스트들의 음악에서 국악적 요소가 활용되며
그 매력이 점차 알려지고 있지만, 실제로 전통 음색을 직접 경험하고 창작에 활용하기엔
여전히 높은 진입 장벽이 존재합니다.

**K-SORi**는 음악을 배우거나 전통 악기를 다루지 않아도,
누구나 버튼 하나로 전통 음색을 경험하고 자신만의 소리를 만들 수 있도록 설계된 앱입니다.
전통 음악이 *감상의 대상*에 머무는 것이 아니라,
*일상 속 창작 경험*으로 확장되기를 바라는 마음에서 시작되었습니다.

---

Gugak is a unique musical tradition shaped by Korea's history and culture —
a sonic art that carries deep emotions like Han (恨 · longing), Heung (興 · joy), and Eol (얼 · spirit).
Yet it remains largely inaccessible: hard to play, rarely encountered outside formal settings.

While K-POP artists like BTS and BLACKPINK have begun weaving traditional sounds into their music,
the barrier to *experiencing and creating* with those sounds firsthand remains high.

**K-SORi** was built to remove that barrier —
so anyone, regardless of musical background, can tap a pad and make something beautiful with Gugak.

---

## 👥 Who Would Benefit

**누가, 어떻게 이 앱을 활용할 수 있을까요?**

- 🎧 **글로벌 리스너** — 국악을 처음 접하는 사람들의 첫 번째 청각 경험
- 🎛️ **창작자 & 프로듀서** — 전통 사운드를 실험적으로 결합하는 루프 제작 도구
- 🌏 **문화 탐험가** — 한국 전통 문화에 자연스럽게 스며드는 입구
- 🎼 **음악 교육자** — 국악 악기(해금·장구·소리북·거문고·부채)를 소개하는 인터랙티브 도구

음악을 전공하지 않은 사람도 간단한 터치 조작만으로 국악의 음색과 리듬을 체험할 수 있으며,
프로듀서는 짧은 루프를 제작하거나 전통 사운드를 현대 음악에 융합하는 도구로 활용할 수 있습니다.

---

This app benefits:

- **Global music listeners** curious about Korean traditional sounds
- **Composers & producers** looking to blend traditional textures into contemporary music
- **Educators** wanting an interactive introduction to Gugak instruments
- **Anyone** who's ever wanted to just *make something* without needing theory or training

---

## ♿ Accessibility

**접근성은 어떻게 설계에 반영되었나요?**

이 앱은 음악 이론이나 전통 음악 지식이 없어도 사용할 수 있도록 설계되었습니다.

사운드 패드는 **카테고리(M · P · R · V · B)별로 역할이 구분**되어 있어,
어떤 버튼 조합을 눌러도 조화로운 소리가 나도록 구조적으로 설계되었습니다.
*실패하지 않는 창작 경험* — 이것이 K-SORi의 접근성 철학입니다.

또한 **인터랙티브 튜토리얼**이 첫 실행 시 단계별로 안내하여,
처음 사용자도 자연스럽게 앱의 흐름을 익힐 수 있습니다.

직관적인 터치 인터페이스와 시각적 피드백(글로우, 햅틱)을 통해
다양한 배경을 가진 사람들이 쉽게 참여할 수 있도록 했습니다.

---

The sound pad is **structurally designed so any combination of buttons sounds harmonious** —
no wrong notes, no music theory required.

An **interactive step-by-step tutorial** guides first-time users through the experience,
and the intuitive touch interface with visual glow feedback and haptic responses
makes the app accessible to anyone, regardless of musical background.

---

## 🌍 Future Possibilities

이 프로젝트는 향후 일반 사운드패드와 결합하여 **퓨전 음악 창작 도구**로 확장될 수 있습니다.
또한 한국에 그치지 않고, 각 나라의 전통 음악 음색을 담은 사운드패드로 발전시켜
전 세계의 덜 알려졌지만 아름답고 개성 있는 문화들이 더 널리 알려지고 활용되는 데 기여할 수 있습니다.

> *전통은 고정된 과거가 아니라, 현재의 창작 안에서 다시 살아날 수 있다고 믿습니다.*
> *Tradition is not a fixed past — it can live again within the creativity of the present.*

---

## ⚙️ Technologies

| Framework | Usage |
|-----------|-------|
| **SwiftUI** | UI & animations |
| **AVFoundation** · AVAudioEngine | High-precision audio playback & recording |
| **Core Haptics** | Category-aware haptic feedback |
| **mach_absolute_time** | Hardware-accurate bar-boundary quantization |

---

## 🎵 Sound Categories

| Label | Instrument (KR) | Instrument (EN) |
|-------|----------------|-----------------|
| **M** | 해금 | Haegeum (fiddle) |
| **P** | 소리북 | Soribuk (drum) |
| **R** | 장구 | Janggu (hourglass drum) |
| **V** | 부채 | Buchae (fan dance vocal) |
| **B** | 거문고 | Geomungo (zither) |

---

## 🎥 Preview

### Intro Screen

<img src="screenshots/intro.png" width="300"/>

*여백(餘白)의 미 — The beauty of empty space*

---

### Main Pad

<img src="screenshots/main.png" width="300"/>

*5×5 사운드 패드 — 악기 이미지로 구성된 그리드*

---

### Interactive Tutorial

<img src="screenshots/tutorial.png" width="300"/>

*P3 → P4 → M3 → V3 → B4 순서의 단계별 안내*

---

### Saved Recordings

<img src="screenshots/recordings.png" width="300"/>

*녹음 리스트 — 저장, 재생, 삭제*

---

## 📃 Sound Credits

음원 출처 · Sound Source: **국립국악원 (National Gugak Center)**
사용, 변형, 상업적 이용 가능 · Free to use, modify, and commercialize
