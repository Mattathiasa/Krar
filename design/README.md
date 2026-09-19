# Design canvas

Source of the Krar & Begena Studio design canvas: one `.dc.html` file per
artboard and `canvas.json`, which lays the artboards out on the canvas.

| Artboard | What it shows |
| --- | --- |
| `Main.dc.html` | Studio: the begena, qenet picker, playable scale degrees |
| `Piano.dc.html` | Piano with each qenet degree laid over the keys, and compare mode |
| `Scales.dc.html` | The four qenet against 12-TET, with playback |
| `Tutor.dc.html` | Tab tutor for the 6-string krar |
| `Mobile.dc.html` | Studio on a phone |
| `Engine.dc.html` | How the sound is made: threads and the Karplus-Strong loop |

The artboards are Design Component pages: they load `./support.js` from the
design canvas they run in, so they don't render as standalone HTML. The
Flutter app in `krar_flutter/` implements this design.
