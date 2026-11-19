# PORT MASTER: MELAKA 1511

**Ideal Gameplay Vision — Game Design & Architecture Blueprint**  
**Concept Document v0.5 | 19 November 2026 | Vision-level, not an implementation specification**

> **Design premise:** A single-player historical strategy game set in Melaka around the turn of the sixteenth century, combining real-time port operations, tactile cargo deduction, cross-cultural commerce, merchant relationships, and political crisis.

## Executive Vision

The player is more than a customs inspector: they manage an international trading port that keeps operating even when their attention is elsewhere. While the player personally investigates a suspicious shipment, other vessels unload, merchants negotiate, the anchorage becomes congested, and distant powers reshape regional trade. Decisions affect port revenues, food supplies, merchant trust, and Melaka's future.

**Core player fantasy:** *I maintain order in one of the world's great trading hubs, but cannot control every merchant or ship. I must investigate, delegate, negotiate, invest, prioritize, and live with the consequences.*

## 01. Design Pillars

1. **Living Port.** Ships, merchants, workers, cargo, and information move autonomously. The world does not freeze whenever the player opens an interface.
2. **Meaningful Prioritization.** Time, berths, staff, warehouse space, and treasury funds are scarce. Losing a ship means losing real trade, tax income, supply, or future relationships.
3. **Tactile Deduction.** Players compare cargo manifests, a reference manual, physical seals, knots, packaging, weights, and contents. There is no one-click reveal of the correct answer.
4. **Trade as Relationships.** Merchants have needs, credit, preferences, alliances, and rivalries. Information and trust change commercial outcomes.
5. **Historical Arc.** A prosperous maritime entrepôt gradually faces external competition, political tensions, and the upheaval of 1511.

## 02. Player Role, Authority, and Limits

The ideal player character is a senior official or administrator acting on behalf of Melaka's port authorities, with discretion over berthing priorities, inspection, port resources, state purchasing, and some commercial policy. The player is **not an omnipotent ruler**. The precise historical title and extent of this authority require research.

**Direct player control:** berthing priorities, inspection depth, important rulings, state purchases, delegation, infrastructure investment, relationship-building, and intelligence actions.

**Outside direct player control:** merchants' demands, overseas supply, every market price, ship arrival schedules, foreign government decisions, and broader historical forces.

## 03. Complete Day–Night Core Loop

| Phase | Player activity | World/system response |
|---|---|---|
| Morning briefing | Review yesterday's revenue, inventories, food supply, outstanding vessels, merchant intelligence, and daily risks; set priorities | Establishes today's market conditions, arrivals, and ongoing issues |
| Harbour opens | Watch vessels arrive at the anchorage; choose berthing order and assign staff | Ships wait, berth, reconsider their plans, or depart |
| Inspection and clearance | Skip, conduct basic inspection, delegate, or personally investigate cargo in detail | Discoveries, errors, fraud, and story clues affect clearance and trust |
| Royal first purchase | Decide whether the state buys some or all available goods before market release | Treasury and state warehouse change; remaining goods enter commerce |
| Trade and operations | Intervene in exceptional deals and policy decisions; supervise rather than micromanage routine operations | Merchants trade, goods move, taxes accrue, staff complete work |
| End-of-day settlement | Review revenue, shortages, backlogs, departed ships, and consequences | Updates the port's economic and relationship state |
| Evening strategy | Socialize, gather intelligence, negotiate, recruit, and plan investments | Creates opportunities, warnings, and constraints for later days |

**Loop:** Evening decisions inform the next morning; unresolved ships and commercial consequences persist across days.

## 04. Time Model and Player Rhythm

**Current leading exploration:** **Real-time Working Day + more deliberate Evening Planning**. During operating hours, port time advances while the player reads manifests, consults the manual, inspects objects, and speaks to people. Other operations continue in parallel. Players can pause the game for real-life interruptions; exactly what may be reviewed or commanded while paused remains to be tested.

**Progressive complexity:** Early days feature fewer vessels, commodities, and rules. Later days introduce more traffic, merchant marks, seals, quality disputes, conflicting testimony, and smuggling clues. Skill growth comes substantially from the player's own familiarity and efficiency, not just character upgrades.

