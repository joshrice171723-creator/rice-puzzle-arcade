# Nightfall Engineering and Delivery Plan

**Current priority: finish and verify the first-zone gameplay before expanding the campaign.** The five-tab home, permanent combat training/talent trees, equipment merging and substats, set bonuses, daily progression and the first five missions are implemented. The October 19 follow-up adds visibly equipped animated weapons, reusable spell meshes, compact icon counters and weapon-specific Salvage Contracts. See [combat delivery](COMBAT_MECHANICS_AND_PRESENTATION.md) and [equipped weapons and contracts](EQUIPMENT_AND_CONTRACT_DELIVERY.md) for evidence and limitations.

The separate [campaign balance package](balance-design/DESIGN_INDEX.md) defines proposed future numbers. Zones 2–20 are not shipped. Warden and Arcanist have implemented combat kits and remain behind their planned future-zone unlocks. Production billing, revenue-ready ad mediation and physical-device acceptance are still separate work; the current first-zone APK is an internal build.

October 18, 2026. Joshua subsequently authorized starting this plan with “ok start.” Implementation is proceeding through the milestones below. The isolated M0 proof and its remaining acceptance gaps are recorded in [engine proof verification](ENGINE_PROOF_QA.md). Production migration, purchases, and deployment are not implied by a successful prototype build.

The October 18–19 feature session now implements the first five-mission zone's rules, eight automatic spell families with branching specializations/evolutions, proximity shrines, protected loot, field defenses, saved Haven equipment/facilities, earned chests, original audio and a separate Salvage Contracts mode. See the [feature session evidence](FEATURE_BUILD_SESSION.md) for implementation and automated checks. M1–M3 acceptance remains open: human combat feel, complete animation, deferred rendering defects, physical-device performance and actual rewarded-video delivery are separate from rule tests and exports. Existing rendering issues are deferred at Joshua's request in the [bug log](KNOWN_ISSUES.md).

Build a polished, complete mission first, expand it into one five-mission zone, then prove that a second zone can be produced efficiently before scaling to 20 zones and 100 missions. The first technical decision is to evaluate Godot for Nightfall with real art and Android integration. Passing that evaluation precedes committing to the migration.

## 1. Product baseline

The [main design](NIGHTFALL_MAIN_PLAN.md), [Beaconbound art direction](ART_DIRECTION.md), and [shrines and run interface](SHRINES_AND_RUN_UI.md) govern the product. This document defines delivery, not a replacement game design. All balancing numbers remain starting proposals.

- Graphical, portrait mobile survival action with automatic weapons, spells and class powers; player movement and Dodge are the combat controls. Scavenging, upgrade choices and optional field defenses remain player decisions.
- Twenty zones, five missions per zone. Four-minute waves in Zone 1, five minutes in Zones 2–5, six minutes thereafter. When the wave timer ends, the boss appears. Killing it is required to win; there is no second timer.
- Performance and collected supplies determine extra rewards. Completing the mission unlocks the next mission even without all mastery medals.
- Persistent character progression, class mastery, equipment, Haven improvements, and secured loot are separate from temporary Combat XP, spells, traits, Relics, and Field Scrap.
- Four classes: Scavenger, Engineer, Warden, Arcanist. Eight implemented equipment slots (Ring and Pants added October 18), six rarity tiers, and the stat limits in the main plan. Saves, inventory, equipment operations and stat calculation include all eight slots.
- One fast Artificer trading shrine per arena; two slower Twinflame shrines sharing a three-Relic-per-run allowance. Charging happens in danger; choosing an offer pauses combat.
- Original chunky Beaconbound artwork, navy/cobalt/violet/ivory/amber palette. Phone controls and combat HUD fit without page scrolling. Equipment inventory is five columns wide and scrolls vertically within its panel; the character, equipped slots, stats and navigation remain fixed.
- Ads and purchases may accelerate progression, but combat rules must be testable independently of ad value or payment history. No scheduled forced losses or hidden changes to boss health when a player approaches victory.

