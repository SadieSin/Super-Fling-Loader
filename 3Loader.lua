-- ════════════════════════════════════════════════════
-- VanillaHub 3Loader
-- Loads Vanilla1, Vanilla2, Vanilla3 in order
-- ════════════════════════════════════════════════════

local BASE = "https://raw.githubusercontent.com/SadieSin/Super-Fling-Loader/main/"

print("[VanillaHub] Loading Part 1...")
loadstring(game:HttpGet(BASE .. "Vanilla1.lua"))()

print("[VanillaHub] Loading Part 2...")
loadstring(game:HttpGet(BASE .. "Vanilla2.lua"))()

print("[VanillaHub] Loading Part 3...")
loadstring(game:HttpGet(BASE .. "Vanilla3.lua"))()

print("[VanillaHub] Loading Part 4...")
loadstring(game:HttpGet(BASE .. "Vanilla4.lua"))()

print("[VanillaHub] All parts loaded!")
