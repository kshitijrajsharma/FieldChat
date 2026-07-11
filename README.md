# Hulaki

An offline-first, privacy-focused field mapping app. Flutter, shipping to Android and iOS.

A *hulaki* stands for a mail runner: the postman who carried message letters on foot across Nepal, over ground in past where there were no roads and signal.

## Architecture

- **Local source of truth**: a drift (SQLite) database on the device. Chat and
  map both render from it; the network only syncs into and out of it.
- **Backend**: Supabase for the relay (Postgres and Realtime), Storage for the
  media blobs, and anonymous auth. The server only ever holds ciphertext.
- **Encryption**: one static AES-256-GCM key per group, shared through the
  invite link and never sent to the server. Every envelope is also signed with
  the device's Ed25519 key and verified on ingest, so authorship cannot be
  spoofed. There is no forward secrecy and no key rotation.
- **Map**: MapLibre with the CARTO Positron basemap. An area can be saved for
  offline use.
- **Track**: a 24 hour local breadcrumb, purged as it ages.

## Languages

English, Spanish, French and Portuguese. A language is a file in `lib/l10n`, see [docs/TRANSLATING.md](docs/TRANSLATING.md).

## Requirements

- Flutter SDK 3.44.4 (stable) on `PATH`.
- Android builds: the Android SDK and a JDK.
- iOS builds and signing: macOS with Xcode.

## Tasks

The `justfile` is the entrypoint:

```
just setup          # install dependencies
just lint           # format check and static analysis
just test           # the test suite
just translations   # check every language against the template
just load           # load tests (slow, allocates hundreds of MB)
just icons          # regenerate launcher icons
just run            # run on a device or emulator
just build-android  # release APK
just build-ios      # release IPA (macOS only)
```

## Configuration

The app reads `SUPABASE_URL` and `SUPABASE_ANON_KEY` from `--dart-define`. With
both absent it falls back to an in-memory relay, so tests and keyless local runs
need no backend.

## Licence

AGPL-3.0.
