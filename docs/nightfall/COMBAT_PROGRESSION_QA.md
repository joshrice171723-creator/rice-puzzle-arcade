# Combat progression implementation — October 19, 2026

## Delivered behavior

Six permanent stats start at 1/99 and cap at 99/99. Their floored mean determines Combat Level (1–99); each level gained earns one global talent point. Points spent in any class reduce the same bank. Existing owned class nodes are grandfathered with an exact spent-point allowance; old mastery does not mint additional new points. Class mastery passives and temporary expedition levels remain separate.

Class → Training displays current stat levels, progress and bonuses. Select Accurate, Powerful, Guarded, Ranged, Arcane or Balanced before starting an expedition. All automatic damage sources train the selected focus; Vitality also receives a third. A saved expedition locks the training focus and combat bonuses until settled. New stat bonuses take effect on the next expedition.

Effective damage is capped by actual remaining HP and a non-refillable per-enemy reward budget. Overkill, corpse hits and healing cannot duplicate XP. Ordinary kills budget 24 focus XP; bosses budget 240. Area, burn and structures use the same accounting. Earned XP survives defeat and ending a saved expedition, and banks once with the reward receipt. Practice and benchmarks award none.

Save schema 5 migrates earlier profiles without changing items, checkpoints or owned unlocks. Old checkpoints resume with zero historical combat XP and baseline training bonuses; damage after resuming earns XP normally. Failed reward writes roll back all XP and points. Failed return-to-Base checkpoints now keep the live run paused and display the error instead of discarding new XP by loading an older snapshot.

## Verification

- Full scripted suite: **27 suites, 7,520 checks, zero failures**, process exit 0, no script errors. Log: `artifacts/nightfall-godot/combat-progression-suite-final.log`.
- New combat progression suite: **136 checks**, covering all threshold boundaries, focus splitting, fractional damage, overkill, healing, normalized HP, shields, burns, area, turrets, practice exclusions, caps, legacy migration, shared point spending, disk checkpoint recovery, settlement idempotency and write rollback.
- New Training UI suite: **351 checks**, six selectable styles, save/reload and failure handling, active-attempt locks, fresh/max fixtures and bounds at 430×760 and 320×568.
- Expedition controller suite: **22 checks**, including failure→paused live run→successful retry→resume→end and XP preservation.
- Class showcase: **35 checks**; Training accessible, Talent Preview and Mastery remain accessible.
- Graphics renders inspected at `artifacts/nightfall-godot/combat-training/`. Real UI, disposable profiles; no sample rewards added to a player save.
- Independent review identified the failed-checkpoint transition; fixed and regression-tested before final suite.

## Android

APK SHA-256: `7869e0e6e1483fae8930645c1186e5bbbcb61bf39fb7fcd1e79d1837a2203a29`.

Export reported `[ DONE ] export`. The known Windows exporter remained alive afterward; its owned export process was stopped and Gradle was stopped. ADB initially reported offline; reconnect recovered it. `adb install -r` succeeded, followed by native launch. Opened Class → Training on emulator-5554 and inspected all six 1/99 rows, Combat Level 1/99, zero talent points and the correctly disabled focus selector for the existing saved expedition. Left the emulator on this screen. Full JSON before/after comparison is identical, including the active checkpoint. The on-disk profile remains version 4 until the next intentional write; migration is applied in memory on load. No mission, item, currency or reward was changed by native inspection. Screenshot: `visual-iterations/combat-training/native-training.png`.

## Remaining balance and platform limits

The one-sixth threshold curve is implemented; **one-sixth real playtime is not established**. The balance document gives explicit rate assumptions and calibration requirements. Existing trees cost 36 points total across four classes; further earned points remain banked. Only two classes and Zone 1 are currently playable. This change does not add the rest of the campaign or additional talent nodes.

Some existing UI test processes still report two ObjectDB instances leaked at exit. No failing assertions or script errors were observed; this warning is not reported as resolved. Production ad fill, physical-device performance and full-campaign progression pacing were not validated in this change.
