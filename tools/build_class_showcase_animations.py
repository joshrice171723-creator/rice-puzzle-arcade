"""Build Nightfall's animated class-screen character art from approved artwork.

The output is a lightweight 2.5D idle loop for the class showcase only. It does
not replace the separate gameplay character rig.
"""

from __future__ import annotations

import argparse
import subprocess
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "apps" / "nightfall-godot"
BLENDER_DEFAULT = ROOT / "tools" / "blender-portable" / "blender-5.2.2-windows-x64" / "blender.exe"
ROSTER = PROJECT / "assets" / "class-showcase" / "roster.png"
ART = PROJECT / "assets" / "class-showcase"
OUTPUT = PROJECT / "assets" / "class-showcase" / "idle_models"
SOURCE = PROJECT / "prototypes" / "class_showcase_motion" / "source"
BLENDS = PROJECT / "prototypes" / "class_showcase_motion" / "blends"
WORKER = ROOT / "tools" / "render_class_showcase_idle.py"
SCAVENGER_BLEND = PROJECT / "prototypes" / "scavenger_idle_blender" / "scavenger_idle.blend"
SCAVENGER_EXPORTER = ROOT / "tools" / "export_scavenger_showcase_glb.py"

ROSTER_REGIONS = {
    "warden": (1000, 75, 1520, 975),
    "engineer": (550, 110, 950, 960),
}
DIRECT_ART = {"scavenger": ART / "scavenger.png", "arcanist": ART / "arcanist.png"}


def prepare_source(class_id: str) -> Path:
    if class_id in DIRECT_ART:
        image = Image.open(DIRECT_ART[class_id]).convert("RGBA")
    else:
        image = Image.open(ROSTER).convert("RGBA").crop(ROSTER_REGIONS[class_id])

    alpha = image.getchannel("A")
    bounds = alpha.point(lambda value: 255 if value > 3 else 0).getbbox()
    if bounds is None:
        raise RuntimeError(f"No visible character pixels found for {class_id}")

    # Keep a small clear border so antialiased edges never touch the render frame.
    cropped = image.crop(bounds)
    padding_x = max(8, round(cropped.width * 0.025))
    padding_y = max(8, round(cropped.height * 0.018))
    padded = Image.new("RGBA", (cropped.width + padding_x * 2, cropped.height + padding_y * 2))
    padded.alpha_composite(cropped, (padding_x, padding_y))
    SOURCE.mkdir(parents=True, exist_ok=True)
    path = SOURCE / f"{class_id}.png"
    padded.save(path, optimize=True)
    return path


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--blender", type=Path, default=BLENDER_DEFAULT)
    parser.add_argument("--classes", nargs="+", choices=["scavenger", "warden", "arcanist", "engineer"], default=["scavenger", "warden", "arcanist", "engineer"])
    args = parser.parse_args()
    if not args.blender.is_file():
        raise SystemExit(f"Blender executable not found: {args.blender}")

    OUTPUT.mkdir(parents=True, exist_ok=True)
    BLENDS.mkdir(parents=True, exist_ok=True)
    for class_id in args.classes:
        model_path = OUTPUT / f"{class_id}.glb"
        if class_id == "scavenger":
            command = [str(args.blender), "--background", str(SCAVENGER_BLEND), "--python", str(SCAVENGER_EXPORTER), "--", "--model", str(model_path)]
        else:
            source = prepare_source(class_id)
            blend_path = BLENDS / f"{class_id}_idle.blend"
            command = [
                str(args.blender), "--background", "--python", str(WORKER), "--",
                "--class-id", class_id,
                "--image", str(source),
                "--model", str(model_path),
                "--blend", str(blend_path),
            ]
        print(f"Building {class_id} showcase animation…", flush=True)
        subprocess.run(command, check=True)


if __name__ == "__main__":
    main()
