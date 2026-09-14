---
name: almanac
description: Log a study session to the study almanac on the personal site (~/Documents/me). Use when the user says "almanac", "almanaque", "registra estudo", "log study session", "estudei X minutos", "sessão de estudo de hoje", or reports time spent studying something and wants it on the site.
---

# Almanac

Adds a study session to the almanac page of the personal site at `~/Documents/me`.

## Where the data lives

- `src/data/studies.json`: the only data file. `year`, `subjects[]` (`id`, `label`, `color`) and `sessions[]` (`date` YYYY-MM-DD, `subject` id, `minutes`, `note`)
- `src/components/StudyAlmanac.tsx`: `SUBJECT_TERM_COLOR` maps subject id to its color on the dark theme
- `src/i18n/en/translation.json` and `src/i18n/pt/translation.json`: `subjects.<id>` holds the lowercase label per language

`src/data/almanac.ts` builds the page from the JSON. Read it only if the behavior below looks wrong.

## Rules that are easy to miss

- **One session per day.** The grid keys sessions by date, so a second entry on the same date silently replaces the first. If the date already has a session, merge: add the minutes and join the notes with ` · `. If the subjects differ, ask the user which one the day should show
- **Only `year` counts.** Sessions from another year are ignored. When the year changes, ask before touching `year`, since it hides every older session
- **Date defaults to today.** Accept "ontem" or an explicit date
- **Note is short and in English**, like the existing ones. A few words describing what was done, not a sentence

## Picking the subject

1. Read `studies.json` and try to fit the session into an existing subject. Subjects are broad areas (e.g. `ca` Computer Architecture covers CHIP-8, CS:APP, Nand2Tetris)
2. If nothing fits, or two fit, ask the user with the options and a recommendation
3. A new subject needs all four places updated:
   - `subjects[]` in `studies.json`: short id (2 letters), Title Case English label, a color
   - `SUBJECT_TERM_COLOR` in `StudyAlmanac.tsx`: a color readable on the dark background and distinct from the others
   - `subjects.<id>` in both translation files, lowercase

## Steps

1. Get date, minutes, subject and what was done. Ask only for what is missing
2. Read `src/data/studies.json`
3. Pick or create the subject (see above)
4. Add or merge the session, keeping `sessions` sorted by date
5. Validate: `cd ~/Documents/me && npx tsc --noEmit`
6. Confirm to the user: date, subject, minutes, note

Do not commit, push or deploy unless the user asks.
