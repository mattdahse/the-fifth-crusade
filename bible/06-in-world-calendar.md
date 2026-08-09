# The Calendar of the Fifth Crusade

*The in-world date authority for the chronicle. Golarion reckoning, year 4713 AR.*

The crusade's days are kept in **Fantasy Grounds**, on the campaign calendar. This file is that
record rendered into the chronicle's voice; the untouched extraction lives beside it in
[`06-in-world-calendar.json`](06-in-world-calendar.json), which is machine-written and should
never be hand-edited. Regenerate the JSON with `pwsh -File ./extract-calendar.ps1` from the repo
root, then write any new days into this file by hand.

**Published.** `build.ps1` reads the month sections below into `window.JOURNAL`, and the site's
**Timeline** tab shows each day's entry beside the chapters that cover it. Everything after the
horizontal rule — the silent days and the open discrepancies — stays authoring matter and is not
read by the build. So this file is both the reference chapters are checked against *and* the text
the Timeline displays: write it in the chronicle's voice, and keep it accurate.

A chapter's place on that Timeline comes from its own `<!-- inworld: … -->` marker in `source/`,
not from this file. When a chapter's dates change, change both.

The campaign runs **16th Arodus** — Armasse, the day Kenabres fell — through **25th Neth**, the
assault on the Ivory Sanctum: **101 days**, of which 65 carry a log entry.