**Important unresolved change:** The earlier baseline assigned **15 in-game minutes to Basic Inspection and 45 minutes to Detailed Inspection**. Under a fully real-time model, detailed inspection may instead consume the time the player actually spends interacting. These two approaches are **alternatives**, not approved costs to stack together.

## 05. Harbour Operations: Berths, Anchorage, and Lost Trade

- **Berths:** scarce positions for ships to dock, undergo relevant processing, and unload.
- **Anchorage:** a buffer where vessels wait for a berth; not an unlimited second set of fully operational trading berths.
- **Berthing priority:** the player can favor urgent food supplies, valuable cargo, important relationships, suspicious ships, or strategically significant trade.
- **End-of-day outcomes:** unfinished vessels may remain, reduce their business, shift trading plans, or depart. Departure is possible, **not automatic**.
- **Meaningful loss:** a Lost Ship or Lost Deal must hurt Melaka itself through foregone taxes, missing goods, lost state-purchase opportunities, weaker merchant trust, or lower likelihood of future visits. A merchant losing a deal while identical trade still occurs locally is not a meaningful port-level penalty.
- **Progression:** berth expansion, unloading improvements, anchorage management, and staffing increase effective capacity.

Specific berth counts, day length, arrival rates, waiting thresholds, and departure probabilities are **playtest variables**, not final numbers.

## 06. Inspection: The Hands-On Core

| Depth | Player interaction | Main benefit and trade-off |
|---|---|---|
| **Skip** | Clear the vessel without additional physical checking | Fast, but may miss faults and intelligence |
| **Basic** | Simplified inspection, personally or by an eligible staff member | Detects routine quantity/quality discrepancies while consuming work capacity |
| **Detailed** | Personally examine papers, packaging, marks, seals, knots, weights, contents, and testimony | Enables deeper deduction, major discoveries, and character encounters at a greater time/attention cost |

### Detailed Inspection Flow

1. **Read the manifest:** vessel, captain, route/departure port, owners, cargo lots, declared quantity, grade, and value.
2. **Inspect the physical cargo:** exterior packaging, merchant marks, seals, knots, automatically presented external weights, visible condition, and contents where opened.
3. **Consult the reference manual independently:** identify relevant commercial conventions and compare them against physical evidence.
4. **Investigate discrepancies:** open containers, compare items, and question the captain, crew, or merchants.
5. **Make a ruling:** clear, correct a declaration, request clarification, hold goods, or trigger a special investigation.

**Approved deduction rule:** The manifest is a **declaration**, not an answer key. It must **not** directly display the correct expected seal, merchant mark, knot, or packaging. The player derives expectations from the reference manual and compares them to the actual cargo. A mismatch is a clue, **not automatic proof of guilt**.

**Hidden truth:** Ship and cargo states are determined when the vessel is generated—not invented in response to the player's choice to inspect. Candidate states include **Clean**, **Minor Fault**, **Major Fraud**, and **Story Event**. Discovery depends on depth of inspection and player reasoning. Multi-lot and overlapping states may come later.

**Narrative payoff:** Investigations can uncover people, trade networks, black markets, diplomatic tensions, and historical stories—not only fines. Major cases must remain uncommon enough to preserve uncertainty.

## 07. Trade and Economy

### Royal First Purchase — Approved Gameplay Rule

Before goods enter the open market, the state may purchase **any commodity in any quantity at the normal market price**, constrained in practice by available treasury funds and state warehouse capacity. Uninspected goods use the **declared grade** for pricing; inspected goods use the **verified grade**. Purchased goods enter the State Warehouse and may later be reserved or resold to guilds and departing vessels.

This is an intentional **gameplay abstraction**, **not** a verified historical claim that Melaka operated an unlimited, market-price royal purchasing system.

### Market Dynamics

Supply arrives through ships and regional networks; demand comes from merchants and communities. Prices and availability respond to incoming cargo, reserves, policies, events, and distant trade routes. Transactions may involve currency, direct barter, brokerage, or multi-party exchange; **not all historical trade should be modeled as barter**.

### Initial Commodity Set

**13 commodities:** Tin, Rice, Timber, Iron, Copper, Nutmeg, Pepper, Sandalwood, Frankincense, Silk, Cloth, Porcelain, Glassware.

| Initial gameplay network | Illustrative goods |
|---|---|
| Java | Rice, timber, nutmeg, sandalwood |
| China | Copper, silk, porcelain |
| India | Iron, pepper, cloth |
| Middle East | Frankincense, glassware |
| Melaka and surrounding region | Tin |

