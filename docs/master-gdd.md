# PORT MASTER: MELAKA 1511 — Master Game Design Document

**Full-game vision and gameplay architecture | v0.6 consolidation | 27 November 2026**

> English reference for designers and AI agents. Discuss the project with the owner in Hong Kong Traditional Chinese / Cantonese. This is an ideal-game design, not a claim of implementation. Approved decisions must be preserved; proposals require owner review. The separate clean-slate Melaka concept exploration is outside scope.

## 0. Executive summary — non-negotiable design context

- The player administers the state port on behalf of the Melaka Sultanate, not a private merchant business and not an unrestricted ruler.
- Four persistent overseas commercial networks: Java, China, India and Middle East. Local Melaka supply is not a fifth overseas faction. Each network has merchants, independent stock, purchasing needs, commercial relationships and potential political support.
- Exactly 13 regular commodities. China supplies copper, India supplies iron, Java supplies rice and timber. Tin is local. Bronze is not an inventory commodity; gunpowder is special Story Cargo.
- Tin is both money and physical metal. One tin coin is the accounting unit; coins may be converted into trade ingots, subject to a yet-to-be-defined conversion model.
- Ships sell inbound goods AND buy outbound goods. Ships, merchants, cargo ownership and physical location are separate persistent entities.
- Royal First Purchase: the state can purchase any quantity of any available inbound commodity at normal market price before market release, subject to funds and storage. No mandatory discount.
- Guild-to-ship commerce runs autonomously. State inventory is not the entire city's inventory. Tax revenue is not equivalent to merchant turnover.
- Detailed inspection is a personal evidence-based interaction. The manifest is not an answer key; the player independently consults a reference manual and examines physical cargo.
- Latest preferred time model: real-time working day, progressive inspection complexity, selectable berthing priority, anchorage buffer, and meaningful potential lost business at closing. Evening strategy is deliberate rather than time-pressured. Exact time scale and closing behavior remain to be reconciled with earlier soft closing.
- The long-term purpose is a prosperous, resilient trading city capable of confronting the political crisis of 1511. The exact ending structure is open.

Status vocabulary: **APPROVED** = explicit owner decision; **CORE** = established design direction; **PROPOSED** = candidate for review; **BACKLOG** = exploratory only. Numerical examples are illustrative, never historical statistics or approved balance.

# PART I — GAME VISION AND PLAYER EXPERIENCE

## 1. Setting and fantasy

Melaka is a cosmopolitan fifteenth-century maritime entrepot connecting regional and long-distance trade. The campaign approaches the Portuguese conquest of 1511. The famous account of approximately 84 languages inspires multilingual interaction, not a literal census or a requirement for 84 skill trees. Regional tin access creates economic leverage; it is not evidence of a worldwide tin monopoly. Barter, monetary trade and brokerage coexist.

The player fantasy is to keep an international port functioning while making selective personal interventions. A suspicious jar, an urgent rice shipment, a lucrative export order and an intelligence lead can all compete for the same afternoon. The player must choose rather than complete every task. Prosperity is meaningful because it supports the state, its population and its political survival.

Design references: Papers, Please for progressive manual deduction; restaurant management for capacity and lost customers; Age of Empires for concurrent operations; Civilization for deliberate strategic allocation. Do not copy any one reference wholesale. No personal fatigue or identity-based dark-line mechanic is required; pressure comes from the port and its consequences.

## 2. The Port Master and the Sultanate

| Actor | Owns / controls | Motivation and limits |
|---|---|---|
| Sultanate / court | State treasury, state stock, public infrastructure, strategic projects | Revenue, food security, legitimacy, diplomatic and defensive readiness |
| Port Master (player) | Delegated decisions on berthing, inspections, clearance, royal purchases, public investment, staff and relations | Stewardship of public assets; cannot command every merchant or foreign power |
| Four guilds | Private inventories, commercial capital, merchants and relationships | Profitable trade, reliable supplies, access and influence |
| Visiting ships / cargo owners | Vessel capacity, onboard cargo, procurement needs, departure plans | Sell, buy, provision, repair and leave profitably |
| Local suppliers and workers | Local production and operational services | Supply tin, labor and services; not a fifth overseas guild |

