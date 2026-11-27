# Port Master: Melaka 1511 — Art Direction & Style Guide

**Version:** 1.0 (Stage A Baseline + Stages B–E Visual Bible)  
**Target Engine:** Godot 4.3 (2D, GL Compatibility Renderer, `1280×720` base viewport)  
**Period:** Melaka Sultanate, c. 1500 (pre-Portuguese conquest of August 1511)

---

## 1. Visual Identity & Art Direction

**Style Pillar — "Maritime Manuscript & Painted Woodblock"**

*Port Master: Melaka 1511* blends the clarity of a tabletop port-strategy board with the warmth of Southeast Asian maritime cartography, Malay illuminated manuscripts (*hikayat* marginalia), and hand-inked architectural watercolors.

1. **Readable Silhouettes First.** Every vessel class, cargo container, seal, and knot must be distinguishable at a glance by outline alone before color or text is read.
2. **Warm Tropical Daylight over Cool Straits Water.** Sunlit timber, laterite earth, attap thatch, and unbleached sails sit warmly against the deep jade-teal waters of the Straits of Malacca.
3. **Tactile Deduction Craft.** In the Inspection View, objects shift from distant painterly silhouettes to crisp, close-up physical artifacts—glazed stoneware, cobalt porcelain, coarse hemp, brittle lac wax, and rag-paper manifests—so discrepancies are genuinely *seen*, not merely listed in text.
4. **Ink, Not Digital Black.** Outlines use warm sepia ink (`#2A1E17`) rather than pure `#000000`, giving sprites cohesion against both sunlit water and parchment UI.

---

## 2. Historical Grounding & Anachronism Guardrails (c. 1500 Melaka)

All visual assets depict the **Melaka Sultanate at its commercial height around 1500**, prior to Afonso de Albuquerque's 1511 conquest.

### Visually Grounded Elements (Include)
- **Harbour Geography:** The mouth of the Melaka River dividing the royal/administrative south bank (*Bandar Melaka*) from the cosmopolitan merchant quarter on the north bank (*Kampung Upeh*).
- **Skyline & Architecture:** **Bukit Melaka** (the coastal hill) crowned by the **Sultan's timber Istana**—a raised Malay palace on stilts with curved, multi-tiered wooden roofs and carved gables—flanked by timber stockades, coconut palms, and nipah/mangrove shoreline.
- **Port Infrastructure:** A wooden bridge lined with covered market stalls spanning the river; timber jetties and wharves (*pangkalan*); attap-thatched timber warehouses (*gedong*) for trade goods.
- **Vessels:** Distinct regional maritime traditions—Southeast Asian *jong* (tall hulls, tilted rectangular *tanja* sails, twin quarter rudders), Ming Chinese *chuan* junks (batten-lug ribbed sails, high poop deck, transom bow with painted *oculus*), Gujarati/Indian Ocean merchantmen (dark teak hulls, settee/lateen sails), Arabian *baghlah*/dhows (swept lateen sails, long raked prow), and nimble Malay coastal *perahu*/*lanchara*.
- **Cargo & Customs Tools:** Woven pandanus/gunny sacks (rice, pepper), large glazed Martaban (*martavan*) stoneware jars packing Ming blue-and-white porcelain bowls in straw, strapped timber trade chests/bales (frankincense), cast Melaka tin ingots (*tampang*/*bida* stepped blocks), brass steelyard balances (*dacing*), reed pens (*kalam*), and rag-paper manifests.

