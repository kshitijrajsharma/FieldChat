# Design system

The visual language for the Hulaki app and its web pages. `lib/design/app_colors.dart`
is the source of truth for colour; this document explains the intent and lists the
tokens so the app and the `pages/` web stay in step.

## Principles

- Ink leads. Buttons, the mark, and active states use ink. The interface stays
  quiet so the map and the field data carry the attention.
- Amber is reserved for GPS and signal. It is never used for buttons, feedback,
  or decoration.
- The background is near neutral. It holds only a trace of warmth so white cards
  read cleanly on it.
- Feedback stays soft. It is legible at a glance without a loud fill.
- App and web share the same values. A palette change updates both.

## Foundation

| Token | Hex | Use |
| --- | --- | --- |
| `ink` | `#15181B` | Primary text, buttons, the mark, active states |
| `inkSoft` | `#1F2421` | Secondary ink surfaces |
| `paper` | `#F6F6F4` | App background |
| `hairline` | `#F1F0EE` | Faint separators |
| `field` | `#EEEEEB` | Input surfaces |
| `mist` | `#E7E6E3` | Card dividers, avatars, the sent message bubble |
| `white` | `#FFFFFF` | Cards, the received message bubble |

The background family (`paper`, then `hairline`, `field`, `mist`) is a light grey
carrying only a trace of warmth, held close to neutral by design. The older cream
tones are not reintroduced.

## Text

| Token | Hex | Use |
| --- | --- | --- |
| `textSecondary` | `#5D584D` | Body and helper text |
| `textMuted` | `#8C887F` | Subtitles, muted labels |
| `textFaint` | `#9A968D` | Timestamps, the faintest labels |

## Status and accents

| Token | Hex | Use |
| --- | --- | --- |
| `amber` | `#E0922A` | GPS and signal only |
| `amberText` | `#A8741A` | Amber text on light surfaces |
| `gpsStrong` | `#22A75A` | Strong GPS accuracy |
| `gpsGood` | `#3E8E5A` | Good GPS accuracy |
| `danger` | `#C0392B` | Destructive actions (delete, leave group) |

## Feedback

Feedback goes through `context.showSuccess`, `showError`, and `showInfo`
(`lib/design/app_snackbar.dart`), never a raw `SnackBar`. Each is a white surface
with plain ink text and no icon, plus a thin left edge in a soft accent as the
only colour. Amber is never used here, and the stronger `danger` red stays for
destructive actions.

| Kind | Surface | Edge |
| --- | --- | --- |
| Success | `white` `#FFFFFF` | `success` `#2F7A50` |
| Error | `white` `#FFFFFF` | `dangerSoft` `#BC4436` |
| Info | `white` `#FFFFFF` | `mist` `#E7E6E3` |

## Messages

A received message bubble is `white`. A sent message bubble is `mist`, so it reads
as the sender's own without a warm one-off colour.

## Tags

Quick tags carry one colour from `TagColors`, shown as the tag dot, its map pin,
and the map filter. The tones are muted so they sit with the light interface while
staying legible on the basemap.

`ink`, `amber #C0801F`, `red #B0503D`, `sienna #8C5A3B`, `olive #6F7A35`,
`forest #3C7A4E`, `teal #2C7A70`, `blue #3466A0`, `indigo #464C88`,
`purple #6E5DA6`, `rose #A44A72`, `slate #566069`.

## Web

The pages under `pages/` mirror the same values through CSS variables
(`--paper`, `--mist`, `--field`) and the legal-page background. Any palette change
updates the app tokens and these pages together, so the app and the published
web results stay consistent.