The precise historical office/title and legal authority require research. The player may influence policy, diplomacy and defense through delegated authority and court requests; this does not imply absolute sovereignty. No personal wallet is needed in the baseline. State money pays public costs and purchases; private transactions do not automatically enrich the treasury except through applicable dues. Court satisfaction, public food availability, guild relations, throughput and readiness should matter alongside treasury balance (exact metrics proposed).

Example: buying rice may reduce cash today but protect supply and political stability; selling all copper may generate cash but remove material needed for a future state project. The state may decline a profitable purchase to preserve liquidity. The player is not rewarded merely for maximizing resale profit.

## 3. Four persistent merchant networks

These are simplified commercial networks, not exclusive ethnic identities, precise historical national borders or a one-to-one Shahbandar mapping. Goods may originate elsewhere and travel through a network.

| Network | Regular supply (approved model) | Proposed commercial identity | Tentative special story opportunity |
|---|---|---|---|
| Java | Rice, timber, nutmeg, sandalwood | Frequent essential shipments, regional connections, food and construction leverage; may also bring large ships | Navigation, shipbuilding or maritime expertise; unique specialty OPEN |
| China | Copper, silk, porcelain | Seasonal valuable cargo, metal and luxury supply | Artillery expertise / gunpowder-related story cargo |
| India | Iron, pepper, cloth | Active textile and spice exchange, infrastructure material | Elephants or associated diplomatic opportunities |
| Middle East | Frankincense, glassware | Less frequent high-value arrivals, resident traders, westward information | Horses or associated diplomatic opportunities |

Frequency, ship size and unique story specialties are proposals, not fixed historical facts. Do not equalize item counts simply for symmetry. Java's importance comes from essentials; Middle East can matter through valuable orders, resident commerce and information despite fewer arrivals.

**All four networks can recruit people, provide intelligence, offer political support, financing or map access.** No exclusive recruitment faction. Individual merchants can disagree with their guild's leadership. Relationships should affect willingness to trade, reliability of information, access to opportunities and reactions to detention; exact modifiers are open. Guilds persist even when no corresponding ship is in port.

## 4. Complete day–night loop

Morning briefing (deliberate) -> open port (real-time) -> arrivals and berthing -> inspection/clearance -> royal purchase window -> unloading and autonomous market trade -> outbound procurement/loading -> departure clearance -> closing and settlement -> evening social/strategic actions -> next day.

These are overlapping processes, not a mandatory sequential wizard for the whole port. While one ship is being inspected, another may unload and a third may negotiate an outbound purchase. Morning reports show stock, cash, ships already waiting, food risk, outstanding projects and intelligence. Evening visits to guild quarters can unlock information, recruits, negotiations and political opportunities. Investment and strategic planning can be performed without the same pressure as daytime inspection (proposed).

### Time design and closing

Earlier model: Skip 0, Basic 15, Detailed 45 game minutes. Latest leading proposal replaces personal detailed inspection's fixed cost with actual player interaction time. Do not stack both costs by default. Staff tasks can still have scheduled durations. Real-time reading, manual lookup and questioning are intentional skill challenges, not automatically exempt from time pressure. Early days introduce few ships and few rules; later days increase complexity. Pause for real-life interruptions is desirable; whether strategic commands or evidence review are allowed while paused is open.

Earlier owner-approved soft closing: approximately 18:00, no new work, finish active work. Latest proposal: evaluate unresolved waiting vessels at end of operations; some stay, others leave or reduce trade. These can coexist, but exact cutoff, completion rules and departure timing need review. Do not silently replace soft closing with instant cancellation. No approved universal 60–150 minute patience threshold. A ship that traveled for months should not appear implausibly impatient without a clear gameplay abstraction or reason.

# PART II — ECONOMY, OWNERSHIP AND TRADE

## 5. Regular commodity catalogue

