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

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
