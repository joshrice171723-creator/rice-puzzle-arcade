# Nightfall Talent Preview

## Scope and visual authority

This completes the talent preview requested in the correction, “the talent preview you forgot that one.” The approved reference is option C, the right-hand composition in [class-options.png](../approved-choices/class-options.png). The existing hero class showcase remains the entry screen; its **Talent Preview** button opens this dedicated page.

The preview inherits Nightfall’s blue enamel panels, gold accents, portrait frames, ribbon title and illustrated ability medallions. Its composition follows the approved reference: class identity above a portrait switcher, a connected talent constellation, then a selected-ability summary and destination controls. This is a scoped implementation note, not a new product or brand specification.

## Implemented behavior

- Previous/next arrows and four class portraits switch the inspected class. The current portrait has a gold highlight.
- Class name, mastery level and available skill points come from the profile.
- Eight ability nodes and their prerequisite connections come from `skill_tree.gd`: three starter abilities and five branch abilities. This real topology replaces the reference image’s illustrative arrangement.
- Selecting a node highlights it and updates the ability name and unlocked, locked or class-locked state. Locked nodes show their point cost when the class is available.
- **Skill Tree** opens the existing progression screen with the selected ability retained. **Mastery** opens the existing mastery page.
- Browsing classes and selecting abilities only changes inspection state. The preview does not spend points, unlock abilities, equip abilities or change the saved profile; progression actions remain in the existing Skill Tree.

Primary implementation: `apps/nightfall-godot/talent_preview.gd`. Entry control: `apps/nightfall-godot/class_showcase.gd`.

## Evidence and disposition

The render harness, `apps/nightfall-godot/tests/talent_preview_render.gd`, captures all four classes at 430 × 760 and 320 × 568, checks that the page body stays above navigation, and asserts that profile data remains unchanged. Eight captures are available in `artifacts/nightfall-godot/talent-preview/`.

Representative captures:

- [Arcanist, 430 px](../../../../artifacts/nightfall-godot/talent-preview/arcanist-430.png)
- [Scavenger, 320 px](../../../../artifacts/nightfall-godot/talent-preview/scavenger-320.png)

The implementation handoff reports zero failures across 34 class checks, 2,764 layout checks and 3,142 progression checks. Reviewer disposition: ship the approved composition with the real eight-ability progression topology; pixel identity with the illustrative reference is not the acceptance criterion.

## Android acceptance

Rebuilt and installed the reviewed source with `adb install -r` (Success). On emulator-5554, opened Class → Talent Preview, switched to Arcanist, selected Gravity Knot and followed Skill Tree to its real details. Returned to the Arcanist Talent Preview and left it open for the user. Complete saved-profile JSON before/after comparison is identical.

Actual native capture: [Talent Preview](implemented/talent-preview-native.png). Focused verification: 5,940 checks across three suites, zero failures; eight renders across four classes and two phone widths. Visual reviewer disposition: ship for this scoped correction.

An initial rapid two-tap script landed on the Expedition screen unexpectedly; the cause was not established. Repeated individual taps successfully selected the node and opened its details. No expedition was ended and the save comparison was unchanged. This is recorded for later rapid-input testing rather than claimed as a diagnosed or fixed bug.