## 2. What exists and what remains unproven

The existing Nightfall application is an Expo/React Native prototype with a Canvas renderer inside a DOM/WebView component. It has movement, spawning, automatic attacks, temporary upgrades, snapshots, and Android build scripts. Its current timer-based victory does not implement the new boss requirement.

The historical [expansion QA report](../EXPANSION_QA.md) records successful focused logic tests and browser checks. It also records approximately 7–11 FPS in an Android emulator and an unfinished native soak test. That is an emulator result, not a physical-phone benchmark; it does not isolate whether the bottleneck is the renderer, host, or emulator configuration. The native rendering path remains unproven for the intended artwork and action.

The three puzzle games already have advertising contracts and native integration work. The studio has a desktop dashboard and an online gameplay collector. Reuse their protocols, lessons, test cases, and reporting rather than recreating the entire studio. Do not mistake those existing systems for a completed Nightfall integration or verified production mediation.

The concept boards establish visual direction. They are not animated characters, layered equipment, collision maps, or functioning screens.

## 3. Recommended toolchain

| Area | Selection | Purpose and boundary |
|---|---|---|
| Nightfall engine | Godot 4 stable, exact version pinned after the technical proof | Purpose-built scene, animation, input, audio, profiling, and Android export workflow |
| Game language | Typed GDScript | One straightforward game language; avoid adding C# export complexity |
| Rendering | Godot Compatibility renderer, 2D gameplay with 2.5D artwork | Start with pre-rendered/cutout sprites and modular terrain; avoid real-time 3D crowds as the initial baseline |
| Character and prop source art | Blender plus AI concept generation | Reusable rigs and controlled camera/lighting produce consistent directional sprites; AI assists concept and static art production |
| Texture editing | An available local raster editor, chosen during tool audit | Alpha cleanup, atlas inspection, icon polish; no paid subscription prerequisite |
| Android platform work | Android Studio SDK/JDK/Gradle and Kotlin bridge | Test export, lifecycle, Google ads/consent, and later Play Billing |
| Content | Versioned JSON definitions with validation | One editable source for stats, drop tables, waves, zones, and mission definitions |
| Scene assets | Godot scenes and resources | UI layouts, animation, visual effects, tile sets; reference content IDs rather than duplicating stats |
| Gameplay tests | Godot headless test runner and deterministic scenarios | Verify the actual GDScript rules; keep existing TypeScript tests for unchanged shared systems |
| Telemetry | Existing HTTPS collector and desktop dashboard | Add a Godot event client compatible with the existing schema |
| Source control | Existing Git repository, scoped branches and commits | Preserve the puzzle games and current prototype during evaluation |

Godot documents Compatibility as an option suited to older hardware and simpler rendering needs, including 2D. That supports this starting choice; it does not promise a frame rate for our game. See [Godot rendering methods](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html).