| Commodity | Regular supply network | Proposed demand networks | Gameplay function |
|---|---|---|---|
| Tin ingots | Local | Java, China, India, Middle East | Export metal, currency relationship, strategic projects |
| Rice | Java | India, Middle East | Food; sole regular commodity directly affecting food metric |
| Timber | Java | China, India, Middle East | Construction, repairs |
| Iron | India | Java, China, Middle East | Tools, infrastructure, defense projects |
| Copper | China | India, Java, Middle East | Metal goods, trade, bronze projects |
| Nutmeg | Java | China, India, Middle East | Spice/luxury |
| Pepper | India | China, Middle East | Spice |
| Sandalwood | Java | China, India, Middle East | Aromatics |
| Frankincense | Middle East | India, China, Java | Aromatics, ritual use |
| Silk | China | India, Middle East, Java | Clothing/luxury |
| Cloth (textiles) | India | Java, China, Middle East | Clothing/luxury |
| Porcelain | China | India, Middle East, Java | Vessels/display |
| Glassware | Middle East | India, China, Java | Vessels/display |

Supply mapping is a deliberate gameplay abstraction. Demand columns are provisional balancing proposals. Keep tin first in commodity tables; glassware replaces rosewater. Do not add pottery as a regular commodity merely to represent porcelain containers. Large porcelain jars and small porcelain bowls belong to the same category; a jar may contain bowls or other cargo. Distinguish packaging from commodity quantity.

### Partial substitution markets

Silk ↔ cloth; pepper ↔ nutmeg; sandalwood ↔ frankincense; porcelain ↔ glassware. A general category order may accept either; a preferred-item order may accept a substitute with reduced satisfaction/value; an exact-item order cannot. These are proposed demand rules, not fixed equivalence ratios. A substitute does not become the same physical commodity. This creates competition between networks without making their supply identical. Prevent endless arbitrage by finite demand and coherent pricing.

## 6. Inventory architecture — ownership is not location

| Inventory / ledger | Owner | Purpose | Capacity |
|---|---|---|---|
| State treasury | Sultanate | Tin coin balance, taxes, wages, purchases | Financial balance, not warehouse slots |
| State warehouse | Sultanate | Purchased goods, reserves, project materials, resale stock | Finite, expandable |
| Guild warehouses | Individual guilds / merchants | Private goods available for sale, reserved orders | Separate from state capacity; exact private limits open |
| Ship cargo hold | Cargo owners aboard vessel | Inbound, transit and outbound cargo | Vessel capacity |
| Pending transfer / reserved goods | Existing owner until agreed settlement | Goods committed to loading, unloading or delivery | Must not be available for a second sale |

The final row is a proposed accounting implementation, not an additional physical warehouse. A lot has commodity, quantity, grade, owner, location, reservation status and provenance where relevant. A purchase and physical delivery may occur at different times. The earlier playtest explicitly included royal-purchased cargo awaiting operations. The UI must distinguish bought stock from stock physically available for use. Reserve warehouse capacity when committing a purchase or define a clear overflow rule; do not allow silent duplication.

Example: a Chinese vessel unloads 20 porcelain units. The state buys 5, the Chinese guild acquires or retains 15. Only the 5 state units consume state capacity. An Indian ship later purchases 8 from the guild; those units move to its hold after loading. The remaining 7 guild units stay in Melaka even after both ships depart. The state still owns its 5. No stock is created merely by changing ownership.

State stock can be reserved for public consumption, sold to a guild, sold directly to an outgoing ship, or consumed by a project. Exact spoilage, private warehouse capacity, local distribution and storage-unit weighting are open. Rice availability in the private market should not be confused with state rice reserves. An illustrative city food metric may depend on accessible supply, not simply state ownership; formula needs approval.

## 7. Tin coin and physical tin economy

**Approved:** one tin coin is one game currency unit; physical tin ingots are export goods; coins can be melted into recoverable metal. Tin is not two unrelated magical resources. The state can use its tin advantage to obtain foreign goods, including barter.

**Open:** coin mass, ingot mass, conversion ratio, labor cost, loss, whether conversion is manual or automatic, and how local tin production reaches the state versus private sellers. Earlier illustrative 100 coins per ingot is NOT approved and is not a historical weight equivalence. A conversion must debit the source balance and credit only the recovered metal. Do not count the same tin as both spendable cash and inventory. Bronze is not reversibly convertible into its original metals by simple remelting.

Example: a Chinese merchant wants tin ingots and offers porcelain. The state can transfer existing ingots or convert coin-equivalent metal if permitted, receive porcelain into available storage and decide whether to reserve or resell it. The transaction uses market valuations to show opportunity cost, even when no cash changes hands. A merchant's demand is finite. Conversion costs and price spreads must prevent infinite coin/ingot arbitrage.

