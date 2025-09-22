# Shader-Programming-Basics

This repository contains learning materials for shader programming.

이 커리큘럼은 현대 3D 그래픽스의 핵심인 셰이더 프로그래밍을 HLSL과 DirectX, Unity 엔진, Win32 등 다양한 환경에서 체계적으로 학습할 수 있도록 설계되었습니다. 
셰이더나 그래픽스가 처음이라면 unity 환경에서 예제를 따라하며 기본기를 익히는 것을 추천합니다. 

# 목차

<details>
<summary> Basics </summary>

* [HLSL/DirectX 셰이더 프로그래밍 커리큘럼](./Shader%20Learning/Basics/1.%20HLSLDirectX%20셰이더%20프로그래밍%20커리큘럼.md)
* [HLSL/DirectX 셰이더 프로그래밍 학습자료 (Part 1)](./Shader%20Learning/Basics/2.%20HLSLDirectX%20셰이더%20프로그래밍%20학습자료%20(Part%201).md)
* [HLSL/DirectX 셰이더 프로그래밍 학습자료 (Part 2)](./Shader%20Learning/Basics/3.%20HLSLDirectX%20셰이더%20프로그래밍%20학습자료%20(Part%202).md)
* [HLSL/DirectX 셰이더 프로그래밍 학습자료 (Part 3)](./Shader%20Learning/Basics/4.%20HLSLDirectX%20셰이더%20프로그래밍%20학습자료%20(Part%203).md)

</details>

---
<details>
<summary> Advanced </summary>

* [실사 렌더링을 위한 PBR 셰이더 가이드](./Shader%20Learning/Adbanced/5.%20실사%20렌더링을%20위한%20PBR%20셰이더%20가이드%20.md)
* [수많은 광원을 위한 Deferred Shading](./Shader%20Learning/Adbanced/6.%20수많은%20광원을%20위한%20Deferred%20Shading.md)
* [GPU 기반 동적 지형 렌더링 테셀레이션 파이프라인](./Shader%20Learning/Adbanced/7.%20GPU%20기반%20동적%20지형%20렌더링%20테셀레이션%20파이프라인.md)

</details>

---

<details>
<summary> DirectX 11</summary>

- [DirectX 11 학습 커리큘럼](./DirectX%2011%20학습%20커리큘럼.md)  
- 단계별 학습  
  - [DirectX 11 1단계](./Directx11/DirectX%2011%201단계.md)  
  - [DirectX 11 2단계 (중급)](./Directx11/DirectX%2011%202단계%20중급.md)  
  - [DirectX 11 3단계 (고급)](./Directx11/DirectX%2011%203단계%20고급.md)  

</details>

---

<details>
<summary> Unity Shader</summary>

- [유니티 셰이더 커리큘럼](./Unity%20shader/유니티%20셰이더%20커리큘럼.md)  
- [고급 셰이더 기술 심화 학습 로드맵](./Unity%20shader/고급%20셰이더%20기술%20심화%20학습%20로드맵.md)  
- 학습 자료  
  - [Part 1](./Unity%20shader/유니티%20셰이더%20Part%201%20학습%20자료이%20문서는%20'유니티%20셰이더.md)  
  - [Part 2](./Unity%20shader/유니티%20셰이더%20Part%202%20학습%20자료.md)  
  - [Part 3](./Unity%20shader/유니티%20셰이더%20Part%203%20학습%20자료.md)  
  - [Part 4](./Unity%20shader/유니티%20셰이더%20Part%204%20학습%20자료.md)  

</details>

---

<details>
<summary>🖥 Win32 / Win API</summary>

- [0. Win32 학습 커리큘럼](./Win32/0.%20Win32%20학습%20커리큘럼.md)  
- [1. Win API 학습 기초](./Win32/1.%20Win%20API%20학습%20기초.md)  
- [2. Win API 그래픽, 입력 처리](./Win32/2.%20Win%20API%20그래픽,%20입력%20처리.md)  
- [3. Win API 표준 컨트롤과 리소스 활용](./Win32/3.%20Win%20API%20학습%20표준%20컨트롤과%20리소스%20활용.md)  
- [4. Win API 고급 시스템 프로그래밍](./Win32/4.%20Win%20API%20고급%20시스템%20프로그래밍.md)  
- [Win API 예제 테스트 환경 활용 가이드](./Win32/Win%20API%20예제%20테스트%20환경%20활용%20가이드.md)  

예제 코드  
- [FileSearcher](./Win32/FileSearcher)  
- [HelloWorld](./Win32/HelloWorld)  
- [Notepad](./Win32/Notepad)  
- [Paint](./Win32/Paint)  

</details>

---

# 선수 지식
#### C++ 프로그래밍 기초

#### 3D 벡터 및 행렬에 대한 기본적인 이해 (선형대수학)

#### DirectX 또는 유사한 그래픽스 API 설정 및 기본 사용 경험 (권장)

---




## Part 1: 셰이더 프로그래밍 입문 (1~4챕터)
#### 1챕터: 그래픽스 파이프라인과 셰이더의 역할

#### 2챕터: 기본 조명 모델 (퐁 조명)


#### 3챕터: 텍스처 매핑 (Texture Mapping)


#### 4챕터: 미니 프로젝트 #1 - 조명과 텍스처를 가진 3D 모델 렌더링


---

## Part 2: 중급 셰이딩 기법 (5~9챕터)
#### 5챕터: 고급 조명 기법


#### 6챕터: 노멀 매핑 (Normal Mapping)


#### 7챕터: 그림자 매핑 (Shadow Mapping)


#### 8챕터: 반사 및 환경 매핑


#### 9챕터: 미니 프로젝트 #2 - 고급 셰이더 효과 통합


---

## Part 3: 고급 셰이더 및 최적화 (10~14챕터)
#### 10챕터: 후처리 효과 (Post-Processing)


#### 11챕터: 지오메트리 & 테셀레이션 셰이더

#### 12챕터: 컴퓨트 셰이더 (Compute Shader)


#### 13챕터: 셰이더 최적화


#### 14챕터: 최종 프로젝트 - 자신만의 셰이더 기술 데모 제작


---

#####  추천 자료 및 도구
* 개발 환경: Visual Studio

* 디버깅/프로파일링: PIX for Windows, RenderDoc

##### 참고 서적

* "Introduction to 3D Game Programming with DirectX 12" (Frank D. Luna)

* "Real-Time Rendering"

##### 온라인 자료

* ShaderToy: 다른 사람들의 셰이더 코드를 보고 배우기 좋은 사이트

* Catlike Coding: (Unity 기반, 원리 이해에 큰 도움이 됨)

* Microsoft DirectX Graphics-Samples