These are **playability-oriented categories**; origins, routes, supply proportions, and historical accuracy require further research. China is **not** designated as a regular iron supplier in this model.

**Porcelain scope:** large porcelain jars and small porcelain bowls belong to the same commodity category. A large jar may contain bowls or other goods, and detailed inspection may reveal its contents. Do not invent standardized national seals or packaging conventions and present them as documented historical facts.

## 08. Autonomous NPCs and Merchants

Each vessel has a captain, cargo owners, cargo lots, route, commercial intent, waiting disposition, risks, and hidden information. Merchants pursue their own interests: buying, selling, bartering, leaving, rerouting, and building relationships. The player cannot dictate every outcome through dialogue choices.

Potential later actors include merchant guilds, brokers, interpreters, port workers, foreign envoys, and local political groups. Language differences can affect communication cost, misunderstanding, and intelligence reliability. Dedicated language-decoding minigames remain **exploratory backlog**, not an approved core mechanic.

## 09. Evening: Social, Intelligence, and Strategy

Evening is not a second shift of tedious paperwork. It offers a limited number of meaningful social or political actions that shape future days.

Examples: ask a captain about the provenance of a shipment; negotiate with a guild; recruit a trustworthy inspector; invest in a wharf; investigate a rumor; or prepare for rising Portuguese pressure.

Intelligence has a **source, reliability, and incentive structure**. A smuggling rumor may correctly identify tomorrow's high-risk ship—or be planted by a rival. Social actions must affect gameplay decisions, not merely increment an affinity meter.

## 10. Long-Term Progression, Events, and 1511

| Stage | Ideal experience |
|---|---|
| **Early game** | Learn basic harbour order, simple cargo verification, initial trade, and merchant relationships |
| **Mid game** | Manage rising traffic, more commodities, merchant networks, market volatility, and smuggling; use delegation, infrastructure, intelligence, and selective detailed inspection |
| **Late game** | Navigate guild interests, regional supply shocks, diplomatic tensions, and mounting Portuguese military pressure |

The Portuguese conquest of Melaka in **1511** may form the historical climax. Whether the player can change the outcome, experience multiple endings, or continue after conquest is **unresolved**. The ideal design should avoid reducing the whole game to a passive, inevitable Game Over countdown. Earlier commercial and political choices should matter in the finale.

## 11. Conceptual System Architecture

| Module | Responsibility | Inputs / outputs |
|---|---|---|
| **World Clock & Scheduler** | Working-day time, background jobs, event queue | Player and NPC actions → time advancement and completion events |
| **Ship & Cargo Generator** | Vessels, lots, owners, hidden truth | Trade networks and narrative seeds → arriving entities |
| **Harbour Capacity & Queue** | Berths, anchorage, waiting, departures | Arrivals and priorities → docking and lost-business outcomes |
| **Inspection & Evidence** | Manifests, physical evidence, manual, rulings | Cargo truth and player actions → findings and decisions |
| **Trade & Market Simulation** | Supply, demand, prices, barter, transactions | Cargo and merchant needs → trades, inventories, taxes |
| **State Treasury & Warehouse** | Purchases, reserves, spending, capacity | State decisions → balances and available goods |
| **NPC, Relations & Intelligence** | Merchant agency, trust, rumors, social actions | World events and interactions → behavior and clues |
| **Progression & Historical Events** | Difficulty escalation, upgrades, geopolitical arc | Persistent state → new pressures, options, and endings |

**Architecture principles:** persistent world state; traceable identities for significant NPCs and cargo; concurrent background systems; explainable consequences in the daily report; minimal mandatory administrative clicking. No engine, database, or programming language is prescribed at this vision stage.

## 12. Ideal Player Journey: One Working Day

A morning report warns of rising rice prices. The player gives a Javanese rice vessel berthing priority to protect food supply. A porcelain ship waits nearby; the previous evening, a contact suggested its owner might be concealing undeclared cargo. The player boards it for a **Detailed Inspection**. A discrepancy between the manifest, a jar's seal, and the reference manual prompts a closer look. Opening the jar reveals additional goods, and the captain's account conflicts with a crew member's testimony.