## 8. Buying, selling and delivery

### 8.1 Royal First Purchase (APPROVED)

Before available inbound goods enter the open market, the state may purchase ANY commodity, ANY quantity at NORMAL MARKET PRICE. Practical limits are available quantity, treasury and state warehouse capacity. If uninspected, use declared grade; if inspected, use verified grade. This is a deliberate game abstraction, not a historical claim of compulsory unlimited royal purchase. No automatic 25% discount. Transit goods and disputed ownership need a clear eligibility rule (open).

Player selects cargo lot and quantity, sees price, total, remaining treasury and storage impact, confirms or declines. Goods not purchased proceed to private commerce. Proposed operational sequence: reserve funds and capacity, settle ownership, schedule delivery, mark goods available when delivered. Exact payment timing open. The state may buy for supply security rather than profit.

### 8.2 Autonomous private trade

Guilds sell inbound stock to other guilds, resident merchants and outbound ships according to their needs, price limits and available stock. The player does not need to click approval for every deal. A ship may buy directly from a guild without the state buying first. NPC trade creates real port activity and applicable revenue but does not transfer the entire sale price to the treasury.

Proposed matching logic: evaluate exact or substitute demand, available unreserved stock, price, buyer budget, relationship and delivery feasibility; reserve accepted quantity; settle and load/deliver; update demand. Partial fulfillment is allowed. If no deal is available, the buyer can wait, negotiate, substitute or leave. Exact AI priority, negotiation model and update frequency are open.

### 8.3 State resale and barter

The player can sell a chosen quantity of available state stock directly to an outgoing vessel or guild. Display buyer demand, offered price, grade, quantity, revenue and remaining reserves. State resale may compete with private sellers; markup is a possible pricing strategy, not guaranteed profit. Barter exchanges goods against goods, including tin; show both valuations and any cash difference if supported. Multi-party exchange and credit are possible later extensions, not mandatory baseline features.

### 8.4 Transaction matrix

| Transaction | Goods flow | Money flow |
|---|---|---|
| Royal purchase | Inbound owner -> state warehouse | State -> seller |
| Private inbound sale | Ship owner -> guild / private buyer | Private buyer -> seller |
| Guild resale/export | Guild -> another guild or ship | Buyer -> guild |
| State resale/export | State warehouse -> guild or ship | Buyer -> treasury |
| Barter | Both parties exchange specified goods | None unless agreed balancing payment |
| Public project | State stock -> consumed materials | Treasury -> labor/services if required |

Taxes and service fees are separate ledger entries. Never treat private sale proceeds as state revenue. A transaction must not produce negative cash, duplicate cargo or exceed capacity. Proposed failure behavior: reject invalid quantities or clearly report partial fulfillment, without silent stock loss.

## 9. Market prices, grades, taxes and public finance

Prices should reflect commodity, grade, supply, demand and events. Declared and verified grade are distinct. The player should see why a price changed. No approved grade multiplier, dynamic price equation or exact tax rate. A useful candidate is a reference price adjusted by grade and market scarcity, bounded to avoid runaway oscillation. NPC offers may differ from reference price; Royal First Purchase uses normal market price, not a privileged discount.

Revenue: inbound customs, applicable outbound duties, port services, state sales and other approved income. Expenses: royal purchases, staff, maintenance, construction, projects and diplomacy. Avoid double-charging an import duty merely because goods change private owners. Distinguish import clearance, service fees and export clearance. Tax exemptions and network-specific rates require historical and gameplay review.

Illustrative ledger (not balance): opening 1,000 coins + 40 customs + 10 services - 200 royal purchase + 90 state resale - 30 wages/maintenance = 910 closing coins. A private 300-coin sale is not added to treasury. Goods bought but not sold remain assets, not cash. Daily report separates cash flow, stock changes and lost opportunities.

Historical prototype values (NOT approved): 5% baseline customs, possible rice exemption; illustrative 6% Middle East rate; berth maintenance 5/day, warehouse 3/day, worker 2/day, inspector 5/day, interpreter 6/day; berth expansion 800 plus timber/iron, warehouse expansion 400 plus timber. Earlier example two berths, one warehouse, six workers and one inspector costs 30/day. Earlier unit price candidates: rice 10, timber 15, iron 30, cloth 35, pepper 45, nutmeg 60, sandalwood 65, porcelain 75, silk 90, frankincense 85, glassware 100; copper and tin ingot pricing unsettled. Do not import these numbers as production defaults without simulation.

