# Canonical Character Portraits

This directory is the **source of truth for how the people of the chronicle look.**
Every named character who has been given a face lives here as a single canonical
portrait. When any image is generated that depicts one of these characters — a
chapter illustration, a scene, a group shot — that character's canonical portrait
below **must** be supplied to the image tool as a likeness reference, so they stay
recognizable from picture to picture. All new art follows the house look described in
[`../bible/04-visual-style-guide.md`](../bible/04-visual-style-guide.md).

The portraits were gathered in different styles; that is fine for a reference of
*who a character is*. The style guide governs *how* new art is rendered. The
definitive style exemplar is the full-body Arueshalae in [`../images/arueshalae.png`](../images/arueshalae.png).

## Registry

| Character | Portrait | Cast group | Likeness anchors (keep these constant) |
|---|---|---|---|
| **Harlock Greyforge** | [`harlock.png`](harlock.png) | The Company | Half-orc man; green skin, short black hair, dark brows, clean-shaven, subtly pointed ears. **A clean, strong, human-like jaw with a closed mouth — NO tusks, NO underbite, no protruding lower teeth.** Noble, even features. Ornate golden full plate; bears the sunburst shield *Radiance*, its face a blazing star. **Timeline — the golden full plate is his LATER look.** Through Book I (Kenabres to the Gray Garrison, including the mythic dream) he is newly sworn and poorly equipped: **a plain steel breastplate bearing Iomedae's sunburst over a padded gambeson, with no pauldrons, gauntlets, greaves, or filigree** — battered and campaign-worn. For any early scene, take his **face and skin tone** from the portrait and **not his kit**. |
| **Lupenor Celest** | [`lupenor.png`](lupenor.png) | The Company | Elf woman; long fiery copper-orange hair, **violet eyes**, light freckles; long tapered ears; deep-blue teardrop-gem earrings in silver settings. Wears a **high-collared dark-green tunic with a steel pauldron at the shoulder — covered, practical**; fletched arrows quivered at her back. |
| **Rabiah** | [`rabiah.png`](rabiah.png) | The Company | Human woman; wild curly red hair tangled with green leaves, **green eyes**, freckles, rosy cheeks; green hooded cloak over green garb, **a leather baldric across the chest with a round dark metal medallion at the shoulder**. (The Riftwardens' spiral is lore, *not* visible in the portrait — don't draw a spiral.) |
| **Varic Sarian** | [`varic.png`](varic.png) | The Company | Half-elf man; long straight blond hair, thin woven gold circlet, clean-shaven, grey-blue eyes; deep-red scarf/cowl and mantle over a gold breastplate with red-and-gold filigree scrollwork. **Steel pauldrons on BOTH shoulders, chainmail beneath.** Sarenrae's sunset behind him. |
| **Chirrik** | [`chirrik.png`](chirrik.png) | The Company | Mongrelman scout, **female (she/her)**; reptilian-avian head with a hooked dark beak, reddish-brown hair in a high ponytail; heavily scaled digitigrade legs with taloned feet, **and a long scaled tail**; **human-like pinkish hands** contrasting the scaled limbs; grey-green hooded travel leathers, wrapped forearms; long horn bow and a quiver of black-fletched arrows. |
| **Cornelia Dewfoot** | [`cornelia.png`](cornelia.png) | Rabiah's Redeemers | Small fey-featured druid; long wavy blonde hair with small braids and a leaf tucked in, pointed ears, **blue eyes**, freckles. Tattered layered green leaf-like druid garb and mossy cloak, beaded necklace, belt of pouches with a small animal skull; carries an oversized scythe with a **vine-wrapped wooden haft**; crescent moon overhead. **She reads as a CHILD — render her youthful and never sexualized: no adult proportions, no revealing or form-fitting clothing.** |
| **Elara Dawnstrider** | [`elara-dawnstrider.png`](elara-dawnstrider.png) | Harlock's Order | Human paladin woman; long wavy brown-auburn hair, gold drop earrings; polished **silver plate with gold filigree, one oversized layered spiked pauldron on her left shoulder**; holds an ornate polearm with a silver-and-gold winged head; sunlit citadel behind. **Full plate cuirass covering the torso — never bared midriff or bikini-plate.** |
| **Arueshalae** | [`arueshalae.png`](arueshalae.png) | Allies & Powers | Succubus; short tousled black hair, curved dark horns, pointed ears, freckled; dark membranous wings. **Dressed in practical brown leather adventuring armor — a high-collared, buckled, long-sleeved leather jacket over leather trousers and tall buckled boots. FULLY COVERED, modest and battle-worn; never revealing, never a bikini/harness/bare midriff.** Tattoos show only at the open collar of her throat. Storm-lit. Style exemplar: [`../images/arueshalae.png`](../images/arueshalae.png). |
| **Iomedae** | [`iomedae.png`](iomedae.png) | Allies & Powers | The Inheritor, goddess of righteous valor. Human woman; **short black hair in a chin-length bob**, pale skin, dark eyes. **She emits a subtle divine radiance** — a soft glow clinging to her person that lights the air around her. Never a halo ring, glowing eyes, beams, or rays. **Mirror-polished silver-white full plate with fine gold edging**, a **rich clean crimson cloak**, a **silver-white kite shield bearing a gold eight-pointed starburst**, and a long straight **longsword held point-down, both hands resting on the pommel**. **Her gear is ALWAYS immaculate — no dent, scratch, smudge, soot, rust, tatter, or battle damage, ever, however ruined the setting around her.** **Only her FACE bears scars — the remnant of her mortal life:** a pale scar down her left cheek, weathered and lined, a woman of middle years carrying the gravity of ages. Never a smooth, young, unmarked face. **Fully covering plate — gorget, pauldrons, vambraces, gauntlets, faulds, and fully armored legs. Never bare thighs, bare midriff, a contoured/anatomical breastplate, or bikini-plate.** *(Fresh house-style render; the original 188×268 source thumbnail was low-resolution, young-faced, and bare-legged, and is superseded.)* |
| **Rothin Vald** | [`rothin.png`](rothin.png) | Varic's Temple | Human priest of Sarenrae, middle-aged; dark hair swept back from a widow's peak and greying at the temples, **full dark beard shot with grey**, heavy dark brows, **pale blue-teal eyes**, stern and serious. Teal-blue tunic with a gold band at the collar over a brown undershirt. Varic's cohort; keeper of the Hidden Temple of Sarenrae west of Drezen. |