Days drawn from the GM's private log rather than the players' are marked *(GM's hand)*.

---

## Arodus, 4713 AR

- **16th** — Armasse. The host of **Deskari** came down on **Kenabres**, and the Worldwound came
  into the city with it. The first day of the whole affair.
- **23rd** — The **Gray Garrison** stormed and the ruined wardstone destroyed. Mythic power came
  to the company on that ground.
- **25th** — The **Vineyard Hills Waystation** delivered out of a demon attack.
- **30th** — **Rabiah's Redeemers** marched for **Drezen**.

## Rova, 4713 AR

- **2nd** — On the road. The quartermaster's count stood at forty-seven. *(GM's hand)*
- **3rd** — Forty-seven units of food and supply on the rolls.
- **4th** — The count fell to forty-four.
- **5th** — Forty-four still. The column camped below the **Lost Chapel**, on the road to Drezen.
- **6th** — Camped within sight of **Drezen**. The horses were poisoned in the night.
  *(GM's hand)*
- **7th** — The **Battle of Paradise Hill**; the **Battle of Southbank**; and Paradise Hill fought
  a second time when the ghouls came. *(GM's hand)*
- **8th** — The courtyard of Drezen taken.
- **9th** — The clearing of **Citadel Drezen** begun — the sally port, the **Templar's Court**, the
  **West Garrison**, the **Inheritor's Temple**.
- **10th** — The **berbalang** dealt with, and the first word of **Callan Thornwind**.
- **11th** — Back into the citadel: the third day of the assault on the first floor.
- **12th** — **Staunton Vhane** buried. ***Soul Shear*** unmade in the forge, and the dungeons
  beneath Drezen entered.
- **13th** — Drezen taken, and the ***Sword of Valor*** recovered.
- **14th** — **Sir Aldrich Thorne** came from the Queen as steward, and Drezen passed to
  **Irabeth Tirabade** to rule.
- **21st** — The first week of Drezen's recovery.
- **28th** — The second week.

## Lamashan, 4713 AR

- **5th** — The third week of recovery in Drezen.
- **12th** — Out from Drezen, to look into a cultist site rumoured in the **Marchlands**.
- **13th** — The second day toward the **Fallen Fane**, along the **Ahari** riverbed. A hail of
  teeth drove the company under a bridge; when the weather broke they looked briefly at the
  abandoned town by the water and pressed on.
- **14th** — The third day. They reached the head of the Ahari, and came out of the riverbed into
  swarming ticks. They fell back and struck south.
- **15th** — The fourth day, after a cold night nobody had dressed for — the Worldwound taking its
  toll on the unprepared. **Cornelia** took a vulture's shape to scout. A patrol was sighted and
  its backtrail followed to the cliffs, and the company slept in a cave.
- **16th** — An old, well-worn trail down the cliffs, and a wide cave holding a temple of
  **Baphomet** kept as a cultists' waystation. **Varic** knew it for a defiled house of
  **Sarenrae**, and it drove him into a rage.
- **17th** — The night spent inside the **Fallen Fane**.
- **18th** — Homeward for Drezen. Ashstorms slowed them.
- **19th** — Still on the road, camped at a shack near the Ahari riverbed.
- **20th** — Drezen again, and news waiting: a priest missing, and caravans being taken.
- **21st** — The disappearance of **Jeskar Hinton** looked into.
- **22nd** — Out for the **Weeping Hills**.
- **23rd** — The **Weeping Hills** reached.
- **24th** — Turned back toward Drezen.
- **25th** — Still bound for Drezen, the Weeping Hills' treasure carried out with them.
- **26th** — Met with **Irabeth**, and commissioned scrolls of ***Secure Shelter***.
- **27th** — The trek toward the temple of **Sarenrae** begun. The hunting came to nothing.
- **28th** — They woke to a rain of acidic ooze.
- **29th** — Camp broken, and a new day's march.
- **30th** — Dead cultists on the ground, and a mount carrying a message that named
  **Jaruunicka** and **Takira's Redoubt**.
- **31st** — The cliffs before the **Gray Road**. Bodaks found them while they gathered firewood.

## Neth, 4713 AR

- **1st** — They came again to the Fallen Fane, no longer fallen. A storm of lightning and
  bursting air met them there.
- **2nd** — The day spent digging out the temple of **Sarenrae**.
- **3rd** — The ground around the new temple explored.
- **4th** — A dream at dawn sent **Harlock** and the company chasing south.
- **5th** — An abyssal rift-storm washed **Lupenor** and **Chyrrik** downstream.
- **6th** — Toward the place of Harlock's dream, and the long way about. **Rabiah** felt herself
  watched.
- **7th** — Across the **Gray Road** and along the shore of the lava lake. **Abner Suthi** died in
  the **Molten Scar**, and the mythic vrock **Vorimeraak** was slain there.
- **8th** — Back by teleport to the temple of Sarenrae. Rabiah studied the ground; the night
  passed indoors.
- **9th** — Out from the temple of **Sarenrae**, north along the rim of the great inland sea by an
  unfamiliar route, followers in train and the hunters of **Erastil** among them.
- **10th** — Second day out. **Selyse Avelia**'s bird taken; the **babau**'s parley on the road;
  the Derakni ambush. **Selyse** read a scroll and was gone. A forced march was argued for and
  voted down; the company made a fortified camp ten miles from **Drezen** instead, **Varic**
  walling the horses in and sitting the night out beside them.
- **11th** — Into **Drezen** before noon. The spoils sold, the great uncut diamond traded away,
  **Abner Suthi** raised in the temple of **Sarenrae** at **Varic**'s own expense. The mural on
  **Rabiah**'s wall. **Horgus Gwerm** asked for paladins and got them.
- **12th** — Breakfast with **Abner**; the charm bracelet given and unmasked as a beacon.
  **Gretcher** marched them to the Citadel, where **Anevia** asked them to plant the Queen's spy
  at the shrine and **Takira's Redoubt** surfaced on **Selyse**'s new map. **Smendrick** the
  jeweller; the watcher turned back down his own thread; **Horgus**'s escort recalled and refused.
  That evening **Chyrrik** and three paladins went out to the shrine and **Elara Dawnstrider** came
  home, by way of two badly missed teleports.
- **13th** — The Queen's agent collected from the temple pews, and the company carried west to the
  **Hidden Shrine**, where they spent the night and turned their minds to the dragon.
- **14th** — The lair of the woundwyrm **Scorizscar** found, and Scorizscar slain.
- **15th** — From the dragon's lair by teleport to the temple of Sarenrae, where they sat out the
  storm.
- **16th** — Out from the temple toward the redoubt.
- **17th** — On the Gray Road, west for **Takira's Redoubt**. **Lupenor** woke from a dream of the
  place. The **Red Swarm** took them on the road.
- **18th** — Marching for the redoubt.
- **19th** — **Takira's Redoubt** reached.
- **20th** — Teleport to the Hidden Shrine: goods set down, orders left, **Chyrrik** posted as
  runner, **Samail** raised — and back to the redoubt, mostly by teleport again.
- **21st** — A storm of teeth held them from leaving for the **Green Gates** and the
  **Ivory Sanctum**. Rabiah's needle and thread built the first bridge to her new succubus
  companion.
- **22nd** — Toward the Green Gates, with **Arueshalae** guiding.
- **23rd** — The same road, the same guide.
- **24th** — The climb to the **Green Gates**.
- **25th** — The **Ivory Sanctum** assaulted.

---

## Silent days

Three log days exist in Fantasy Grounds carrying no text at all: **24th Arodus**, **26th Arodus**,
and a stray duplicate of **16th Arodus** filed under year 0. They are noise, not gaps in the
record — the campaign simply logged nothing for them.

## Open discrepancies

Flagged where the Fantasy Grounds log and the chronicle disagree, or where the log names something
the chronicle has never named. **Not yet reconciled** — resolve with Matt before relying on either.

- **7th Neth — Abner Suthi.** The log reads *"Killed Abner Soothy and the mythic Vrock."* The
  chronicle and the Cast both have him rescued from the vrocks' ritual and killed by their
  lightning moments after — not slain by the company. Rendered above to match the chronicle.
- **10th Neth — Drezen. ⚠️ REOPENED, and the previous resolution was wrong.** Ch IX was validated
  against its recording (call `667972898`) in Aug 2026, and **the forced march never happened.** The
  recording is explicit: the company argued for pushing through, read out the forced-march rules,
  decided the horses could not do three hours of broken ground in the dark, and **camped** — a
  proper fortified camp inside the *Sword of Valor*'s ward, with **Varic** raising a *Wall of Stone*
  to pen the horses, ringing it with torches, and sitting up in the gap all night. They walked in
  the next morning, and **Rabiah's followers were at the gate because they had worked out the
  arrival day in advance** — so "well ahead of schedule" was wrong too. The camp has been restored
  to Ch IX and the day-by-day above rebuilt around it. *(The earlier pass deleted a real scene to
  make the log fit; noted here so it is not deleted a second time.)*
  **What this costs:** the FG log's *"10th Neth — Drezen, to no small fanfare"* and the GM's own
  in-session dates on 9 May (*"today is the 10th of Neth"*, *"Toil Day, the 12th of Neth"*) are now
  **one day early**, because neither counts the night in camp. The chronicle's dates above follow
  Ch VIII's validated *second day out = 10 Neth* and run 11–13 Neth. **Matt to rule** on which
  record moves; nothing downstream of the 14th is affected either way.
- **Ch VIII / Ch IX overlap — the body count is still out.** Ch VIII (validated) ends with **one**
  Derakni dead and one fled. The 9 May recording opens with the GM describing **two** Derakni
  carcasses on the rock. Both chapters are now validated against their own recordings, so this is
  not a chronicle error but a table one: the 9 May recap simply mis-remembered the previous
  session's tally. Ch IX's text follows the recording. **Matt to rule** whether Ch IX drops to one
  carcass to agree with Ch VIII.
- **20th Neth — Samail.** A raising the chronicle never records; the name appears nowhere in
  `source/` or `characters/`. Spelling unconfirmed.
- **Vorimeraak.** The mythic vrock of the Molten Scar. Spelling and sex settled by Matt, Aug 2026:
  **Vorimeraak**, and **she is female** — the session transcript's "Vremorak" and its male pronouns
  are both wrong, and the chronicle has been corrected throughout.
- **7th Rova — Southbank.** The log spells it *Soutthbank*; the chronicle never names the battle
  at all, though it covers the fighting.
- **Book I's four days.** Arodus 16–30 carry four entries for eight sessions of play. The log
  thins backward, not the story — do not read the silence as absence.
