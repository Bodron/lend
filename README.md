# lend

## API, panou admin și site cu Docker

După configurarea `backend/.env` (inclusiv `MONGODB_URI` și un `JWT_SECRET` sigur), pornește serviciile din rădăcina proiectului:

```powershell
docker compose -f backend/docker-compose.yml up --build -d
```

API: `http://localhost:3000/api/health`. Panou admin: `http://localhost:3001`. Site: `http://localhost:3002`.
Site-ul rulează în mod de dezvoltare și preia automat modificările din folderul `site`.
MongoDB este extern și trebuie să fie accesibil prin `MONGODB_URI` din `backend/.env`.
Rolul `super_admin` se acordă o singură dată unui cont existent:

```powershell
docker compose -f backend/docker-compose.yml exec api node scripts/grant-super-admin.js admin@example.com
```

Înlocuiește adresa cu cea a contului administrat de tine. Detalii în [admin/README.md](admin/README.md).

A new Flutter project.

## Run

### macOS

Flutter must be on your PATH. This project requires Dart 3.12.2 or newer
within Dart 3.x (bundled with Flutter). Check your setup first:

```bash
flutter doctor -v
flutter pub get
```

For iOS, install Xcode, complete its first-launch setup, and install an iOS
simulator runtime. Follow the [Flutter iOS setup guide](https://docs.flutter.dev/platform-integration/ios/setup).
This project has a CocoaPods Podfile; if Flutter reports missing CocoaPods,
install it (with Homebrew installed: `brew install cocoapods`).

Start the simulator from Xcode > Open Developer Tool > Device Hub (Xcode 27)
or Simulator (older Xcode), then run:

```bash
cd /Users/bodronc/Flutter/lend
bash run_lend.sh
```

Choose `2` to use the existing dev API without starting a local backend.
Flutter will let you select a device if several are available. To target a
specific simulator or connected phone:

```bash
flutter devices
bash run_lend.sh -d <device-id>
```

The macOS runner reads `.env` as data and forwards Google sign-in and Maps
settings just like the Windows runner. Copy `.env.example` to `.env` if needed
(do not overwrite an existing `.env`), then add your Google configuration.
The iOS Maps key is also written to the ignored `ios/Flutter/MapsKeys.xcconfig`.

Option `1` requires a separately running local backend, which is not included
in this checkout. The default iOS simulator API is `http://localhost:3000/api`;
Android emulators use `http://10.0.2.2:3000/api`. A physical phone needs
`APP_BASE_URL_LOCAL` set to a reachable address, such as your Mac's LAN IP.
Running from a Mac does not require targeting the macOS desktop app; use an
iOS simulator for the mobile app.

### Windows

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