## Known drift — state the negatives explicitly in every prompt

Image models fall into the same traps repeatedly. Descriptions here are **prescriptive**: if an anchor is silent on something, the model invents it, and it invents these:

- **Fantasy-armor sexualization.** Any woman in "leather" trends toward a bikini, bare midriff, or strap harness. Arueshalae in particular is a succubus, which pulls hard in that direction — she is a *penitent*, dressed as a working scout in covered leathers. Always say **"fully covered, modest, practical armor"** and add `bare midriff, revealing outfit, bikini armor, cleavage` to the Avoid line.
- **Orc caricature.** "Half-orc" alone yields tusks, an underbite, and a brutish snout. Harlock has none of these. Say **"no tusks, no underbite, clean strong human-like jaw"** and put `tusks, underbite, protruding lower teeth, brutish features` in the Avoid line.
- **Child-like characters must never be sexualized.** Cornelia reads as a young girl. Any prompt depicting her states **"a child, youthful proportions, modest covering clothing"** and carries `sexualized, adult proportions, revealing or form-fitting clothing` in the Avoid line. This is non-negotiable and overrides any styling instruction.
- **Deities are not weathered mortals.** A god depicted in the chronicle **emits a subtle divine glow** and their raiment, armor, and weapons are **flawless — no dent, smudge, soot, rust, tatter, or battle damage — no matter how ruined the setting around them.** The contrast against a crumbling, filthy world is the point, and the glow is the image's single luminous accent. **Only a deity's face may bear scars**, as a remnant of a mortal life (Iomedae's do; her armor never does). Left unsaid, the model will distress a god's gear to match the environment. Applies to Iomedae, Sarenrae, and Desna alike.
- **Inferred lore is not observed detail.** Rabiah's row once claimed a "Riftwardens' spiral at the shoulder" because the *cast bio* mentions the spiral — the portrait shows a plain round medallion. Describe only what the PNG shows; keep lore out of the likeness anchors.
- **Verify against the portrait, not your memory of it.** Both errors above originated in this file — an anchor written from a hazy recollection propagated straight into the art. Re-open the PNG before you write or trust a row.

## Adding a character to the registry

1. Save the canonical portrait here as `<kebab-name>.png` (portrait/bust framing, ~3:4).
2. Add a row above with the likeness anchors — the handful of features that must never drift.
3. Register the likeness in the site: add `'<Cast Name>': 'characters/<file>.png'` to the
   `PORTRAITS` map in [`../index.html`](../index.html) so it appears on the Cast gallery.
4. Keep the filename stable forever — the site and the style guide both reference it by name.
