# Economy, daily progression, facilities and recovery

The baseline economy is earned play without ads, payments, daily attendance or perfect medals. Two separate ledgers prevent double-counting: `economy_forecast.csv` compares cumulative first-pass income against a target build at each zone independently; `economy_sequential.csv` carries supplemental contract earnings and XP forward and buys each cumulative investment only once. Summing the snapshot deficits would incorrectly charge the same shortage repeatedly.

## Currency and reward registry

| Resource | Persists? | Income / spending |
|---|---|---|
| Credits | Yes | Clear/field/medal/contract/daily income; levels, affixes, facilities, chosen crafts |
| Parts | Yes if banked or secured | Clear/cache/contract/salvage/daily income; same progression sinks |
| Named zone materials | Yes if banked/secured | Signature boss one; captains one-third fragment; targeted recipes and tier catalysts |
| Gems | Yes | First clears/mastery/daily; optional keys or cosmetic convenience, no mandatory power gate |
| Cache keys | Yes | First clears, every third successful contract, daily objectives/calendar, optional videos |
| Field Scrap | No | Run construction/repair;130 early,180 later maximum ordinary budget |
| Field Tokens | No | Proposed separate merchant currency;90 early,150 later maximum budget |
| Combat XP | No | Weighted monster drops, temporary selections only |
| Survivor / mastery XP | Yes | Clear reward and capped field progress; preserved on defeat |

Standard clear Credits `165+45(z−1)`, Parts `3+floor(z/2)`, Survivor XP `85+15(z−1)`, mastery XP `45+5(z−1)`. Mission5 multiplies each by1.5, rounded half upward. These reproduce the main-plan anchors: Zone1 165/3/85/45;5 345/5/145/65;10 570/8/220/90;15 795/10/295/115;20 1,020/13/370/140.

Field Credits cap at `40+8(z−1)` per mission. Field Survivor XP cap is `60+8(z−1)` and mastery cap is half that, rounded half upward. The forecast collects70% of those caps. Distribute awards over eligible non-summoned kills/caches; no elapsed-time-only XP and no reward for repeatedly damaging an immortal enemy. Persistent field XP is distinct from the Combat XP curve.

There are4 caches early,5 in Zones6–15,6 later. Each guarantees `2+floor((z−1)/5)` Parts in the future design. The baseline funds60% cache capture and excludes salvage/random gear to remain conservative. Cache Parts are a material bundle subject to stash/clear rules; field Credits and earned persistent XP survive defeat. Equipment rolls do not replace the guaranteed Parts in this proposal.

## Upgrade investment and meaningful choice

For current item level `L`, next-level Credits are `40L` through L10, then `400+20(L−10)`. Parts are `L+1` through L5, then `6+floor((L−5)/3)`. Workshop II discounts Credits by10%, rounded up, not Parts. `upgrade_costs.csv` expands all29 transitions. Current level1→5 costs remain400 Credits/14 Parts per item; full later growth is deliberately less punishing than extending the current early formula to level30.

The target ledger upgrades seven primary-bearing slots to `zoneCap−2`; Gadget remains level1 because its utility has no level scaling. It also funds up to seven selected rank-3 affixes, current three facility upgrades, and later facility packages. It conservatively ignores the Workshop discount in expenses. Affix tuning is optional; the minimum viable build uses no tuned affixes. Expensive rerolling and full rarity/targeted-craft investment are **not** silently included in those totals.

The sequential result needs **22 extra successful contracts,77 modeled minutes at3.5 minutes each**, over the entire100-mission first pass to meet that target investment. The final wallet remains positive. This does not mean everyone finishes in a fixed number of hours: failures, menus, collection, boss duration, loot choice, multiple class builds and human learning add variable time. A build using weaker accessories temporarily can progress with fewer contracts; a perfected collection needs more.

Midgame Parts are the bottleneck, particularly level-cap/facility jumps near Zones6 and15. Credits alone do not solve it. The preferred response is transparent Parts contracts and delaying optional facility tiers, not selling an emergency mandatory bundle. The ledger's seven equal-level slots are convenient budget targets, not an instruction to upgrade a5-HP ring ahead of the weapon/chest.

