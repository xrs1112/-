# ai_assets/generate.py
# 批量调用 Pollinations API 生成游戏素材
# 优先使用免费模型，生成前打印预估信息

import subprocess
import os
import sys
from pathlib import Path

# Pollinations skill script path
SKILL_DIR = Path(os.environ.get("POLLINATIONS_SKILL_DIR",
    Path.home() / ".pi/agent/skills/pollinations-image-gen"))
GENERATE_SCRIPT = SKILL_DIR / "scripts/generate.mjs"

# === 配置 ===
MODEL = "flux"          # 免费模型: flux, klein, gptimage, zimage, imagen-4
SIZE = "512x512"        # 游戏素材不需要太大
QUALITY = "medium"      # medium (免费)
ENHANCE = False         # 不使用 AI 增强（保持提示词精确）

# === 纪元一素材清单（MVP 需要 7 张） ===
ASSETS_ERA1 = [
    # 塔 (3张)
    {"name": "tower_probability", "prompt": "quantum probability tower, crystalline structure with wave fluctuations, probability clouds, blue purple neon glow, game asset 2D top-down"},
    {"name": "tower_observer", "prompt": "observer tower monolith with single glowing eye lens, measurement rings, light beam collapsing quantum state, sci-fi game asset 2D top-down"},
    {"name": "tower_quark_trap", "prompt": "flat circular trap pad with swirling containment field rings, particle accelerator ring, glowing trapped energy, game asset 2D top-down"},
    # 敌人 (3张)
    {"name": "enemy_virtual_particle", "prompt": "flickering energy ball enemy, phases in and out, ghostly trail, quantum particle, game asset 2D"},
    {"name": "enemy_free_electron", "prompt": "tiny fast spark of blue electricity with comet trail, speeding bullet of light, game asset 2D"},
    {"name": "enemy_proton_cluster", "prompt": "large slow sphere of three bound orbs connected by energy strings, dense armored tank enemy, golden glow, game asset 2D"},
    # Boss (1张)
    {"name": "boss_entanglement", "prompt": "twin crystalline entities connected by energy tether, shared aura, rotating rings, epic boss, complex geometric, game asset 2D"},
]

OUTPUT_DIR = Path(__file__).parent / "generated"

def estimate_cost():
    """预估消耗"""
    free_models = ["flux", "klein", "gptimage", "zimage", "imagen-4"]
    if MODEL in free_models:
        print(f"✅ 使用免费模型: {MODEL}")
        print(f"   将生成 {len(ASSETS_ERA1)} 张图片，预计免费额度内")
    else:
        print(f"⚠️ 使用付费模型: {MODEL}")
        print(f"   将生成 {len(ASSETS_ERA1)} 张图片，请确认预算")
    print(f"   图片尺寸: {SIZE}")
    print(f"   输出目录: {OUTPUT_DIR}")

def generate_one(name, prompt):
    """生成单张图片"""
    output_path = OUTPUT_DIR / f"{name}.png"
    cmd = [
        "node", str(GENERATE_SCRIPT),
        "--prompt", prompt,
        "--model", MODEL,
        "--output", str(output_path),
        "--width", SIZE.split("x")[0],
        "--height", SIZE.split("x")[1],
        "--quality", QUALITY,
        "--negative_prompt", "blurry, photorealistic, 3D, text, watermark",
        "--seed", "-1",
    ]
    if ENHANCE:
        cmd.append("--enhance")
        cmd.append("true")

    print(f"  生成: {name} ...")
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode == 0:
        print(f"    ✅ {output_path}")
    else:
        print(f"    ❌ 失败: {result.stderr[:200]}")

def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    estimate_cost()
    print()
    print("开始生成...")
    for i, asset in enumerate(ASSETS_ERA1, 1):
        print(f"[{i}/{len(ASSETS_ERA1)}]", end=" ")
        generate_one(asset["name"], asset["prompt"])

if __name__ == "__main__":
    main()
