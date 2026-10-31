from __future__ import annotations

import base64
import io
import os
from pathlib import Path

from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parents[1]
TEMPLATE = ROOT / "tools" / "phone_unlock_mockup.html"
OUT_DIR = Path(
    r"C:\Users\lenovo\.qoder-cn\app\chat-session-visualizations"
    r"\6d445683-152e-46be-a557-3a638a2184e2\visualizations"
)
OUT = OUT_DIR / "phone_unlock.html"


def uri(path: Path, size: tuple[int, int] | None, fmt: str, quality: int = 90, fit: bool = False) -> str:
    im = Image.open(path)
    if fmt.upper() == "JPEG":
        im = im.convert("RGB")
    else:
        im = im.convert("RGBA")
    if size:
        if fit:
            im = ImageOps.fit(im, size, Image.Resampling.LANCZOS)
        else:
            im.thumbnail(size, Image.Resampling.LANCZOS)
    buf = io.BytesIO()
    if fmt.upper() == "JPEG":
        im.save(buf, "JPEG", quality=quality, optimize=True, progressive=True)
        mime = "image/jpeg"
    else:
        im.save(buf, "PNG", optimize=True)
        mime = "image/png"
    data = base64.b64encode(buf.getvalue()).decode("ascii")
    print(f"{path.name}: {im.size} -> {len(buf.getvalue()) / 1024:.1f} KiB")
    return f"data:{mime};base64,{data}"


def main() -> None:
    assets = ROOT / "assets"
    subs = {
        "__BG__": uri(assets / "场景内部图" / "熊起东方总部.png", (1600, 900), "JPEG", 72, True),
        "__PAPER__": uri(assets / "ui" / "ledger" / "paper_tex.png", (512, 512), "JPEG", 82),
        "__TAPE__": uri(assets / "ui" / "ledger" / "tape_tex.png", (260, 74), "PNG"),
        "__SEAL__": uri(assets / "ui" / "ledger" / "seal_tex.png", (128, 128), "PNG"),
        "__PHONE__": uri(
            assets / "ui" / "rework_v1" / "hud" / "reference_full_v1" / "06_手机按钮.png",
            (420, 420),
            "PNG",
        ),
        "__LOCK__": uri(
            assets / "ui" / "rework_v1" / "task_book" / "05_锁图标_灰白修正版.png",
            (150, 150),
            "PNG",
        ),
        "__CHECK__": uri(
            assets / "ui" / "rework_v1" / "task_book" / "16_未勾选框.png",
            (72, 72),
            "PNG",
        ),
        "__DOT__": uri(
            assets / "ui" / "rework_v1" / "hud" / "components" / "11_通知_红点.png",
            (48, 48),
            "PNG",
        ),
        "__AVATAR__": uri(
            assets / "ui" / "rework_v1" / "profile" / "components" / "03_人际关系" / "NPC_通用头像框.png",
            (120, 120),
            "PNG",
        ),
        "__PAW__": uri(
            assets / "ui" / "rework_v1" / "task_book" / "22_页面装饰爪印.png",
            (120, 120),
            "PNG",
        ),
    }

    html = TEMPLATE.read_text(encoding="utf-8")
    for key, value in subs.items():
        html = html.replace(key, value)

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    OUT.write_text(html, encoding="utf-8")
    print(f"\nWrote {OUT} ({OUT.stat().st_size / 1024:.1f} KiB)")


if __name__ == "__main__":
    main()