# PART III — SHIPS, OPERATIONS AND INSPECTION

## 10. Ship lifecycle and port capacity

Arrival -> waiting at anchorage -> player-selected berth -> arrival clearance -> unload/sell -> port stay and outbound procurement -> return to berth if necessary -> load -> departure clearance -> depart. A ship can overlap procurement and unloading. It need not buy every desired good before leaving. Transit cargo may stay aboard.

Berths are scarce work positions for inspection, loading, unloading and repair. Anchorage is a buffer, not an unlimited second port. Proposed architecture: distinguish initial waiting ships from cleared ships temporarily anchored while trading or awaiting sailing conditions; whether they share one capacity pool is open. Moving away from a berth frees it for another vessel. A ship may need to return for outbound loading. Total stay can exceed berth occupation substantially. Merchant residency can outlast the ship.

Player prioritizes by rice shortage, high-value trade, strategic materials, relationships, risk intelligence and departure urgency. Ships are not required to be processed FIFO. Staff and facilities can work concurrently. A full anchorage may cause a new arrival to bypass Melaka. At closing, unresolved ships may stay, leave or reduce business. Lost trade must affect Melaka through foregone taxes, supplies, procurement opportunities or future relationships; merely moving an identical local deal between merchants is not a meaningful loss.

Departure permit: review outgoing manifest, outstanding dues, loading status and suspicious cargo. Optional outbound inspection is distinct from arrival clearance. Arbitrary indefinite detention should damage trust and diplomacy. Exact legal powers and penalties open. Cleared ships may depart even with unfulfilled shopping lists.

Proposed compressed stay examples from earlier discussions: Java berth 1–2 days / total 1–4; India 2–4 / 4–12; China 3–5 / 7–20; Middle East 2–4 / 7–20 or seasonal. These predate the latest real-time model and must not be combined blindly with it. Actual historical stays could last months. Monsoon season can influence arrival and departure without requiring literal real-time months.

## 11. Inspection — personal skill and selective attention

| Depth | Interaction | Consequence |
|---|---|---|
| Skip | No extra physical check | Fast, risk of missed faults; routine clearance still applies |
| Basic | Simplified personal check or delegated staff task | Routine quantity/quality findings; consumes work capacity |
| Detailed | Personal hands-on evidence examination | Deeper fraud, story clues and character encounters; consumes player time |

Detailed inspection: read manifest (ship, captain, departure port, route, cargo owners, lots, quantity, grade, value); observe packaging, marks, seals, knots, external weights and condition; independently consult reference manual; open selected containers, compare contents, question people; rule on clearance, correction, clarification, hold or special investigation. Departure port is not necessarily origin of goods. Automatic outer package weight is an observation, not a verdict.

**Approved:** manifest must not provide the correct expected seal, knot, merchant mark or packaging. The player derives expectations from the manual. Discrepancy is evidence, not automatic guilt. Do not invent standardized national marks and label them historical. Packaging conventions require research; fictional merchant marks can be explicitly authored as game fiction.

Hidden truth should be generated before inspection (strong proposal): clean, minor fault, major fraud, story event; later multiple lots and overlapping conditions. Inspection does not create fraud when selected. Detailed inspection does not guarantee discovery. A correct ruling depends on player reasoning, not just choosing the expensive button. Staff reports should be understandable, with skill/error rules to be tested. Detailed delegation is not baseline.

Routine documents (arrival register, tax receipts, stock ledgers) should be automated. Evidence documents are a gameplay role, not a separate historical document class. Manifest becomes evidence when compared with physical cargo. Nested porcelain jars can conceal small bowls or other goods. Language Lab (contextual decoding, translation relay, whisper/contradiction) and tactile balance-scale limited-weighing puzzles remain BACKLOG; do not replace physical inspection without approval.

## 12. Staffing, construction and player attention

Proposed roles: workers for loading/unloading, inspectors for basic checks, interpreters for communication, administrative staff for routine records. All four networks may help recruit. Delegation frees player attention but still consumes staff time and potentially berth capacity. Staff should not teleport goods or complete jobs without resources. Wages and reliability matter. No requirement to personally approve every routine transaction.