Never refund free value as paid investment. Proposed future same-slot transfer returns80% of recorded paid level-up Credits/Parts, not80% of an item's theoretical level cost. Free reward levels would have zero recorded investment. Rerolls, affix ranks, recipes and consumed donor investments are excluded unless explicitly approved. Merge preserves the highest level but does not refund both consumed donors. Salvage yields `2+rarityIndex+level−1` Parts; it is an inexpensive unwanted-item sink, not a full refund or source of Credits.

## Targeted contracts and side modes

| Mode / gate | Time and objective | Guaranteed reward / cap |
|---|---|---|
| Salvage Contracts / after first mission | Collect3 caches; extraction beacon eligible after90s,3s charge;180s cap; model210s including menus |65% standard zone Credits/Survivor/mastery XP, rounded half upward; `6+floor((z−1)/2)` Parts; chosen-slot Common/Uncommon item; one key per3 wins |
| Boss Training / unlocked encounter | Practice encounter, instant kit reset | No permanent rewards, daily credit or material income |
| Haven Siege / after Zone5 | Five-minute defense variant with an explicit defended structure objective | One standard-zone Credits/Parts reward; selected preparation materials; no exclusive power required by campaign |
| Bounty Hunt / after Zone7 | One already-cleared boss plus a short preparation phase | One local material,50% standard Credits/XP; chosen-category gear roll35%; cannot farm boss summons |
| Nightmare Expeditions / after Zone10 | Cleared zones only; optional +25% HP/+15% hit/one extra specialist packet |125% normal Credits/Parts, cosmetic/mastery goals; no cap bypass or exclusive mandatory mainline item |
| Advanced class trial / after Zone15 | Three learned-mechanic encounters for selected class | Mastery-focused reward,75% standard Credits, no shared class XP cloning |
| Tempest component contract / after Zone18 | Earned endgame contract, same clearly declared objective family | One Mythic fragment per successful clear; ten for a core; blueprint gate still required |

A side mode's source tier is at most the highest legitimately cleared zone, not an unopened frontier preview. Contracts provide chosen slot, not automatically a rare set. Chosen-family targeting can replace the random family after three successful contracts in that slot; this proposed deterministic stamp system consumes the three stamps for one chosen Uncommon family. At eight local materials, the main chosen craft supplies Rare/Epic/Legendary as documented. These paths supplement random duplicate merging.

The sequential ledger models Parts contracts only and conservatively excludes their gear/key/salvage benefits. Its contract XP is65% of the zone standard clear, without an additional field-XP grant. This is important: adding field XP again would overstate Survivor/mastery levels. Contract victories do count toward the future daily clear objective, but no daily value is included in the no-daily ledger.

## Haven facility progression

| Gate | Facility / investment | Bounded effect |
|---|---|---|
| Zone1 | Workshop II400 Credits/12 Parts |10% item-level Credit discount; no rarity/level-cap bypass |
| Zone1 | Storehouse II300/10 | Backpack8→9; secure slots remain2 |
| Zone1 | Infirmary II350/12 | Medkit20→25% max-HP heal once/run |
| Zone6 | Field Workshop package900/20 | Chosen-slot contract stamp exchange and investment ledger; no direct damage |
| Zone6 | Storehouse III600/15 | Backpack9→10; no secure increase |
| Zone10 | Storehouse IV1,200/25 | Third secure slot; Outrider can add one, total4 |
| Zone10 | Research Bench1,800/35 | Chosen recipe filters, defensive blueprint conveniences; no free spell ranks |
| Zone15 | Advanced Workshop2,500/50 | Opens already campaign-gated Legendary recipes; no additional level discount |
| Zone15 | Arcanum II2,500/50 | Deterministic targeted-affix crafting interface and class-loadout convenience; no global damage multiplier |

Packages total1,050/34 initially, then+1,500/35,+3,000/60,+5,000/100. These are exactly the cumulative facility expenses in the forecast. A facility gate does not grant its higher rarity before the campaign receipt. Refusing to build an optional convenience facility must not prevent clearing the next campaign boss.

## Daily lane currently being implemented by the parent delivery

