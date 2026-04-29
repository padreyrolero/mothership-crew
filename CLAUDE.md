# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A web app for tabletop RPG sessions of **Mothership 0e** (sci-fi horror TTRPG). No build system — the project is two standalone HTML files with all CSS and JS inlined. Open them directly in a browser or serve via any static file server (e.g. `python3 -m http.server`).

- **`index.html`** — Player-facing character creation tool (Spanish UI)
- **`admin.html`** — GM panel (password-protected)
- **`portraits/`** — Character portrait images, named by convention: `{class}-{gender}-{n}.jpg` (e.g. `marine-f-1.jpg`, `android-3.jpg`)
- **`supabase-setup.sql`** — Database schema; run in Supabase SQL Editor to set up or update tables

## Architecture

### Data layer
All persistence goes through the **Supabase REST API** (no SDK, raw `fetch`). The URL and anon key are hardcoded in both HTML files. Two tables:

- **`characters`** — `id`, `player_name`, `char_name`, `class` (enum: Marine/Teamster/Scientist/Android), `strength`, `speed`, `intellect`, `combat`, `body_save`, `fear_save`, `sanity_save`, `armor_save`, `max_stress`, `skills` (text[]), `equipment` (text[]), `trinket`, `patch`, `portrait_path`, `ship_id`, `quiz_answers`
- **`ships`** — `id`, `name`, `description`, `log_md`, `recruitment_text`

RLS is enabled with public read/insert and (for ships) public update policies. There is no server-side auth; admin access is enforced client-side with a hardcoded credential check in `admin.html`.

### `index.html` — Screen flow
Single-page app with `.screen` divs toggled via `showScreen(id)`. Screens in order:

1. **`splash`** — intro with live clock, starts the process
2. **`ship-select`** — fetches ships from Supabase, lets player pick one (max 5 crew per ship enforced here)
3. **`recruitment`** — shows the ship's `recruitment_text` as corporate flavour
4. **`quiz`** — 10-question personality quiz; answers map to classes via a weighted scoring object (`QUIZ_WEIGHTS`)
5. **`chargen`** — full character generation:
   - Class determined by quiz result (data in `CLASSES` object)
   - Gender selection → portrait carousel (images probed via `probeImage()`, taken portraits locked via `getUsedPortraits()`)
   - Background selection (per-class strings in `BACKGROUNDS`)
   - Stat rolls (3d10 × 4 stats, up to 3 rerolls)
   - Saves are fixed by class (defined in `CLASSES[cls].saves`)
   - Skill tree: Trained/Expert/Master tiers with prerequisites; point costs 1/2/3 (in `TIER_COST`); class starting skills auto-granted; player spends `freePoints`
   - D100 trinket and D100 patch rolls (large lookup tables at bottom of file)
   - On submit: `supaInsert()` writes to Supabase and advances to sheet
6. **`sheet`** — renders the filled character sheet; print button triggers `@media print` CSS that formats it as A4

Ambient audio (`startAmbient()`) plays on the chargen screen using the Web Audio API — multiple layered oscillators, brown noise, and random events (clang, blip, rumble, pulse).

### `admin.html` — GM Panel
- `doLogin()` checks credentials and stores `gm-auth` in `sessionStorage`
- `loadAll()` fetches all ships and characters in parallel, calls `renderAll()`
- Ship sections show crew sub-grid and a Markdown ship log (uses `marked.js` from CDN)
- GM can create ships (with auto-generated recruitment text), delete ships/characters, and edit per-ship logs

## Key Data Structures

```js
// CLASSES — defines all class-specific data
CLASSES[cls] = { desc, saves, specialRule, startingFixed[], startingChoice, freePoints, equipment[] }

// SKILL_TREE — all 38 skills
SKILL_TREE[key] = { es: 'Spanish name', tier: 'T'|'E'|'M', req: [prerequisiteKeys] }

// Skill point costs
TIER_COST = { T:1, E:2, M:3 }
```

## Game Rules Encoded

- Stats rolled as `10 + Math.floor(Math.random()*10)` × 4, up to 3 rerolls total (not 3 per stat)
- Class stat bonuses applied on top of rolls (e.g. Teamster gets +5 STR, +5 SPD)
- Saves are fixed per class, not rolled
- Portraits are globally locked once a character is saved (`portrait_path` stored in DB)
- Max crew per ship: `MAX_CREW = 5`
- Skill starting skills: `startingFixed` are pre-granted for free; `startingChoice` lets the player pick N from a list; `freePoints` are then spent on the tree