Infrastructure candidates: additional berths, anchorage improvements, warehouse expansion, handling equipment/services, repairs and defense projects. Construction consumes treasury and appropriate stock and takes time (exact recipes/durations open). Capacity upgrades should reduce a real bottleneck rather than simply raise a score. More berths without enough staff may not improve throughput. Warehouse expansion enables reserves but costs money that could buy supplies.

# PART IV — POLITICS, NARRATIVE AND CAMPAIGN

## 13. Evening, guild relations and intelligence

Visit merchant quarters, speak with captains or resident traders, negotiate orders, recruit, seek political support, learn about trade routes and investigate rumors. Intelligence has source, reliability, motive and expiry (proposed). A rival may mislead the player. Night information can change next day's berth priority and inspection decisions. Evening actions should produce operational consequences rather than only affinity points. Exact action limits and whether language learning is a skill system remain open.

Court and guild requests may involve luxury deliveries, urgent supplies, favors or support. Competing requests create meaningful allocation choices. A guild relationship is not equivalent to every member's opinion. Multilingualism can affect access, interpretation and trust; dedicated minigames remain optional exploration.

## 14. Strategic materials and Story Cargo

Gunpowder is Story Cargo, not a fourteenth routine commodity. China is a plausible story channel but not the exclusive historical source of knowledge or supplies. Other special opportunities: horses (Middle East), elephants (India), artillery expertise (China), Java specialty unresolved. All are tentative narrative assignments, not monopolies. Maps, recruitment, intelligence and political support are available across networks.

Copper and tin may be consumed by bronze-related state defense projects; bronze is NOT tracked as standalone inventory. Iron supports other equipment and infrastructure. Example project categories: harbor defense, royal fleet readiness, guard equipment, fortification and repair. Materials, funding and expertise can be prerequisites. Exact costs, effects and combat representation remain open. A single rare purchase should not automatically win the historical crisis. No separate routine ingredients for gunpowder.

## 15. Campaign progression and 1511

Early: low traffic, simple manifests, learn basic trade and stock ownership. Mid: more vessels, grade disputes, competing orders, substitutions, congestion, delegation and infrastructure. Late: supply shocks, merchant politics, strategic procurement, diplomacy and Portuguese pressure. Player skill grows through recognition of familiar cargo and rules, not only character upgrades. Introduce complexity gradually rather than starting with all 13 goods and all inspection rules.

The historical conquest in 1511 is the anchor, not yet an approved fixed Game Over. Options for owner review: historically fixed outcome with variable preparedness/legacy; branching alternate-history outcomes; continuation after conquest. The player should see how prior economic, political and logistical choices matter. No final victory formula or campaign duration approved. Possible evaluation dimensions: public finances, food security, trade continuity, relationships, infrastructure, strategic readiness and historical consequences.

# PART V — CONCRETE PLAYER EXPERIENCE AND ARCHITECTURE

## 16. Illustrative multi-day gameplay scenario

Day 1 morning: rice shortage and limited treasury. Java rice/timber ship, China porcelain/copper ship and India cloth/iron ship approach. Player chooses Java first for public supply and delegates basic inspection. China is next because yesterday's rumor suggests undeclared cargo. India waits. Player personally checks a porcelain jar against manual and manifest; discovers an inconsistency and chooses whether to investigate further. Meanwhile Java unloads. State purchases some rice at normal market price; remaining rice enters private stock. State buys limited copper rather than all porcelain, preserving cash.

Afternoon: Indian vessel sells cloth and iron and wants porcelain and tin for export. It buys porcelain from the Chinese guild without state intermediation. The player offers state tin ingots in exchange for some cloth (if demand and stock allow). Goods are reserved, then physically loaded. China can move to anchorage while seeking outbound goods, freeing a berth. A later high-value arrival cannot be accommodated; at closing it may leave, causing foregone revenue and supply. Active work may finish under soft closing; exact rules pending.