Godot supports an Android export workflow and native Android plugins. We will prove that workflow before building substantial content. See [Android export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html) and [Android plugins](https://docs.godotengine.org/en/stable/tutorials/platform/android/android_plugin.html).

Blender can render animation frames in background batches, supporting a repeatable sprite production pipeline. See [command-line rendering](https://docs.blender.org/manual/en/latest/advanced/command_line/render.html).

This is a proposed revision to [ADR 001](../ADR_001_ARENA_RENDERING.md), which currently favors the Expo prototype. Once implementation is authorized, first build an isolated proof. Adopt Godot and update that ADR only if export, visuals, performance, and native integration pass. If the proof fails, profile the cause and revise the architecture decision before producing more content.

## 4. Architecture and reuse

Proposed new project location: `apps/nightfall-godot/`. Keep `apps/nightfall-arena/` intact as the reference prototype until the replacement passes the complete first-zone milestone. The three puzzle applications remain in their existing stack.

Use five small, explicit areas rather than a general-purpose studio engine:

1. **Game rules:** run state, damage, stat aggregation, spawning, abilities, loot rolls, shrine limits, boss phases, and mission results. Keep these testable without the presentation layer.
2. **Presentation:** scenes, character animation, effects, HUD, controls, menus, camera, and audio. Render game state without deciding rewards.
3. **Content:** stable definitions for classes, equipment, abilities, enemies, bosses, missions, zones, buildings, and rewards. Validate references and limits before exporting.
4. **Persistence:** versioned player profile, active-run checkpoint, inventory, progression, and reward transaction records.
5. **Platform services:** lifecycle, audio focus, ads, consent, purchases, and telemetry. Desktop development uses explicit test implementations; shipping Android uses native services.

Reuse existing TypeScript logic as a behavioral reference and test vector source, not through a JavaScript runtime embedded in Godot. The React Native ad wrapper cannot be imported directly into Godot. Its reward rules and failure scenarios can be reused; the native bridge must be implemented and tested separately.

Start with a small Kotlin Android plugin using the official Google SDKs behind a narrow interface: initialize consent, query availability, request rewarded video, receive earned reward, receive close/error, and show an eligible interstitial. Pin compatible versions after the first export. Add mediation adapters only when the account mappings and partner SDK requirements are known.

Run simulation on a fixed physics step. Use seeded random sources for reproducible QA, separating combat, loot, and offer draws so a visual effect or cosmetic change cannot consume gameplay randomness. Exact cross-device floating-point replays are not assumed. Pool frequent enemies/projectiles/pickups where profiling supports it, cap entity counts explicitly, and use spatial queries instead of checking every entity against every other entity.

Define a single stat pipeline: base character and equipment, permanent modifiers, temporary run modifiers, then documented caps and final calculations. Tooltips and damage calculations read the same results. Currency units, percentages, seconds, meters, and integer rounding must be explicit in content definitions.

## 5. Delivery milestones

| Milestone | Deliverable | Exit evidence |
|---|---|---|
| M0 Technical proof | Android-exportable scene with representative art, input, crowds, and an isolated test-ad bridge | Device/emulator report, profiling capture, install/relaunch evidence, earned-reward callback trace |
| M1 Complete combat mission | Scavenger, one arena, escalating waves, temporary upgrades, one boss, victory and defeat | Full playable run; timer cannot grant victory; no second boss timer; responsive controls |
| M2 Scavenging and shrines | Backpack/stash rules, field construction, both shrine types, selected run UI | Risk/reward choices work under combat; caps and costs are enforced; no pause exploit |
| M3 First-zone vertical slice | Haven, gear, upgrades, five missions and bosses, mastery rewards, persistent saves | Complete home-to-run-to-reward-to-next-run journey, including restart/recovery |
| M4 Repeatable content pipeline | Second zone, all class foundations, full stat/gear framework | New content mainly uses definitions/assets; class and equipment counters are measurable |
| M5 Five-zone alpha | Zones 1–5, four playable classes, targeted farming and initial side mode | Player feedback shows readable combat and useful progression; performance holds with expanded content |
| M6 Monetization and service readiness | Verified ads, consent, entitlement backend, purchase testing, analytics | Real SDK/test-store journeys succeed; cancellations and repeats cannot grant duplicate value |
| M7 Campaign production | Content batches to 10, then 15, then 20 zones | Every mission and boss reviewed; economy/performance regressions checked per batch |
| M8 Release candidate | Signed release candidate, store materials, recovery/support flows | Physical-device acceptance, privacy/store checklist, installation/update tests and owner release decision |

These milestones are ordered by dependencies. The early ad/export proof in M0 reduces platform risk; it is not production monetization. M6 integration can begin after M3 if platform access is ready, but it must not consume effort needed to establish enjoyable combat. Publishing fees or unavailable partner accounts must not prevent local development and ordinary game QA.

### M0 Technical proof

First inspect available tools and storage. This planning pass found about 4.8 GB free on C:. Target 20–30 GB of working headroom before new SDK caches, engine templates, or asset rendering; measure actual needs during setup. Godot and Blender were not on PATH, which does not prove they are absent from the machine. Reuse existing Android SDK/JDK locations rather than downloading duplicates.

Build only an instrumented test arena: one animated Scavenger, one representative enemy, one prop with foreground occlusion, one spell, camera, joystick, dodge, and a small HUD. Test 30, 60, and 120 active enemies; add a documented projectile/pickup/effect load. These are test scenarios, not an instruction to fill every mission with 120 enemies.

Use real Beaconbound sprite sizes early. Placeholder rectangles do not prove art performance. Measure CPU and GPU time, frame-time percentiles, input responsiveness, memory, loading, and atlas size. Compare emulator results separately from physical Android measurements. Aim for 60 FPS on a representative midrange phone and a stable 30 FPS quality tier on the minimum supported device; select the actual minimum device from evidence, not an invented specification.

Also prove pause/background/resume, audio focus, safe-area layout, installation, and a Google sample rewarded ad in an isolated diagnostic screen. An unavailable network or no-fill is a separate blocker from plugin compilation. Do not report real ad delivery from a simulated callback. Physical-device acceptance stays open until a phone is available.

### M1 Complete combat mission

Build a test slice in the Blackout District with the Scavenger, Service Pistol, dodge, three enemy behaviors, a four-minute wave schedule, three initial spells, a small passive pool, and one representative boss. The Breaker is the signature-boss art candidate for this slice; it does not replace the final five-mission boss order.

Implement a clear run state machine: loading, combat, paused choice, boss arrival, boss combat, defeated, rescue pending, victory, and results. All transitions must be explicit. Boss death grants one result; timer expiry only starts the boss phase. Pause covers damage, spawning, projectiles, cooldowns, and the wave timer. Display time and simulation time must agree.

Prove readable movement and enemy tells before adding more systems. The player should recognize why they took damage and have room to evade. Add impact effects, short audio cues, hit reactions, and restrained screen shake. Include reduced-motion/shake and sound controls from the first playable slice.

### M2 Scavenging and shrines

Add Field Scrap, equipment drops, the field backpack, the two secured slots, supply caches, a barricade, and one turret. Establish shared Field Scrap tradeoffs between defenses, shop traits, and rerolls.

Implement one Artificer shrine with the proposed two-second charge and two Twinflame shrines with seven-second charge. Show a ground circle and readable progress. The hero can fight and move within the circle; leaving invokes the agreed grace/decay behavior. Damage does not arbitrarily cancel charging. Menus pause gameplay only after activation.

Artificer offers three purchasable traits, permits multiple affordable purchases, and enforces rank caps. Twinflame offers two Relics and grants one; three total accepted Relics are shared across both shrines. Rerolls spend Field Scrap, preserve their cost state, and cannot be reset by closing/reopening. Validate exhausted shrine visuals and the post-boss-phase interaction rule before expanding offer pools.

### M3 First-zone vertical slice

Deliver a complete player journey: start at Haven, inspect/equip gear, select a mission, play, receive a result, bank or lose the appropriate loot, upgrade an item, unlock the next mission, close the game, and return with the correct state.

Use the first zone's actual five mission definitions: Bruiser, Hunter, Caller, Guardian, signature boss. Their attacks and wave mixes differ while the core game remains the same. Establish each boss with two readable attacks before expanding phases. Add the Engineer at its planned Zone 1 Mission 4 unlock so the unlock has a usable class behind it.

Initial Haven needs Armory, Workshop, and Training functions, not all seven fully developed facilities. Target eight working equipment slots after the Ring/Pants amendment; initially populate a bounded set of Common through Epic items. Include backward-compatible six-slot save migration and bounded stats in that change. Validate Legendary/Mythic data and stat caps later before those tiers become obtainable. Do not fill screens with inactive paid offers or fake upcoming features.

Implement clear/no-rescue-hit-budget/collection medals, first-clear rewards, repeat rewards, zone milestones, and secured-loot loss rules. Verify rewards against the main plan with explicit rounding. Include one optional rescue path with a diagnostic provider until the genuine SDK path is validated. Test controls must be excluded from release builds.

### M4 and M5 Classes and content production

Build Zone 2 using the tools from Zone 1. If a new zone requires copying mission code or rewriting UI, fix the content boundary before making the remaining zones. Add Warden at the planned Zone 2 unlock and Arcanist at Zone 3 Mission 3.

Complete the eight weapon families, eight spell families, equipment sets, rarity/affix rules, caps, and the first useful facilities in small tested groups. Add one focused progression mode first: Salvage Contracts for parts and targeted equipment materials. Endless Night, Arcane Trials, Haven Siege, Bounties, and Nightmare remain later scope, each requiring its own reward budget.

Five-zone alpha is the point to judge whether classes change decisions, equipment creates useful tradeoffs, and difficulty increases through enemy combinations and boss patterns. Do not expand to all 100 missions solely because content generation is fast.

### M6 Monetization and services

Keep development on official sample ads or registered test devices. Reward only from the earned-reward event, once per request; dismissal is not proof of earning. Test load failure, no-fill, cancel, delayed callback, background/resume, and repeated taps. Google's [rewarded-ad documentation](https://developers.google.com/admob/android/rewarded) describes test units and the earned-reward callback.

Nightfall needs its own app and ad-unit configuration. Preserve the agreed one-rescue allowance, optional result bonus, and spaced interstitial policy. An ad failure returns the player to a usable result or game state and does not silently spend currency. Separate real earned rewards, simulated diagnostics, and unavailable ads in the dashboard.

Production mediation requires both native adapters and activated partner account mappings. Inspect the current AdMob/partner state at implementation time. An installed adapter alone is not evidence of a winning mediated impression or revenue.

Before selling currency or power, introduce a server-authoritative premium wallet and entitlement ledger with transaction IDs. Google Play purchase tokens must be verified before granting an entitlement, and repeated verification must not grant it twice. See [Play Billing security guidance](https://developer.android.com/google/play/billing/security).

Use the existing host where practical, but keep commerce storage, access control, backups, and logic separate from the analytics event table. Analytics reports player activity; it must not be able to mint currency. Resolve player identity, guest-to-account linking, restore, refund handling, pending purchases, and offline spending before enabling payments. Offline earned gameplay remains available; premium changes reconcile with the server. Paid randomized chests require reviewed odds/pity behavior and applicable store requirements before release.

### M7 and M8 Full campaign and release

Produce zones in batches: 6–10, 11–15, then 16–20. Each zone needs terrain/prop variation, enemy introductions, five mission definitions, five boss encounters, a signature reward, drop tables, mastery targets, and a progression review. Shared boss families may reuse animation and attack machinery, but each encounter needs a distinct tested combination; twenty recolored arenas alone are not the intended content.

Release readiness includes physical-device performance, upgrade installation without save loss, privacy/consent, purchase restoration, reward failure recovery, accessibility controls, store assets, and a support route. Keep internal APK delivery separate from store publication. The user's publishing budget and account availability are release dependencies, not reasons to build a weaker local game.

## 6. Art production plan

First create a small production kit: Scavenger, pistol, one enemy, one shrine, one terrain tile group, one icon set, and one spell effect. Match the approved B board at actual phone size before producing full rosters.

- Start with eight-direction hero movement using a reusable source rig, with idle, run, attack, hit, dodge, and defeat animations. Test whether mirrored directions preserve weapon handedness and silhouette. Reduce enemy directions where visually acceptable.
- Render sprites from a fixed camera, scale, lighting rig, and pivot convention. Export transparent atlases with a reproducible manifest. Keep high-resolution source art separate from runtime textures.
- Plan body, weapon, and accessory layers so changing a weapon need not produce every body/weapon/animation combination. Validate draw order during turning and dodging. Not every stat item needs a unique visible model.
- Build modular terrain, fence, wall, debris, doorway, shrine, and Haven prop sets. Roofs and tall props fade or occlude correctly; they must not hide enemies or trap the character.
- Use authored Godot text and controls for menus. Do not ship generated screenshots with baked-in labels as the interface.
- Give enemy attacks distinct silhouettes and warning patterns beyond color. Keep projectile density and spell opacity adjustable so important tells remain visible.
- Maintain an asset register with source, license/provenance, approved style, animation coverage, dimensions, pivot, collision intent, and runtime size.

The largest art risk is animation consistency, not producing more illustrations. Validate one complete hero and enemy before commissioning or generating hundreds of individual assets. Original AI-assisted work still needs provenance and similarity review; do not promise that AI generation automatically eliminates copyright concerns.

## 7. Difficulty and economy process

Difficulty comes from pressure, positioning, resource decisions, enemy combinations, build weaknesses, and boss execution. Increase one or two dimensions at a time. A player should be able to identify a way forward: dodge an attack, change a spell, upgrade a slot, or farm a known material source.

For first attempts in newly reached zones after Zone 5, use a provisional 30–45% clear-rate band for appropriately progressed internal test builds. This is a cohort-level tuning hypothesis, not a rule forcing individual players to lose. Compare first attempts separately from repeated farming and highly practiced play. Small internal samples cannot establish population retention.

For every zone, maintain three benchmark loadouts: minimum expected earned gear, typical progression gear, and strong earned gear. Test multiple classes and at least two viable spell strategies. Skilled play with minimum gear must remain plausible. Also measure common-player routes; a theoretically possible perfect no-hit run is not sufficient evidence of balanced progression.

Track attempts to first clear, damage by source, boss reach rate, boss phase deaths, useful gear obtained, and sessions to the next meaningful upgrade. Do not impose a fixed multiweek wall. If players remain stuck, distinguish a desirable mastery challenge from unclear attacks, missing upgrade access, bad controls, or an excessive stat gap.

Model credits, parts, materials, gems, chest pity, and upgrade costs before enabling purchases. Compare campaign, repeat missions, and side modes so one trivial farming route does not invalidate all others. Paid acceleration must not determine whether enemy telegraphs or control responsiveness work.

## 8. Test and acceptance matrix

| Area | Required checks |
|---|---|
| Combat | Damage and mitigation formulas, caps, proc recursion limits, targeting, collision, death exactly once |
| Mission state | Timer triggers boss only, mandatory boss kill, no boss deadline, pause freeze, simultaneous player/boss death rule |
| Abilities | Offer validity, rank limits, unavailable/evolved abilities excluded correctly, cooldown and temporary-stat reset |
| Shrines | Proximity, charge/grace/decay, shared three-Relic limit, rank/currency caps, reroll persistence, pause/resume |
| Loot | Seeded drop tables, pity/crafting guarantees, first-clear versus repeat, secured versus unsecured defeat outcomes |
| Saves | Atomic replacement, version migrations, interrupted write fallback, active run resume, no duplicate result claim |
| UI | Short and tall phones, safe areas, touch targets, font scaling, all combat controls visible, five-column vertically scrolling inventory with fixed character and navigation |
| Lifecycle | Background during combat/choice/ad/results, audio focus, process kill, relaunch, interrupted update |
| Ads | Real test video, earned callback, cancellation, error/no-fill, delayed/duplicate events, reward once, no timer advancement |
| Purchases | Pending/cancelled/successful, backend verification, restoration, duplicate token, refund, network interruption |
| Performance | Representative crowd/effects, frame-time percentiles, memory, heat-related slowdown, 15-minute then 30-minute soak |
| Content | Every ID resolves, all 100 mission slots present at campaign completion, rewards obtainable, boss arenas traversable |

Set the simultaneous-death rule during M1: proposed precedence is player alive after the resolved damage tick for an ordinary clear; otherwise defeat/rescue. Record it explicitly so a race between animation callbacks cannot decide rewards.

Avoid hard unit tests for every cosmetic value. Prioritize rules that lose progress, grant currency, break victory, or affect combat fairness. Use screenshots and hands-on review for appearance. Use simulation for bounded properties and regression, not as a substitute for judging fun.

Each accepted milestone has an exact commit, build artifact, test report, known issues, and visual evidence. Mark browser, desktop, emulator, physical device, and production-service results separately. A successful export is not gameplay acceptance.

## 9. Progression and save integrity

Separate a durable player profile from an active-run checkpoint. Snapshot at safe milestones and before entering platform flows; recover without duplicating loot or rerolling an already displayed offer. Store schema versions and keep a last-known-good save.

Generate a unique run ID. Record a result transaction before granting its rewards, and make repeated processing return the same result. Apply the same pattern to chest opening, crafting, and upgrades. A retry after a crash must not spend currency twice or create a second item.

Keep temporary modifiers out of the permanent stat record. Store content version with a run so an update can resume compatible runs or apply a documented fallback. During the prototype, local saves are not a secure paid-currency ledger. Move premium entitlement authority to the backend before selling anything.

## 10. Studio telemetry

Extend the existing collector and dashboard with a small, versioned event set: mission started, run upgrade selected, shrine activated, trait purchased, Relic selected, boss reached, player defeated, rescue offered/earned, mission completed, rewards banked, equipment changed/upgraded, and purchase verified. Aggregate routine hits/kills during the run instead of transmitting every frame or projectile.

Attach game/build/content version, zone/mission, class, run ID, elapsed combat time, and test/production environment. Use minimal pseudonymous identifiers and the agreed privacy controls; do not send raw purchase tokens or personal account information to analytics.

Primary dashboard questions:

- Which missions lose players before the boss, and which bosses cause repeated failures?
- Which classes, abilities, gear sets, and shrine choices are useful versus ignored?
- How many sessions produce a meaningful upgrade or first clear?
- Do players return after a defeat, an upgrade, or reaching a new zone?
- Do rewarded ads load, play, and grant exactly once, and what percentage fail?
- Does revenue improve without worsening crashes, progression, or return rates?

Do not infer ad revenue from an impression count. Revenue reporting requires actual SDK/provider data and reconciliation. Keep local QA traffic out of player-retention reports.

## 11. Project management

The lead engineer owns architecture, task order, integration, and evidence. Joshua reviews the first moving art sample, first complete mission, first-zone experience, and major balance/economy decisions. Routine file changes do not need repeated approval; engine implementation begins only after the planning-only constraint is lifted.

Keep one milestone's critical path active. Break work into testable player outcomes: for example, “finish a run and reopen with the correct secured loot,” rather than “build a save framework.” Maintain a short backlog with dependency, acceptance check, status, and linked evidence. Handle the highest risk first: rendering/native export, art animation, combat feel, save/reward correctness, then content throughput.

Before work, inspect changes and synchronize the actual upstream branch (`master` in this repository). Preserve unrelated work and attachments. After scoped changes, pull/merge as appropriate, commit, push, and verify remote alignment. Do not remove the existing prototype or overhaul shared puzzle-game infrastructure as incidental cleanup.

Do not promise a calendar launch before M0 and M3 establish real asset throughput and QA effort. At those milestones, estimate remaining work from measured production time per enemy, boss, mission, and zone. A full 100-mission campaign with four classes, animated art, purchases, and side modes is a substantial product.

First implementation batch, once authorized:

1. Audit tools, disk headroom, existing SDK locations, and repository state.
2. Pin the engine/tool versions and create the isolated Godot proof.
3. Produce one production-quality hero/enemy art sample and test it in motion.
4. Export to Android; measure the crowd scene and phone layout.
5. Prove the native consent/test-ad callback boundary.
6. Record the architecture decision and begin the one-mission slice only after the proof is credible.

No paid tools, full asset library, 100-mission generation pass, live monetization switch, or publisher deployment belongs in that first batch.
