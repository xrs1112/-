# AI 美术生成提示词模板
# 纪元一：量子微观 (Quantum Microcosm)
# 使用 Pollinations API，优先免费模型 (flux, klein, gptimage)

ERA_1 = {
    "visual_style": "深蓝/紫色量子场，粒子轨道，概率云，荧光粒子轨迹，Tron风格发光线条，科学可视化美学",
    "color_palette": "深蓝 #0a0a2e, 荧光蓝 #00ccff, 紫 #6a0dad, 白 #ffffff, 暗紫 #1a0033",
    "quality_prefix": "game asset, 2D top-down view, isometric style, clean edges, transparent background ready, vector-like, sci-fi aesthetic",
    "negative": "photorealistic, 3D render, blurry, text, watermark, complex background, messy, grainy",
}

# === 塔 ===

TOWER_PROBABILITY = """
A quantum probability tower for a tower defense game. 
Appearance: a floating crystalline structure with wave-like energy fluctuations, 
surrounded by probability clouds of blue and purple particles. 
It pulses with uncertain energy - sometimes bright, sometimes dim.
Style: {visual_style}, {quality_prefix}
Color: {color_palette}
Negative: {negative}
"""

TOWER_OBSERVER = """
An observer tower for a quantum tower defense game.
Appearance: a tall monolith with a single glowing eye/camera lens at the top,
emitting a beam of light that "collapses" quantum uncertainty around it.
The eye has concentric rings of runic measurement symbols.
Style: {visual_style}, {quality_prefix}
Color: {color_palette}
Negative: {negative}
"""

TOWER_QUARK_TRAP = """
A quark trap tower for a quantum tower defense game.
Appearance: a flat circular pad on the ground with swirling containment field rings,
glowing with trapped particle energy. When triggered, it erupts in a burst of particle effects.
Looks like a particle accelerator ring lying flat.
Style: {visual_style}, {quality_prefix}
Color: {color_palette}
Negative: {negative}
"""

# === 敌人 ===

ENEMY_VIRTUAL_PARTICLE = """
A virtual particle enemy for a quantum tower defense game.
Appearance: a small, flickering ball of energy that phases in and out of existence,
with a ghostly trail of after-images. Sometimes nearly invisible (30% opacity),
sometimes bright and solid. Simple spherical core with fading edges.
Style: {visual_style}, {quality_prefix}
Color: {color_palette}
Negative: {negative}
"""

ENEMY_FREE_ELECTRON = """
A free electron enemy for a quantum tower defense game.
Appearance: a tiny, extremely fast-moving spark of blue-white electricity,
with a comet-like trail behind it. Very small but bright, like a speeding bullet of light.
Minimalist design - just a bright core with a motion trail.
Style: {visual_style}, {quality_prefix}
Color: {color_palette}
Negative: {negative}
"""

ENEMY_PROTON_CLUSTER = """
A proton cluster enemy (tank type) for a quantum tower defense game.
Appearance: a large, slow-moving sphere made of three tightly-bound smaller orbs
(representing quarks), connected by glowing energy strings. Dense, heavy, armored-looking.
Has a faint golden/orange glow at the binding points.
Style: {visual_style}, {quality_prefix}
Color: {color_palette}, add golden #ffaa00 for binding energy
Negative: {negative}
"""

ENEMY_BOSS_ENTANGLEMENT = """
A quantum entanglement boss for a tower defense game.
Appearance: TWO identical large crystalline entities connected by a pulsing energy tether,
sharing the same health bar visualized as a shared aura between them.
Each entity is a complex geometric shape (dodecahedron-like) with rotating rings.
When one takes damage, the other flashes simultaneously.
Epic boss scale - 3x larger than normal enemies.
Style: {visual_style}, {quality_prefix}, boss monster, epic
Color: {color_palette}, with bright white core
Negative: {negative}
"""
