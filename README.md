# zonemanager

주차 구역과 점유 상태를 실시간으로 관리하는 Flutter 앱입니다.  
Firebase Realtime Database를 데이터 소스로 사용하고, 현재 구조는 MVP 단계에 맞춰 `MVVM + Repository` 패턴으로 정리되어 있습니다.

## Architecture

이 프로젝트는 UseCase 계층 없이 아래 흐름으로 동작합니다.

`View -> ViewModel -> Repository -> Service -> Firebase`

### Layer roles

- `screens`
  화면 렌더링과 사용자 입력 처리만 담당합니다.
- `viewmodels`
  화면 상태, 로딩 상태, 에러 상태, 사용자 액션을 관리합니다.
- `repositories`
  ViewModel이 의존하는 데이터 접근 인터페이스입니다.
- `services`
  Firebase, 로컬 디바이스 정보, SharedPreferences 같은 외부 구현 세부사항을 다룹니다.
- `models`
  도메인 모델과 직렬화 로직을 가집니다.

## Project structure

```text
lib/
  main.dart
  firebase_options.dart
  models/
  repositories/
  screens/
  services/
  viewmodels/
```

## Main features

- 방 생성 / 목록 조회
- 방 참여
- 주차 구역 추가 / 삭제
- 주차 점유 수 증가 / 감소
- 다크 모드 저장
- Firebase 실시간 동기화

## Setup

### 1. Install packages

```bash
flutter pub get
```

### 2. Firebase config

Firebase 설정은 코드에 하드코딩하지 않고 외부 설정으로 분리했습니다.

- 실제 실행 파일: `config/firebase.json`
- 공유용 예시 파일: `config/firebase.example.json`

필요하면 예시 파일을 복사해서 실제 파일을 만드세요.

```bash
cp config/firebase.example.json config/firebase.json
```

### 3. iOS config

iOS는 두 방식 중 하나로 초기화됩니다.

- `--dart-define-from-file=config/firebase.json` 값이 있으면 그 값을 사용
- 값이 없으면 `ios/Runner/GoogleService-Info.plist`를 사용

## Run

### 기본 실행

```bash
flutter run
```

### 외부 Firebase 설정 파일로 실행

```bash
flutter run --dart-define-from-file=config/firebase.json
```

### Makefile 사용

```bash
make analyze
make test
make run
make check-run
```

`make check-run`은 아래 순서로 실행됩니다.

1. `flutter analyze`
2. `flutter test`
3. `flutter run`

## Design decisions

- MVP 단계라서 UseCase 계층은 아직 넣지 않았습니다.
- 대신 ViewModel이 화면 상태와 액션을 모으고, Repository가 데이터 접근 경계를 담당합니다.
- Firebase 관련 세부 구현은 Service 레이어에 남겨 두어 이후 교체나 테스트 대역 주입이 쉬운 구조로 맞췄습니다.

## Future improvements

- 인증 계층 추가
- Repository 테스트와 ViewModel 단위 테스트 추가
- Room / ParkingZone 기능별 모듈 분리
- Firebase rules와 앱 권한 모델 정교화
