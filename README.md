# Krar & Begena Studio

A microtonal instrument and tab tutor for the Ethiopian lyres, built on a
physically modelled string engine. Every note is synthesised with
Karplus-Strong: there are no samples in this repo.

The same Rust engine drives both platforms. On the web it is compiled to
WebAssembly and played through an AudioWorklet; on iOS it is compiled to a
native framework that renders straight into CoreAudio and is driven from Dart
over `dart:ffi`.

- **Instruments:** 5-string begena, 6-string krar, and a piano for comparison
- **Tuning:** the four Ethiopian *qenet* — Tizita Minor, Tizita Major,
  Ambassel and Bati — placed in cents, not rounded to the nearest piano key
- **Input:** up to ten fingers, strumming by dragging across the strings,
  glissando across the piano keys

---

## Pages

| Page | What it does |
| --- | --- |
| **Play** | The begena, face on. Touch a string to pluck it, drag across to strum. Colour-coded strings, a live voice count, an oscilloscope of the real output, and a partials meter from the string model's own harmonics. Tap a scale degree to hear it. |
| **Piano** | A playable keyboard (C3–C6 on desktop, C4–C5 on phones) with the chosen qenet laid over it. Each degree is a pad with a line down to where its pitch really falls between the keys. Compare mode plays the nearest piano key, then the Ethiopian pitch. |
| **Scales** | All four qenet on one cent ruler against equal temperament, showing which way and how far each degree leans. Each scale plays. |
| **Tab Tutor** | A 6-string krar tab with a moving playhead, tempo, loop and "wait for me". Tap along on the pluck pad and your timing is measured against the beat. |
| **Engine** | How the sound is made: the three layers, and an animated Karplus-Strong loop. The text describes whichever path the platform actually uses. |

---

## How the sound works

One Rust crate, `krar_engine`, holds the DSP. Each voice is a Karplus-Strong
string: an excitation fills a delay line one period long, and every pass
around the loop is averaged and damped, so high harmonics fade first.

Two excitations:

- **Pluck** (`pluck`) — a noise burst shaped by the string's harmonics: the
  lyres.
- **Strike** (`strike`) — a felt-shaped bump near one end of the string, with
  a longer sustain and a higher loop gain: the piano.

### Voices

The engine is created with 14 voices:

| Voices | Use |
| --- | --- |
| 0–4 | Begena strings: Db2 69 Hz, Ab2 104, Eb3 156, Bb3 233, F4 349 |
| 5 | Preview voice for single notes (scale degrees, tab playback), so they never retune a string |
| 6–13 | Piano pool, taken round robin, so chords and glissandi ring together |

`KrarEngine.voiceCount` in Dart and `NUM_VOICES` in
`krar_flutter/web/js/krar_wasm_bridge.js` must agree.

### Web

```
pointer events → Dart → krar_wasm_bridge.js → WASM KrarEngine
                                    ↓
                     AudioWorklet (krar-processor) → AnalyserNode → speakers
```

