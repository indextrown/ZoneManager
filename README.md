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

### Android 에뮬레이터에서 실행

먼저 에뮬레이터를 켜고 연결된 디바이스를 확인합니다.

```bash
flutter devices
```

결과에서 Android 에뮬레이터 ID를 찾은 뒤 실행합니다.

```bash
flutter run -d emulator-5554 --dart-define-from-file=config/firebase.json
```

※ `emulator-5554`는 예시입니다. 실제 ID는 `flutter devices` 출력에서 확인하세요.

### 연결된 실제 기기에서 실행

먼저 기기를 연결한 뒤 Flutter가 인식하는지 확인합니다.

```bash
flutter devices
```

특정 기기를 지정해서 실행하려면:

```bash
flutter run -d <device-id>
flutter run -d <device-id> --dart-define-from-file=config/firebase.json
```

## Real device setup

### iPhone에서 실행

1. iPhone을 Mac에 연결합니다.
2. 필요하면 iPhone에서 이 Mac을 신뢰합니다.
3. Xcode에서 `ios/Runner.xcworkspace`를 엽니다.
4. `Runner` 타깃의 `Signing & Capabilities`에서 Apple 계정과 Team을 설정합니다.
5. Bundle Identifier가 충돌하면 고유한 값으로 바꿉니다.
6. 기기에서 개발자 모드와 앱 실행 허용을 완료합니다.
7. 아래 명령으로 실행합니다.

```bash
flutter run -d <iphone-device-id>
```

현재 확인된 무선 iOS 실기기 예시:

```bash
flutter run --release -d 00008130-00090C281A38001C --dart-define-from-file=config/firebase.json
```

이 프로젝트의 iOS Firebase 초기화는 다음 둘 중 하나를 사용합니다.

- `ios/Runner/GoogleService-Info.plist`
- `--dart-define-from-file=config/firebase.json`

### Android 실제 기기에서 실행

1. Android 기기에서 개발자 옵션과 USB 디버깅을 켭니다.
2. USB로 연결하고 권한 허용 팝업을 승인합니다.
3. `flutter devices`로 기기가 잡히는지 확인합니다.
4. 아래 명령으로 실행합니다.

```bash
flutter run -d <android-device-id> --dart-define-from-file=config/firebase.json
```

참고:

- Android는 보통 `google-services.json`을 함께 쓰는 구성이 많지만, 현재 프로젝트는 Dart define 기반 Firebase 설정도 지원합니다.
- 기기가 안 잡히면 `adb devices`와 `flutter doctor`를 같이 확인하는 것이 가장 빠릅니다.

## Build

### 공통 사전 점검

빌드 전에 아래 순서로 상태를 확인하는 것을 권장합니다.

```bash
flutter pub get
flutter analyze
flutter test
```

### Android APK 빌드

```bash
flutter build apk --dart-define-from-file=config/firebase.json
```

빌드 결과물:

- `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle(AAB) 빌드

Google Play 배포용은 보통 AAB를 사용합니다.

```bash
flutter build appbundle --dart-define-from-file=config/firebase.json
```

빌드 결과물:

- `build/app/outputs/bundle/release/app-release.aab`

### iOS Release 빌드

```bash
flutter build ios --release --dart-define-from-file=config/firebase.json
```

Xcode에서 아카이브까지 진행하려면:

1. `ios/Runner.xcworkspace`를 엽니다.
2. `Runner` 타깃의 Signing 설정을 확인합니다.
3. Xcode 메뉴에서 `Product -> Archive`를 실행합니다.

### iOS IPA 배포 준비

Flutter만으로 기본 iOS release build는 만들 수 있지만, 실제 App Store/TestFlight 업로드는 보통 Xcode Archive 단계까지 진행해야 합니다.

일반적인 흐름:

1. `flutter build ios --release`
2. Xcode에서 `Runner.xcworkspace` 열기
3. `Product -> Archive`
4. Organizer에서 `Distribute App`

### 현재 프로젝트의 Android 릴리즈 서명 상태

현재 [android/app/build.gradle.kts](/Users/kimdonghyeon/2025/개발/Flutter/zonemanager/android/app/build.gradle.kts:1) 에서는 release 빌드가 임시로 debug signing을 사용하고 있습니다.

즉 지금도 로컬 릴리즈 빌드는 가능하지만:

- Play Store 배포용으로는 부적절하고
- 실제 배포 전에는 별도의 release keystore 설정이 필요합니다

배포 전에는 `signingConfigs`를 release용으로 분리하는 것을 권장합니다.

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
