# SliceMate Changelog

## 0.25
- Feature: Forward/backward slicing, using quantize
- Feature: Forward/backward fill, limited by scope (song, pattern, etc.)
- Feature: Slice insert (insert existing slices into pattern)
- Feature: Add “Step size” as quantize amount
- Cleaned up, rearranged GUI a bit 
- Fixed: beat-sync issue (related to xLib) 
- Fixed: re-use effect columns if values are identical (skip writing)
- Fixed: issue with invalid pos (first line in song)

## 0.22
- Add preliminary support for beat-synced samples 
- Fix: never search forward when looking for notes to slice

## 0.21
- Fix issue when placing cursor at last line of phrase
- Preserve effect-column indices for Sxx, Zxx commands
- Don't overwrite existing effect-columns (allocate new cols if needed)
- Option to suspend "selection" updates while GUI is hidden (less CPU usage)
- Add link to github documentation [www]
- Add MIDI mappings for navigating to prev/next line 

## 0.2
- Add support for slicing instrument phrases
- Add emulated pattern navigation while dialog is focused
- Add ability to navigate prev/next line 
- Remove "show GUI on auto-start" option (always do this)
- Update cLib/xLib libraries

## 0.17

- Add support for Sxx commands (also when triggering slices)
- Notes are inserted using their basenote

## 0.16

- Bugfixes

## 0.15

- Quantize notes to line,beat,bar,block or pattern (optional)
- Fixed: "detach" button should now work properly
- Clear the "slice status" when not connected to an instrument

## 0.12

- Detect changes to instrument, samples, song (tempo) and pattern data
- Bugfixes

## 0.11

- Carry over sample properties to newly sliced samples

## 0.1 

- Initial version 