Evening: the player sees cash flow, rice supply, state copper reserve, private inventory, waiting ships and lost business. Chooses whether to recruit an inspector, expand berth capacity or pursue the rumor. A resident Chinese merchant remains available even after the original ship departs. Day 2: Indian ship receives remaining purchases and requests departure clearance; it can leave with an incomplete shopping list. Private stock left behind remains in Melaka. Later the copper reserve supports a state project, demonstrating why the earlier purchase mattered.

This is a synthetic scenario, not a transcript of an approved playtest. No fixed quantities, taxes or timings are implied.

## 17. UI architecture (proposed)

- Harbour overview: clock, open/closing state, berths, anchorage, approaching ships, staff jobs, alerts, treasury and food summary. Select any eligible waiting ship.
- Ship detail: inbound cargo, procurement, departure readiness; owner and location visible, quantities and grade, waiting disposition, outstanding jobs.
- Inspection workspace: manifest, physical cargo, independent reference manual, observations, dialogue and ruling. Avoid showing hidden truth as UI hints.
- Royal purchase and state sales: quantity selector, unit price, total, cash and storage consequences, reservation/delivery status.
- Market/guild view: four networks, supply, demand, private stock visibility appropriate to player knowledge, orders and relationships. Separate state warehouse view with reserved/available stock.
- Evening map/quarters: characters, intelligence, negotiations, recruitment, projects and court requests.
- Daily settlement: revenue/expense breakdown, stock changes, completed and waiting vessels, lost trade reasons, pending transfers and consequences.

Whether inspection is a separate screen or persistent split view with live harbour status remains open. Avoid forcing player to monitor every notification while reading evidence. No final visual style or engine UI layout prescribed.

## 18. Conceptual system boundaries

| System | Responsibility | Key state |
|---|---|---|
| World clock/scheduler | Day phases, concurrent jobs, arrivals and completion events | Time, phase, job queue |
| Harbour | Berth/anchorage allocation, vessel transitions | Capacity, occupancy, waiting |
| Ship generator | Persistent ships, lots, owners, intent, hidden truth | Ship IDs, cargo IDs, arrival seed |
| Inspection | Evidence, manual, observations, rulings | Declared vs true vs observed data |
| Inventory | Ownership, location, quantities, reservations, delivery | Lots and capacity ledgers |
| Market | Offers, demand, prices, barter and autonomous matching | Orders, budgets, stock availability |
| State finance | Taxes, fees, purchases, sales, costs | Treasury and transaction ledger |
| Staff/projects | Delegation, construction, upkeep | Workers, jobs, materials |
| NPC/guild | Persistent people, relationships, motives, rumors | Merchant IDs, guild stock and relations |
| Campaign | Progression, historical events, outcomes | Event flags, public and strategic state |

Recommended engineering invariants (not implementation mandate): stable entity IDs; cargo owner and location separate; one authoritative transaction ledger; no negative quantities or duplicate reservations; deterministic event ordering; save/load preserves pending jobs and hidden truth; UI does not mutate economic state directly; reports explain changes. Real-time clock and economic simulation should be separable so balancing can run without rendering. Keep manual time stepping as a debug/test tool even if final gameplay is real-time.

## 19. Development roadmap — ideal vision is not MVP scope

1. Core fun: one working day, limited berths and anchorage, meaningful prioritization, one genuinely deductive inspection. Test real-time reading pressure and closing.
2. Operational vertical slice: concurrent staff jobs, royal purchases, delivery, treasury, state storage, meaningful lost trade, evening intelligence.
3. Living economy: four persistent guilds, all 13 commodities, inbound/outbound procurement, private trades, substitution, tin accounting and departure permits. Validate ownership and stock conservation.
4. Political layer: resident NPCs, relationships, recruitment, court requests, strategic projects and special cargo.
5. Campaign: progressive complexity, seasonal and historical pressures, 1511 outcomes, usability and balance.

Existing Godot experiment (reported in prior conversation): project.godot, harbour.tscn and harbour.gd for manual time stepping, ship arrivals, berth/anchorage scheduling and completion logs. Not runtime-verified in this consolidation. It is not the full game, nor proof that trade, inspection or politics are implemented. Earlier HTML playtest is design evidence, not production architecture. Do not overwrite existing repo or begin implementation without owner request.

### Acceptance tests for design validation

