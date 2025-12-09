# Project_UART_FIFO_SENSOR_CLOCK
스톱워치, 초음파센서, 온습도센서

### FPGA & Verilog HDL Based Multi-Function System
#### Verilog HDL을 사용하여 구현한 다기능 디지털 시계(Stopwatch, Watch, Timer) 및 환경 모니터링 시스템. FSM 설계를 통한 센서 제어(DHT11, HC-SR04)와 FIFO 기반의 UART 통신을 통합하여 하드웨어 제어 및 데이터 통신 프로젝트
<br>

## System Architecture
### Top Block Diagram
<img width="2231" height="1026" alt="image" src="https://github.com/user-attachments/assets/9db03958-1d57-483b-994c-6521cf6b6793" />
<br>

### Uart-Fifo Block Diagram
<img width="2102" height="1062" alt="image" src="https://github.com/user-attachments/assets/65ff1e82-1c84-455b-94ad-d8dea10fd099" />
<br>

### Vivado Schematic
<img width="2012" height="819" alt="스크린샷 2025-12-09 181842" src="https://github.com/user-attachments/assets/7fad499a-7c5a-418c-868e-896bc774c21b" />

시스템은 크게 **Time Keeping Unit(시계 동작)**, **Sensor Control Unit(환경 감지)**, **Communication Unit(데이터 전송)**, **Display Unit(시각화)**으로 구성되어 있으며, Top Module에서 각 모듈 간의 신호 간섭을 제어하고 데이터를 라우팅하는 구조.
<br>

## 특징
### 1. Custom 1-Wire Protocol (DHT11)
#### FSM (Finite State Machine) 기반 센서 제어
> 마이크로컨트롤러(MCU) 없이 FPGA의 순수 로직만으로 DHT11의 독자적인 통신 규격(1-Wire)을 구현.
> 타이밍이 매우 중요한 비동기 통신을 처리하기 위해 10us 단위의 Tick Generator와 정밀한 상태 머신(State Machine) 설계.
> Datasheet의 Timing Diagram을 분석하여 Start, Response, Data Read의 전 과정을 직접 설계함.
<br>

### 2. 동작 방식 (Key Operation Logic)

#### 클록 분주 (Clock Division) : 
시스템 클록(100MHz)을 용도에 맞게 분주하여 사용.
- **100Hz:** Stopwatch의 10ms 카운팅용.
- **1kHz:** FND의 Dynamic Multiplexing(잔상 효과) 제어용.
- **10us Tick:** DHT11 센서와의 정밀 통신 타이밍 계수용.

#### 통신 구조 (UART with FIFO) :
데이터 생성 속도(센서)와 전송 속도(UART 9600bps)의 차이를 극복하기 위해 버퍼링 구조 도입.
- **Circular FIFO:** 송수신 데이터의 유실을 방지하고 시스템 안정성 확보.
- **ASCII 변환:** 2진수(Binary) 센서 데이터를 수신 측(PC)에서 즉시 가독 가능한 ASCII 코드로 실시간 변환하여 전송.

#### 제어 유닛 (DHT11 Control Unit)의 특징 :
##### State 1 - IDLE & START : 버튼 트리거 시, 라인을 18ms 이상 Low로 유지하여 센서에 Start Signal 전송.
##### State 2 - SYNC (Response Check) : 센서로부터 오는 80us Low -> 80us High 응답 신호를 감지하여 연결 확인.
##### State 3 - DATA_DETERMINE : 50us Low 구간 이후 들어오는 High 구간의 길이를 카운팅하여 데이터 판별. (26~28us: '0', 70us: '1')
##### State 4 - STOP & CHECKSUM : 40비트 데이터 수신 완료 후, Parity Check를 통해 데이터 무결성 검증.

#### 데이터패스 (Datapath - Stopwatch) :
##### - Tick Gen : 10ms 단위의 Enable 펄스 생성.
##### - Cascaded Counters : msec(100) -> sec(60) -> min(60) -> hour(24) 순으로 Carry를 넘겨주는 종속적 카운터 구조.
##### - Control Logic : Start/Stop/Reset 신호에 따른 카운터 값 유지 및 초기화, MUX를 통한 모드별 출력 데이터 스위칭.
<br>

### 3. 장단점
#### [장점]
##### 100% 하드웨어 로직으로 구현되어 MCU 대비 매우 빠른 응답 속도와 병렬 처리(Parallelism) 가능.
##### FIFO를 적용하여 UART 통신 시 데이터 오버런(Overrun) 방지 및 신뢰성 확보.
##### 모듈화(Modularity) 설계를 통해 각 기능(시계, 센서, 통신)의 독립적 디버깅 및 유지 보수 용이.
##### 파라미터(Parameter) 기반 설계로 클록 주파수나 Baud Rate 변경 시 유연한 대처 가능.

#### [단점] (및 해결 과정)
##### FSM 설계 시 타이밍 마진(Timing Margin) 계산이 까다로움 (Simulation을 통해 최적값 도출).
##### 버튼 입력 시 기계적 채터링(Chattering) 발생 -> Debounce 회로를 추가하여 해결.
##### 단일 FND로 여러 정보를 표시해야 하는 한계 -> 모드 스위칭 MUX와 LED 인디케이터를 활용하여 UI 개선.
