# lend

A new Flutter project.

## Run

On Windows, use the interactive runner:

```powershell
.\run_lend.ps1
```

Choose `1` for the existing local API configuration or `2` for the dev API at
`https://lend.bcmenu.ro/`.

The runner reads `.env` when present:

```env
APP_BASE_URL_DEV=https://lend.bcmenu.ro
APP_BASE_URL_LOCAL=
```

For Codemagic, set `APP_BASE_URL` or `APP_BASE_URL_DEV` in the workflow
environment. The value is passed to Flutter with `--dart-define=APP_BASE_URL`.

Extra Flutter arguments are forwarded, for example:

```powershell
.\run_lend.ps1 -d chrome
```

## App update dialog

The Android and iOS apps request `GET /api/app-version` from the existing
backend on launch and when they return to the foreground. Set these optional
values in `backend/.env` (or the backend's deployment environment):

| Parameter | Example | Purpose |
| --- | --- | --- |
| `APP_LATEST_VERSION_ANDROID` | `1.0.1` | Shows an optional update to older Android versions. |
| `APP_MINIMUM_VERSION_ANDROID` | `1.0.0` | Requires an update below this Android version. |
| `APP_UPDATE_URL_ANDROID` | `https://play.google.com/store/apps/details?id=com.lend.ro` | Android store destination. Defaults to this Play Store URL when empty. |
| `APP_LATEST_VERSION_IOS` | `1.0.1` | Shows an optional update to older iOS versions. |
| `APP_MINIMUM_VERSION_IOS` | `1.0.0` | Requires an update below this iOS version. |
| `APP_UPDATE_URL_IOS` | `https://apps.apple.com/app/idYOUR_APP_ID` | App Store destination; a TestFlight public invitation URL also works. Required for iOS prompts. |

Use a version already available at the linked destination before raising the
minimum version. Values may include a build number, such as `1.0.0+29`, when
you need to distinguish builds with the same release version. An empty or
invalid version disables its corresponding check. The dialog is skipped when
the backend is unavailable. Restart or redeploy the backend after changing the
environment values.

To preview the dialog without configuring the backend, run a debug build with
`--dart-define=APP_UPDATE_PREVIEW=true`, for example:

```powershell
flutter run -d chrome --dart-define=APP_UPDATE_PREVIEW=true
```

The preview shows version `1.0.1`; its Update button closes the dialog instead
of opening a store. The preview flag has no effect in release builds.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
