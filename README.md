<div align="center">

# 🦆 DuckHunter (FPGA Optical Shooting Game)

<img src="https://img.shields.io/badge/Language-SystemVerilog-green?style=for-the-badge&logo=verilog" />
<img src="https://img.shields.io/badge/Hardware-FPGA-orange?style=for-the-badge" />
<img src="https://img.shields.io/badge/Sensor-OV7670-blue?style=for-the-badge" />
<img src="https://img.shields.io/badge/Display-VGA-red?style=for-the-badge" />

<br/>

<p align="center">
  <strong>FPGA와 OV7670 카메라를 활용한 인터랙티브 슈팅 게임</strong><br>
  카메라가 조준점(Crosshair) 역할을 하여 붉은색 레이저나 물체를 감지해 오리를 사냥하는 게임입니다.
</p>

</div>

<br/>

## 📖 프로젝트 개요 (Overview)

**DuckHunter**는 고전 게임 'Duck Hunt'를 FPGA 상에서 하드웨어 로직으로 재구현한 프로젝트입니다.
[cite_start]기존의 라이트 건 대신 **OV7670 카메라 모듈**을 컨트롤러로 사용하여, 화면 중앙에 위치한 **붉은색 물체를 인식**하는 영상 처리 기법을 적용했습니다[cite: 10, 210].

게임 로직, 그래픽 출력(VGA), 사운드 제어, 카메라 인터페이스(SCCB) 등 모든 시스템이 SystemVerilog RTL로 설계되었습니다.

---

## 🎮 주요 기능 (Key Features)

### [cite_start]1. 카메라 기반 조준 (Optical Aiming) [cite: 10, 11]
- **적색 검출(Red Detection):** 카메라 영상의 중앙 영역(Crosshair)에서 RGB 값을 분석하여 붉은색 픽셀을 검출합니다.
- [cite_start]**임계값(Threshold):** `R >= 12`, `G <= 18`, `B <= 15` 조건을 만족하는 픽셀이 일정 개수(80개) 이상일 때 조준으로 판정합니다[cite: 11, 16].

### [cite_start]2. 게임 시스템 (Game Mechanics) [cite: 210, 220, 223]
- [cite_start]**총알 시스템:** 최대 **50발**의 총알이 제공되며, 사격 시마다 UI에 아이콘과 숫자가 업데이트됩니다[cite: 221, 393].
- [cite_start]**타임 어택:** 제한 시간 **60초** 동안 최대한 많은 점수를 획득해야 합니다[cite: 219].
- [cite_start]**Night Mode:** 남은 시간이 30초 미만이 되면 배경이 어두워지며 긴장감을 조성합니다[cite: 296, 590].
- [cite_start]**랜덤 스폰:** 오리는 무작위 위치와 속도로 등장하여 비행합니다[cite: 754, 763].

### [cite_start]3. 디스플레이 (VGA Display) 
- **레이어 합성:** 배경, 오리 스프라이트, 카메라 영상(PIP), 텍스트(HUD)를 실시간으로 합성하여 출력합니다.
- [cite_start]**HUD:** 점수, 타이머, 남은 총알 수, 게임 상태(Start/Game Over)를 픽셀 폰트로 생성하여 표시합니다[cite: 298].

---

## 🕹 조작 방법 (Controls)

| 버튼 (FPGA) | 기능 | 설명 |
| :--- | :--- | :--- |
| **Btn U** | `Start / Resume` | [cite_start]게임 시작 또는 일시정지 해제 [cite: 210, 257] |
| **Btn D** | `Pause` | [cite_start]게임 일시정지 [cite: 211, 259] |
| **Btn R** | `Shoot` | [cite_start]사격 (총알 차감) [cite: 210, 261] |
| **Btn L** | `Exit` | [cite_start]초기 화면으로 리셋 [cite: 211, 247] |
| **Switch** | `Cam Overlay` | [cite_start]우측 하단 카메라 PIP 끄기/켜기 [cite: 210, 296] |

---

## 🛠 시스템 아키텍처 (System Architecture)

전체 시스템은 `DuckHunt_System`을 최상위 모듈로 하여 다음과 같이 구성됩니다.

```mermaid
graph TD
    User[User Inputs] --> Top[DuckHunt_System.sv]
    Camera[OV7670] <--> SCCB[SCCB_Controller.sv]
    SCCB --> Top
    
    Top --> RedDet[Red_Detector.sv]
    Top --> GameLogic[Duck_Controller.sv]
    Top --> Display[Game_Display_Controller.sv]
    Top --> TextGen[Text_Screen_Gen.sv]
    
    RedDet --> GameLogic
    GameLogic --> Display
    TextGen --> Display
    Display --> VGA[VGA Output]