- A ship can sell and buy in the same visit; merchant and guild stock survive its departure.
- A private sale changes private ownership and applicable fees, not the full treasury balance.
- Royal purchase of a partial lot uses declared or verified grade correctly and respects cash/storage.
- Reserved cargo cannot be sold twice; a completed delivery changes location once.
- Coin-to-ingot conversion cannot duplicate money or metal.
- Player can inspect one vessel while delegated operations continue; lost business changes port-level outcomes.
- Manifest does not reveal expected physical marks; a clean ship remains clean regardless of inspection choice.
- A ship can leave with incomplete procurement; arbitrary detention has consequences.
- All four guilds remain meaningful even when arrival frequencies differ.
- Early-day rules are learnable; late-game delegation prevents click overload.

# PART VI — DECISION REGISTER AND RESEARCH

## 20. Status register

| Decision | Status |
|---|---|
| State port role, not private merchant; no personal fatigue/dark line | APPROVED / CORE |
| Four guild networks plus local supply; all guilds can recruit | APPROVED |
| 13 goods; Java timber/rice, China copper, India iron; glassware not rosewater | APPROVED |
| Rice sole routine food-metric commodity | APPROVED |
| Tin coin accounting and recoverable physical metal; tin ingot label | APPROVED |
| No bronze inventory; gunpowder Story Cargo | APPROVED |
| Inbound and outbound trade, meaningful departures | APPROVED / CORE |
| Royal First Purchase any available quantity at market price | APPROVED |
| Independent manual and physical evidence, no manifest answer key | APPROVED |
| Earlier soft closing, finish active work | APPROVED earlier; reconcile with latest timing |
| Real-time day, real-time detailed inspection, deliberate evening | LEADING PROPOSAL |
| Player-selected berths, anchorage buffer, end-of-day possible lost ships | STRONG PROPOSAL |
| Separate merchant/cargo/ship persistence, autonomous private trade | CORE architecture; exact state transitions proposed |
| Hidden cargo truth pre-generated | STRONG PROPOSAL |
| Demand matrix, partial substitution, prices, tax rates, wages | PROPOSED / balance open |
| Tin conversion UI and ratio, delivery settlement, private capacity | OPEN |
| Special faction story items, project recipes, 1511 endings | OPEN |
| Language Lab, weighing deduction minigame | BACKLOG |

## 21. Historical research guardrails

Historical starting points: Devinder Raj, *Where Eighty-Four Languages Were Once Spoken: An Account of Melaka 1400–1824* (2020); Yahaya Abu Bakar, *Foreign Documents and the Descriptions of Melaka Between A.D. 1505–1511*, UNESCO Silk Roads knowledge bank: https://zh.unesco.org/silkroad/sites/default/files/knowledge-bank-article/foreign_documents_and_the_descriptions_of_melaka_between_a.d._1505-1511_0.pdf . Prior discussions referenced these works; the full book was not established as accessible and neither source was freshly verified for this consolidation. Recheck primary passages before publishing exact tax rates, ship counts, coin weights, office powers, food exemptions, military shortages or packaging conventions. Distinguish historical observations, plausible extrapolation and authored game fiction. The four guilds, 13-item economy and Royal First Purchase are design abstractions.

## 22. Open questions prioritized

First: real-time clock scale, pause behavior, soft closing versus departure assessment, berth/anchorage capacity and concurrent job rules. Second: transaction settlement, delivery reservations, grade/price model, tax events, tin conversion, autonomous procurement and stock visibility. Third: court authority and satisfaction, guild relationship effects, staffing, strategic project costs and campaign outcome. Do not solve these by silently inventing final values.

## 23. Provenance and handover

Consolidates the earlier `PORT_MASTER_MELAKA_1511_Handover.md` (7 November 2026), `Port_Master_Melaka_1511_Ideal_Gameplay_Blueprint_EN.md` (19 November 2026), and subsequent discussion of real-time inspection, progressive complexity, berth selection, anchorage and day/night rhythm. The earlier handover preserves the economy and ship lifecycle that the shorter blueprint compressed. This document integrates them; it does not erase older unresolved alternatives. No repository inspection or new runtime validation was performed. New accounting invariants, UI details, examples and acceptance tests are recommendations for review, not owner approvals.

**North star:** every working day should contain a reason to investigate something personally and a decision that matters to the entire port. The state must remain distinct from private commerce, and the city must continue living beyond any single ship or inspection.
