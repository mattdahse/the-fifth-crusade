# The Liberation of Drezen — Campaign Archive

A searchable, browsable archive of our Pathfinder: *Wrath of the Righteous* campaign —
*A Chronicle of the Crusade Against the Worldwound*.

**Live site:** enabled via GitHub Pages (see the repository's environment/deployment).

## What's here

- **33 chapters** across two books:
  - *Book I — The Road to Drezen* (14 chapters): the fall of Kenabres, the underground escape, Neathholm, the Black Wing Library, and the storming of the Gray Garrison.
  - *Book II — The Liberation of Drezen* (19 chapters): the siege of the citadel and the long crusade beyond, out to Takira's Redoubt.
- **Full-text search** across every chapter (client-side, no server).
- A **reader** for each chapter, each linked to its Fathom session recording.
- A **cast** reference (in-game names).

## How it's built

A fully static site — just two files:

- `index.html` — the app (search, reader, cast); all CSS and JS inlined.
- `data.js` — the chapter corpus, compiled from the master Chronicle and the reconstructed Book I.

No build step and no dependencies. To run locally, put both files in a folder and open `index.html`
in any browser (it works from `file://`).

*Compiled from session transcripts (Fathom) and the emailed chapter recaps.*