### Anachronisms to Avoid (Exclude)
- **No Portuguese stone fortress (*A Famosa*).** It was constructed only after the August 1511 conquest.
- **No European galleons or carracks** in standard merchant traffic (reserved strictly for late-game 1511 historical events if introduced).
- **No European oak barrels/casks** as default Asian cargo containers.
- **No invented "standardized national seals" presented as historical fact.** Per `docs/gameplay-blueprint.md` and `docs/research/seals-marks-packaging.md`, only diplomatic seals (Ming silver seals bestowed on Melaka's rulers) are documented for Melaka—none on cargo. Keep Ming diplomatic seals off ordinary cargo; treat any shahbandar clearance stamp, merchant mark, or tied-closure wax/lac seal as separate gameplay visual grammar, not a single historical Melaka cargo standard.
- **Archaeological grounding for ceramics & packing:** Base stoneware storage jars and nested porcelain bowls on the late-15th-century **Santa Cruz wreck** (bulbous brown/olive stoneware jars with short necks, shoulder ear-lugs, incised/stamped shoulder marks, and porcelain cups/bowls packed inside jars) and the **Bakau wreck** (tall grey stoneware jars with four lugs). Treat ink ownership marks on ceramic bases as an older regional precedent (**Nanhai I**, Song period). How 1511 cloth bales, sacks, and wooden chests were wrapped, sewn, or knotted is undocumented in Melaka sources and is therefore deliberate art direction for silhouette readability (blocky bound bale vs. bulging gathered sack vs. rigid lidded chest).
- **No modern UI chrome** (neon glows, flat sci-fi gradients, modern sans-serif HUDs).

---

## 3. Master Color Palette

### Straits Water & Sky
| Swatch | Hex | Usage |
|---|---|---|
| Deep Malacca Jade | `#1B4D54` | Deep anchorage water, hull waterlines |
| Mid Straits Teal | `#2C6E73` | Open bay, wave troughs |
| Shoal Turquoise | `#4D9596` | River mouth shallows, sunlit water bands |
| Sunlit Seafoam | `#DCE8E2` | Wake ripples, shoreline highlights |
| Tropical Zenith | `#8EB8BD` | Upper sky wash |
| Monsoon Gold | `#F2D7A7` | Low horizon glow, morning sunlight |

### Melaka Shore, Architecture & Foliage
| Swatch | Hex | Usage |
|---|---|---|
| Laterite Earth | `#9C523B` | Coastal hillside soil, roof ridge accents |
| Aged Teak | `#5C3B28` | Wharves, ship hulls, inspection desk |
| Sunlit Merbau | `#8C5E3C` | Lit timber planks, bridge beams, Istana walls |
| Attap Thatch | `#B59461` | Godown roofs, woven baskets, straw packing |
| Deep Palm Green | `#3E6342` | Mangroves, shaded jungle canopy |
| Sunlit Frond | `#648C4F` | Coconut palms, sunlit hillside foliage |

### Sails, Textiles & Trade Goods
| Swatch | Hex | Usage |
|---|---|---|
| Unbleached Cotton | `#E9DEC8` | Sails, rice sacks, linen wraps |
| Saffron Ochre | `#D49B3E` | Javanese *tanja* sails, royal accents, rice grain |
| Kling Indigo | `#2B4666` | Indian sail trim, merchant textiles |
| Cinnabar Lac | `#A8322D` | Wax seals, Chinese junk trim, official stamps |
| Ming Cobalt | `#254C8A` | Blue-and-white porcelain motifs |
| Porcelain Glaze | `#F5F2EA` | Ming ceramic body, highlights |
| Cast Tin Pewter | `#8C9499` | Melaka *bida*/*tampang* tin ingots |
| Frankincense Amber | `#D99B43` | Resin tears, brass highlights |
| Peppercorn Umber | `#3D2E24` | Peppercorns, dark hull shadows |

### Parchment UI, Ink & Semantic States
| Swatch | Hex | Usage |
|---|---|---|
| Sepia Ink | `#2A1E17` | All outlines, primary body typography |
| Aged Rag Paper | `#EFE5CE` | Manifests, UI panel fill |
| Warm Vellum | `#F7F0DF` | Highlighted cards, active paper surfaces |
| Brass Trim | `#C49A45` | Panel borders, *dacing* steelyard, royal trim |
| Status Clear (Jade) | `#3B7A57` | Cleared cargo, intact seal, available berth |
| Status Caution (Ochre) | `#C98A2C` | Waiting ship, minor discrepancy |
| Status Alert (Cinnabar) | `#A8322D` | Broken seal, lost arrival, urgent warning |

---

## 4. Lighting, Linework & Shading Standards

- **Key Light:** Consistent upper-left tropical morning sun (~35° elevation). Left/top faces receive warm gold highlights (`#F7E7C4` screen/overlay tint); right/bottom faces fall into cool teal-umber shadow (`#2A3942` multiply at 20–30%).
- **Atmospheric Perspective:** Background layers (distant hills, horizon clouds) desaturate toward `#E6C38E` / `#B8CDD0` and drop heavy outlines. Foreground sprites (ships, cargo, inspection artifacts) carry full saturation and crisp ink lines.
- **Line Weights (at 1× native canvas):**
  - Harbour backdrop distant forms: `0–1 px` soft tinted strokes.
  - Ship sprites (`256×192`): `2.5 px` exterior silhouette in `#2A1E17`, `1.2–1.5 px` interior planking/rigging lines.
  - Cargo icons (`128×128`): `2.5 px` exterior contour, `1.2 px` texture details.
  - Inspection close-ups (`256×256`+): `2–3 px` expressive ink contour with subtle cross-hatching or stipple shading.
- **Surface Texture:** Use subtle organic grain (paper fiber on parchment, woodgrain lines on timber, mottled glaze highlights on stoneware) rather than sterile flat fills.

---

## 5. Godot 4.3 Technical & Import Specifications

- **Viewport:** `1280×720`, stretch mode `canvas_items`, stretch aspect `keep`.
- **Format:** 8-bit RGBA PNG (`*.png`) with clean alpha channels for all sprites, icons, and UI frames.
- **Directory Layout** (aligned with `docs/data-formats.md` for Stage A JSON references):
  ```text
  assets/
    inspection/    # Stage A case evidence illustrations (2:1, <lowercase-kebab-name>.png/.svg), referenced by data/inspections/*.json
    art/
      harbour/     # Panoramic harbour backdrop, berth markers, water/shore overlays
      ships/       # Vessel sprites (side-3/4 profile, facing left-to-right consistently)
      cargo/       # Cargo lot icons (128x128) & close-up inspection props (256x256)
      inspection/  # Customs desk backdrop, manifest parchment, seals, tools
      ui/          # 9-slice panels, header banners, icons
      marks/       # (Stage B+) Merchant marks & reference manual glyphs
      knots/       # (Stage B+) Cordage & knot inspection close-ups
      portraits/   # (Stage B+) Character busts
  ```
- **Naming Convention:** Lowercase `snake_case`, prefixed by asset category (`ship_<origin>_<type>.png`, `cargo_<commodity>.png`, `seal_<material>_<state>.png`).
- **Godot Import Settings:**
  - `compress/mode`: Lossless (or VRAM Compressed for large backdrops if needed).
  - `mipmaps/generate`: `false` for crisp UI and 2D sprites; `true` only if heavy zooming is added later.
  - `process/fix_alpha_border`: `true` to prevent dark fringes on transparent sprite edges.
  - Commit `.import` sidecar files if custom settings are needed; **never commit `.godot/`**.

---

## 6. Stage A Asset Inventory (Implemented)

| Asset Path | Native Size | Role & Visual Notes |
|---|---|---|
| `assets/art/harbour/harbour_backdrop.png` | `1280×720` | Panoramic c.1500 Melaka harbour: Bukit Melaka with timber Istana, wooden bridge with stalls, attap godowns, 2 foreground timber berths, and open Straits anchorage bay. |
| `assets/art/harbour/berth_marker.png` | `160×64` | Carved timber-and-brass berth nameplate for docking slots. |
| `assets/art/ships/ship_javanese_jong.png` | `256×192` | Javanese Rice Trader (*jong*): high curved hull, twin ochre *tanja* sails, quarter rudders. |
| `assets/art/ships/ship_chinese_junk.png` | `256×192` | Chinese Porcelain Trader (Ming *chuan*): ribbed batten-lug sails, high red-trimmed stern, painted bow *oculus*. |
| `assets/art/ships/ship_indian_merchant.png` | `256×192` | Indian Pepper Trader (Gujarati/Malabar): dark teak hull, twin indigo-trimmed settee/lateen sails. |
| `assets/art/ships/ship_arabian_dhow.png` | `256×192` | Arabian Frankincense Trader (*baghlah*/dhow): long raked prow, ornamented stern, sweeping cream lateen sails. |
| `assets/art/ships/ship_regional_perahu.png` | `256×192` | Regional Tin Trader (Malay coastal *perahu*): slender low-draft hull, single pandanus-tan *tanja* sail. |
| `assets/art/ships/ship_coromandel_cloth.png` | `256×192` | Coromandel Cloth Trader (South Indian *Keling* merchantman): warm teak hull, madder-red & cream striped sails. |
| `assets/art/cargo/cargo_rice.png` | `128×128` | Stitched woven pandanus/gunny sacks with golden unhusked/milled rice spill. |
| `assets/art/cargo/cargo_porcelain.png` | `128×128` | Glazed brown Martaban stoneware jar alongside a Ming blue-and-white porcelain bowl. |
| `assets/art/cargo/cargo_pepper.png` | `128×128` | Tied jute spice sacks with dark peppercorns spilling onto woven cloth. |
| `assets/art/cargo/cargo_frankincense.png` | `128×128` | Strapped teak/cedar resin chest with translucent pale-amber frankincense tears. |
| `assets/art/cargo/cargo_tin.png` | `128×128` | Stacked Melaka cast tin ingots (*bida*/*tampang* stepped pewter blocks). |
| `assets/art/cargo/cargo_cloth.png` | `128×128` | Bound bolts of Coromandel dyed cotton/chintz in Kling indigo, madder red, and saffron ochre. |
| `assets/art/cargo/porcelain_jar_closed.png` | `256×256` | Inspection close-up: sealed Martaban stoneware jar (Santa Cruz profile) bound with hemp cord and wax/lac closure. |
| `assets/art/cargo/porcelain_jar_open.png` | `256×256` | Inspection close-up: opened Martaban jar revealing straw packing and nested Ming blue-and-white bowls inside. |
| `assets/inspection/lot-seven-exterior.png` | `640×320` | Stage A `case_001` ("The jars from Guangzhou") evidence plate (2:1): forward-row jars (dry grey circle-and-line seals, 32–36 kati) vs. after-row jars (soft reddish fish-facing-left seals, loose straw, 45–47 kati). |
| `assets/inspection/lot-seven-open.png` | `640×320` | Stage A `case_001` ("The jars from Guangzhou") evidence plate (2:1): opened forward-row jar (30 blue-and-white bowls in straw, 2 chipped) vs. opened after-row jar (8 bowls over straw mat and ~18 kati whole nutmegs). |
| `assets/art/inspection/inspection_desk_bg.png` | `1024×640` | Top-down/angled teak customs table with brass *dacing* steelyard, bamboo reed pen, inkpot, and woven mat. |
| `assets/art/inspection/manifest_scroll.png` | `384×512` | Aged rag-paper manifest parchment with hand-ruled ink columns and Malay geometric border. |
| `assets/art/inspection/seal_wax_intact.png` | `96×96` | Intact cinnabar lac/wax merchant seal with raised maritime emblem. |
| `assets/art/inspection/seal_wax_broken.png` | `96×96` | Cracked and partially re-melted cinnabar wax seal for fraud/tampering deduction. |
| `assets/art/ui/panel_parchment.png` | `256×256` | 9-slice-ready warm vellum panel with double sepia-ink and brass corner rules. |
| `assets/art/ui/banner_header.png` | `640×80` | Teak-and-brass harbour header ribbon with subtle woven trim. |

---

## 7. Future Asset Guidelines (Stages B–E)

To keep all upcoming assets cohesive as the project expands beyond Stage A:

### 7.1 Seals & Impressions (`96×96` inspection / `48×48` manifest)
- **Historical Separation (per `docs/research/seals-marks-packaging.md`):** Keep royal/diplomatic seals (such as Ming silver seals), official document stamps (lampblack/ink impressions like later regional Malay permits), and physical cargo closures visually distinct. Do not reuse one matrix across all three roles or place Ming diplomatic insignia on merchant cargo.
- **Materials:** Lampblack/soot ink and vermilion ink stamps for documents; cinnabar lac/wax (`#A8322D`), dark beeswax (`#7A542E`), or unfired river clay (`#9C7A5B`) for optional physical closures.
- **State Variants:** Every seal family should ship in at least 3 readable states: **Intact** (clean rim, crisp relief), **Damaged/Weathered** (chipped edge, still legible—innocent transit wear), and **Tampered/Forged** (hairline re-melt seam, mismatched emblem symmetry, or double-struck impression).
- **Legibility:** Keep inner motifs bold (max 3–4 geometric/botanical/maritime shapes) so players can compare them directly against Reference Manual drawings.

### 7.2 Merchant Marks (`64×64` monochrome ink, transparent background)
- **Visual Language:** Brushed in sepia ink (`#2A1E17`) or charcoal (`#332A24`) onto ceramic bases (following the Song-era Nanhai I precedent), incised/stamped on stoneware jar shoulders (following the Santa Cruz wreck), or stenciled onto cargo sacks and manifests.
- **Deduction Design:** Built from distinct, memorable primitives (diamond, trident/anchor, crescent, twin-wave, trefoil, cross-bar) with 1-stroke variations for forged lookalikes. Associate marks with fictional trading houses/partnerships in the manual, never as "official national standards."

### 7.3 Knots & Cordage (`128×128` close-up)
- **Materials:** Natural hemp (`#C8B088`), dark coconut coir (`#7D5C3B`), and split rattan strips (`#B89458`).
- **Clarity Rule:** Always draw clear shadows where one strand passes *under* another. Maintain 3–5 visually unmistakable knot families (e.g., flat reef binding, clove hitch, spiral lashing, double-loop slip) plus a messy/frayed "re-tied in transit" variant.

### 7.4 Porcelain Jars & Bowls (`256×256` inspection layers)
- **Nested Inspection Architecture:** Separate exterior container (`jar_body`, `jar_lid`, `cord_wrap`, `seal`) from interior layers (`straw_packing`, `nested_bowls`, `hidden_contraband`) so the Programmer can compose multi-layer reveals dynamically.
- **Ceramics Palette:** Brown/olive iron-glazed Martaban stoneware (`#5C3F28` / `#7C5A38`) contrasted against bright Ming cobalt (`#254C8A`) on warm off-white glaze (`#F5F2EA`), plus celadon jade-green (`#8FA895`) for grade differentiation.

### 7.5 UI & Reference Manual
- **9-Slice Panels:** Use `panel_parchment.png` (24px margins) for ledgers, tooltips, and dialogs; reserve dark teak (`#3B261A`) with brass trim (`#C49A45`) for primary headers and active tabs.
- **Reference Manual Pages:** Styled as an open two-page merchant handbook—left page holds hand-inked diagrams (ships, knots, seals, jars), right page holds concise notes.
- **Accessibility:** Never rely on color alone for status; pair Jade/Ochre/Cinnabar with clear iconography or text labels, and keep body text contrast ≥ 7:1 (`#2A1E17` on `#F7F0DF`).

### 7.6 Character Portraits (`256×256` transparent RGBA PNG bust)
- **File Convention:** `assets/art/portraits/<id>.png` matching the snake_case `id` in `data/deputies/<id>.json`, `data/merchants/<id>.json`, and `data/characters/<id>.json` (transparent background — the game draws the card frame).
- **Framing & Lighting:** 3/4 bust portrait flush to bottom edge, eye-line at upper third, warm key light from top-left, sepia ink contours matching the harbour and inspection style.
- **Cultural & Period Diversity (c. 1500 Melaka):**
  - **Malay Port Officials (*Syahbandar*, clerks):** Woven *songket*/silk *baju*, *tengkolok*/*destar* headwear, restrained gold/indigo/maroon accents.
  - **Javanese *Nakhoda* (Captains):** Batik *kain*, headcloth (*ikat kepala*), weathered maritime complexion.
  - **Chinese Junk Masters (Fujian/Cantonese):** Ming-era cross-collar *hanfu*/merchant tunic, cloth cap, muted indigo/umber/ochre tones.
  - **Gujarati & Tamil Merchants:** Draped cotton *dhoti*/tunic, neatly wrapped turban (*pagri*), gold/brass signet ring.
  - **Arab & Persian Traders:** Layered robe (*thawb*/*jubbah*), wrapped turban, trimmed beard.
- **Expression Set:** 3 core expressions per recurring NPC (`neutral`, `guarded/evasive`, `pleased/cooperative`) achieved via brow/eye/mouth swaps on a shared base portrait.