The worklet asks the main thread for each 128-frame block over its
MessagePort, so the engine currently renders on the main thread. Moving it
inside the worklet is the main open task (see [Known issues](#known-issues)).

### iOS

```
pointer events → Dart → dart:ffi → KrarEngine.framework (Rust)
                                            ↓
                              cpal / CoreAudio real-time thread → speakers
```

The audio thread never waits on the UI: the render callback only `try_lock`s
the engine, and plays one silent block rather than blocking. The C ABI lives
in [`krar_engine/src/native.rs`](krar_engine/src/native.rs) (`krar_start`,
`krar_pluck`, `krar_strike`, `krar_set_scale`, `krar_copy_waveform`, …).

---

## The scales

Cents from the root, as defined in
[`krar_engine/src/scale.rs`](krar_engine/src/scale.rs) and mirrored in
[`krar_flutter/lib/models/qenet.dart`](krar_flutter/lib/models/qenet.dart):

| Qenet | Degrees (cents) |
| --- | --- |
| Tizita Minor · ትዝታ | 0, 282, 386, 520, 678, 884, 1018, 1136 |
| Tizita Major · ትዝታ | 0, 282, 386, 520, 678, 884, 1018, 1136 |
| Ambassel · አምባሰል | 0, 182, 316, 520, 678, 812, 1018, 1136 |
| Bati · ባቲ | 0, 182, 316, 498, 678, 884, 1018, 1136 |

Several of these sit far from any piano key: 282 is 18 cents below D♯, 520 is
20 above E, 678 is 22 below G. That distance is what the Scales and Piano
pages are built to show.

> **Note:** Tizita Major currently carries the same cent table as Tizita
> Minor, so the two look and sound identical. It needs its own values.

---

## Repository layout

```
krar_engine/            Rust DSP crate (WASM + native)
  src/karplus_strong.rs   KrarEngine: voices, mixing, master gain
  src/string_model.rs     One string: pluck, strike, delay-line loop
  src/scale.rs            The four qenet
  src/native.rs           C ABI and CoreAudio output for iOS
  ios/                    build-xcframework.sh and the KrarEngine podspec
krar_flutter/           Flutter app (web + iOS)
  lib/audio/              Engine handle and the per-platform backends
  lib/models/             Qenet, piano keys, string tunings
  lib/screens/            App shell and the five pages
  lib/widgets/            Instrument canvas, meters, shared UI
  lib/theme/              Colours and type
  web/js/                 WASM bridge and the AudioWorklet processor
design/                 Source of the design canvas, one file per artboard
```

---

## Requirements

- Flutter 3.47+ (Dart SDK ^3.13.3)
- Rust with `wasm-pack`, plus the targets you build for:
  ```bash
  rustup target add wasm32-unknown-unknown aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios
  ```
- For iOS: macOS with Xcode and CocoaPods (built with Xcode 27). The app targets iOS 15+.

---

## Getting started

### Web

```bash
npm run build:engine && npm run build:web && npm run serve
```

Then open <http://localhost:8080>. Audio starts on your first tap, as
browsers require.

For a dev loop with hot reload (build the engine at least once first; the
script copies the WASM package into `web/` so audio works there too):

```bash
npm run dev
```

### iOS simulator

```bash
npm run build:ios:sim
```

Then run it from `krar_flutter`:

```bash
cd krar_flutter && flutter run
```

### iOS device

```bash
npm run build:ios
```

Open `krar_flutter/ios/Runner.xcworkspace` in Xcode and set your signing team
once. The bundle identifier is `com.mattathias.krarFlutter`.

### Tests

```bash
cd krar_flutter && flutter test
```

The suite covers the scale and piano maths, navigation, and sweeps every page
at desktop, laptop and phone sizes so layout errors fail the build. It also
runs in a browser with `flutter test --platform chrome`.

---

## Build scripts

| Script | What it does |
| --- | --- |
| `npm run build:engine` | Builds the WASM package with `wasm-pack` |
| `npm run build:engine:ios` | Builds `KrarEngine.xcframework` (device + universal simulator) |
| `npm run build:web` | Builds the Flutter web app and copies the WASM package into it |
| `npm run build:ios` | Builds the engine framework, then the iOS app |
| `npm run build:ios:sim` | The same, for the simulator |
| `npm run serve` | Serves the web build on port 8080 |
| `npm run dev` | Copies the WASM package into `web/`, then `flutter run` in Chrome |

The iOS framework is a build artifact and is not committed, so run
`npm run build:engine:ios` before `pod install` or an Xcode build in a fresh
clone.

---

## Known issues

- **Web audio still depends on the main thread.** The worklet requests every
  block over its port, so a busy UI can still interrupt the sound. Running
  the engine inside the worklet is the fix.
- **Tizita Major duplicates Tizita Minor's cents** (above).
- **Reverb is a no-op.** The engine stores the amount but does not apply it.
- **The tab editor** behind "Edit tab" predates the redesign: it records every
  note on string 0 and offers frets, which lyres do not have.
- **The simulator slice** covers Apple silicon and Intel; no other desktop
  platform has an audio backend, so the app there reports "Audio unavailable".

---

## Design

`design/` holds the source of the design canvas the app was built from: one
`.dc.html` per artboard plus the canvas layout. The artboards need the design
canvas's runtime, so they do not render as standalone HTML. See
[design/README.md](design/README.md).

---

## License

MIT, as declared in `package.json`. No `LICENSE` file has been added yet.
