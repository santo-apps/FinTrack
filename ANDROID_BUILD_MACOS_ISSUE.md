# Android Build on macOS - Known Issue

## Problem

Building this Android app on macOS currently fails due to a known bug in the macOS JDK's `jlink` tool when processing Android SDK 34/35 module transformations. This affects multiple Flutter plugins:
- `flutter_plugin_android_lifecycle`
- `image_picker_android`
- `local_auth_android`
- `path_provider_android`
- `flutter_local_notifications`

The error manifests as:
```
Execution failed for task ':PLUGIN:compileDebugJavaWithJavac'.
> Could not resolve all files for configuration 'androidJdkImage'.
  > Failed to transform core-for-system-modules.jar
    > Error while executing process /Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/jlink
```

## Solution: Build on Linux

### Option 1: Linux Machine
```bash
# On any Linux machine with Flutter SDK:
flutter build apk --release
# Or for debug:
flutter build apk --debug
```

### Option 2: GitHub Actions CI/CD

Create `.github/workflows/android-build.yml`:

```yaml
name: Build Android APK

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - uses: actions/setup-java@v3
      with:
        distribution: 'zulu'
        java-version: '17'
    
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.x'
        channel: 'stable'
    
    - name: Install dependencies
      run: flutter pub get
    
    - name: Build APK
      run: flutter build apk --release
    
    - name: Upload APK
      uses: actions/upload-artifact@v3
      with:
        name: app-release
        path: build/app/outputs/flutter-apk/app-release.apk
```

### Option 3: Docker Container

```bash
# Use Flutter Docker image (Linux-based)
docker run --rm -v "$PWD:/app" -w /app cirrusci/flutter:stable flutter build apk --release
```

## Current Configuration

**Temporary Changes for macOS Build Testing:**
- ❌ `flutter_local_notifications` - Disabled (stubbed in `notification_service.dart`)
- ❌ `image_picker` - Disabled
- ❌ `local_auth` - Biometric auth disabled (stubbed in `security_service.dart`)
- ✅ All other features working

**To Re-enable Full Functionality:**

1. Uncomment in [pubspec.yaml](../pubspec.yaml#L22-L34):
   ```yaml
   flutter_local_notifications: 14.1.5
   image_picker: ^0.8.8
   local_auth: ^2.3.0
   ```

2. Restore [lib/services/notification_service.dart](../lib/services/notification_service.dart)

3. Restore [lib/services/security_service.dart](../lib/services/security_service.dart) BiometricService

4. Remove dependency override:
   ```yaml
   dependency_overrides:
     flutter_plugin_android_lifecycle: 2.0.22  # Remove this line
   ```

## iOS Build

iOS builds work perfectly on macOS:
```bash
flutter build ios
# Successfully builds 34.6MB app
```

## References
- [Flutter Issue #135486](https://github.com/flutter/flutter/issues/135486)
- [Android Gradle Plugin JDK Issue](https://issuetracker.google.com/issues/332154908)