Meanwhile, staff finish a **Basic Inspection** of the rice shipment. Before the rice reaches the market, the player purchases part of it at the market price for state reserves. By afternoon the anchorage is crowded. Another high-value vessel cannot obtain a berth and may take its business elsewhere. At settlement, the player sees both the benefit of securing rice and the cost of spending too long on a single investigation. That evening, they must choose between recruiting staff, expanding capacity, and pursuing a new intelligence lead.

*This is an aspirational gameplay scenario, not implemented content or a promise that all such events occur in one day.*

## 13. Development Blueprint: From Vision to Playable Game

| Stage | Scope | Exit criterion |
|---|---|---|
| **A — Core Fun Prototype** | One port day, illustrative two berths, limited anchorage, several ships, a simple manual, one genuinely deductive Detailed Inspection case | Players face a real trade-off and find inspection intrinsically engaging |
| **B — Vertical Slice** | Several linked days, basic delegation, state purchasing, taxes, end-of-day departures, one or two evening intelligence events | Day and night influence each other; losing ships has economic consequences |
| **C — Living Economy** | Autonomous merchant demand, exchange networks, inventory flow, price and supply effects, improved staffing | Port economy responds coherently without constant manual intervention |
| **D — Narrative and Political Layer** | Persistent characters, guilds, diplomatic tensions, historical event chains | Relationships and politics meaningfully alter operations and outcomes |
| **E — Full Vision and Polish** | Richer inspection cases, progression, balancing, usability, historical finale, replayability | Systems remain understandable, consequential, and enjoyable across a full campaign |

**Development rule:** Validate the core fun before building a huge economic or diplomatic simulation. At each stage assess cognitive load, player agency, explainability, repetition, and replay value.

## 14. Design Decision Register

| Decision | Status | Notes |
|---|---|---|
| Manifest does not provide correct seals or marks | **APPROVED** | Player deduces them from reference manual and physical cargo |
| Royal first purchase: any goods, any quantity, market price | **APPROVED** | Practically limited by treasury and storage |
| Physical cargo can contain nested porcelain items | **APPROVED DIRECTION** | Jars may contain bowls or other inspectable contents |
| Port management rather than inspection-only simulation | **CORE DIRECTION** | Consequences must affect the port as a whole |
| Personally performed Detailed Inspection as a deduction experience | **CORE DIRECTION** | Evidence and dialogue, not automatic revelation |
| Real-time working day | **LEADING PROPOSAL** | Preferred for testing, not final approval |
| Real-time inspection duration replacing fixed 45 minutes | **LEADING PROPOSAL** | Earlier 15/45-minute model remains an alternative |
| Player-selected berthing and anchorage buffer | **STRONG PROPOSAL** | Capacity and queue behavior require testing |
| End-of-day possibility of merchant departure | **STRONG PROPOSAL** | Not all waiting ships automatically leave |
| Evening intelligence and relationships | **CORE DIRECTION** | Action economy and detailed mechanics unresolved |
| Language decoding, weighing puzzles, other special minigames | **EXPLORATORY BACKLOG** | Not adopted into the baseline |

## 15. High-Impact Open Questions

1. What is the real-time clock scale, operating-day duration, pause policy, and precise relationship between player action and inspection time?
2. How do inspection, docking, unloading, and berth occupation overlap? Can ships be pre-screened or merchants contacted while at anchor?
3. What meaningfully distinguishes personally performed Basic Inspection from staff delegation? How do staff skill, error rates, and wages work?
4. How predictable should merchant departure at day-end be? What exceptions prevent implausibly impatient ocean-going traders?
5. What is the smallest enjoyable model of prices, barter, taxation, cargo grades, and state reserves?
6. How can the player's rulings and powers remain historically plausible, and which mechanics should be explicitly identified as abstractions?
7. Is the outcome of 1511 fixed, alterable, or branching? How can player agency coexist with historical weight?
8. How do we ensure Detailed Inspection remains worth doing instead of becoming a trap that players always skip for throughput?

## North Star

**Every working day should present at least one problem worth investigating personally and at least one choice that affects the entire port.** The world must respond visibly to player decisions. The impossibility of doing everything is not a flaw—it is the source of the game's strategic tension.

---

*Document status: Vision blueprint. “Approved” applies only to specifically established gameplay decisions; all other examples, values, and system behaviors remain subject to research, design review, and playtesting.*
