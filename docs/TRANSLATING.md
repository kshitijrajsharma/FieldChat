# Translating Hulaki

Hulaki can speak any language. Adding one takes a single file, and you do not
need to know Flutter or Dart to do it.

Every language lives in `lib/l10n/` as one file named `app_<code>.arb`, where
`<code>` is the two letter language code:

```
lib/l10n/app_en.arb   English (the original)
lib/l10n/app_es.arb   Spanish
lib/l10n/app_fr.arb   French
lib/l10n/app_pt.arb   Portuguese
```

The app picks up whatever files are in that folder. Add `app_de.arb` and German
appears in the language list on the Me screen, with no other change anywhere.

## Add a language

1. Find the language code for your language on the
   [ISO 639-1 list](https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes)
   (German is `de`, Nepali is `ne`, Swahili is `sw`).
2. Copy `lib/l10n/app_en.arb` to `lib/l10n/app_<code>.arb`.
3. Open your new file and translate it (see below).
4. Open a pull request.

## What the file looks like

An ARB file is a list of pairs. The name on the left is an internal label. The
text on the right is what people read on screen. **Translate only the text on the
right.**

```json
{
  "@@locale": "de",
  "languageName": "Deutsch",
  "chatsNoGroupsYet": "Noch keine Gruppen",
  "commonCancel": "Abbrechen"
}
```

Three rules cover almost everything:

- **`@@locale` must match your file name.** In `app_de.arb` it is `"de"`.
- **`languageName` is your language written in your language.** It is what people
  see in the language list, so German is `Deutsch`, not `German`.
- **Lines starting with `@` are notes for translators.** You can delete them from
  your file, or keep them. They are never shown to anyone.

## Words in curly braces

Some texts have a slot in them, written in curly braces:

```json
"meSignedInAs": "Signed in as {name}"
```

`{name}` is replaced by real text when the app runs. **Keep every slot exactly as
written, spelling included.** You may move it to wherever it belongs in your
language:

```json
"meSignedInAs": "Angemeldet als {name}"
```

Some texts change with a number:

```json
"chatsPointCount": "{count, plural, =0{No points} =1{1 point} other{{count} points}}"
```

Translate only the words inside the inner braces. Keep `count`, `plural`, `=0`,
`=1` and `other` exactly as they are. If your language needs different plural
categories, you may use `one`, `two`, `few`, `many` and `other` as your grammar
requires.

## Check your work

If you have Flutter installed:

```
dart run tool/verify_translations.dart
```

It tells you, in plain words, about any missing text or any slot you dropped.

If you do not have Flutter, open the pull request anyway. The same check runs
automatically and will comment on what needs fixing.

## Keeping a translation up to date

When the app gains a new screen, English gains new lines and every other language
is missing them. The check will list exactly which ones. Add those lines to your
file and the language is current again.