This is a separately reported implementation lane, not assumed income in this package's baseline. The parent reports a seven-claim calendar that pauses on missed days: **75 Credits;3 Parts;100 Credits;1 key;5 Parts;10 Gems;2 keys**, then repeat. No streak reset or catch-up payment. One full cycle supplies175 Credits,8 Parts,3 keys and10 Gems. Dividing by seven gives25 Credits,1.143 Parts,0.429 keys and1.429 Gems per *claimed day*, not per absent calendar day.

Four daily objectives are100 kills,3 field caches,finish2 attempts,clear1 campaign-or-contract. Any3 grants75 Credits+3 Parts+1 key once per UTC day. Only banked non-practice/non-benchmark attempts lasting at least60s or ending in victory qualify; defeat can contribute. Completed unclaimed bonuses carry forward. No paid/ad objective. The parent implementation uses a monotonic local UTC watermark; it is not a server-authenticated anti-clock service.

At full earned participation, calendar plus objective averages100 Credits,4.143 Parts,1.429 keys and1.429 Gems per claimed day. Over seven active days that is700 Credits,29 Parts,10 keys,10 Gems. This accelerates early affix/Parts collection substantially:29 Parts is more than two early item1→5 investments. It does not bypass zone/rarity/level gates. Verify early Epic pity pacing with this lane, because ten earned keys/week plus campaign/contract keys is materially faster than videos alone.

Daily rewards are bonuses for returning, not a required equation term for a clear. A player who completes the campaign in a few sessions should not be underpowered because their calendar has fewer claims. A player who waits/farms for many days can become stronger within the same published caps; enemies do not silently scale to cancel those rewards.

## Gems, optional videos and purchases

One full first-clear zone grants80 Gems; twenty grant1,600. Full fifteen-medal completion across all zones adds `sum(30+5z)=1,650`, but that is excluded from required progression. At25 Gems/key, the first-clear grant alone can buy64 additional keys; this is substantial earned acceleration and belongs in any future detailed inventory simulation. Spending Gems on keys is optional; no mandatory resurrection cost or final-zone entry fee.

Optional rewarded videos may grant at most two keys/day and a separately offered+25% eligible clear Credits/Parts. The clear reward is earned before the offer; declining, closing or unavailable ads does not change victory, loot, boss AI or future odds. Apply a multiplier once to the eligible base, round half upward, and award only after an authenticated earned callback. Never multiply first-clear keys, chosen gear, materials, XP or daily bonuses. For example Zone6 ordinary clear390 Credits/6 Parts becomes488 Credits/8 Parts with the optional bonus; the independent base remains390/6.

Do not sell Legendary before Zone15 clear or Mythic cores before blueprint eligibility. Paid keys use the same available pool/caps/pity as earned keys. Buying twenty keys cannot buy twenty levels or grant permanent class skill ranks. Real-money prices, legal disclosures and live-service monetization are outside this design-only package.

## Defeat, rescue and recovery

On defeat retain previously owned equipment, secured new bundles/items, collected Credits and already earned Survivor/mastery XP. Lose unsecured new equipment/materials; grant no clear reward, boss material, first-clear key or medal. Temporary XP/spells/traits/structures/currencies reset when the attempt ends. Abandoning is not a clear and cannot duplicate secured loot by restoring a checkpoint.

Secure capacity starts2, rises to3 with the Zone10 upgrade, and Outrider can add1. One slot protects one equipment item or one material bundle with its recorded amount, not an unlimited category. Backpack starts8 and expands as listed. Loot IDs and banking receipts must be stable across restart; replacing a secured item requires an explicit choice, never silently evicts it.

An optional rescue may continue the same encounter at50% maximum HP with boss HP/add budgets/cooldowns retained. At most one rescue per attempt. Restore a short safe repositioning window without resetting once-per-run Medkit, mastery prevention, signature shield or reward counters. Minimum and typical victory targets exclude rescue. An unavailable or declined rescue ends the run normally; no future pity penalty, hidden boss modifier or forced loss.

For a failed attempt with field Credits `C_f`, field XP `X_f`, secured Parts `P_s`, the persistent return is exactly `C_f,X_f,P_s`, not a fraction of a success reward. Expected progress over attempts depends on actual survival time, capture and banking; do not replace that with an invented empirical clear probability. The stochastic damage experiments isolate one conditional survival model and are not an economy forecast of real players.
