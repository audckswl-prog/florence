# 앱 배포 작업 진행 현황 (2026-04-04)

현재 Android 앱 배포를 위한 빌드 작업을 진행하다가 중단되었습니다. 작업 내용은 다음과 같습니다.

## 1. 완료된 작업
- **keystore 확인**: `android/app/upload-keystore.jks` 파일 존재 확인 및 alias(`upload`) 확인 완료.
- **서명 설정 파일 생성**: `android/key.properties` 파일에 비밀번호 및 경로 설정 완료.
- **빌드 설정 업데이트**: `android/app/build.gradle.kts` 파일을 수정하여 릴리스 빌드 시 자동으로 서명되도록 설정하고, namespace를 `com.audckswl.firenze`로 수정함.
- **매니페스트 수정**: `AndroidManifest.xml`에서 중복된 `</queries>` 태그 제거.

## 2. 현재 상태 및 문제점
- **빌드 성공**: 기존에 발생했던 R8 에러(`google_mlkit` 등 일부 클래스 누락 문제)를 `android/app/proguard-rules.pro` 파일에 예외 규칙을 추가하여 해결했습니다.
- `flutter build appbundle --release` 빌드가 정상적으로 완료되었으며, `build/app/outputs/bundle/release/app-release.aab` 파일이 생성되었습니다 (약 70.2MB).

## 3. 남은 작업
- 구글 플레이 콘솔(Google Play Console)에 App Bundle(aab) 업로드 및 내부 테스트/출시 진행.
- iOS 배포를 위한 설정 및 `flutter build ipa` 진행 (필요 시).
