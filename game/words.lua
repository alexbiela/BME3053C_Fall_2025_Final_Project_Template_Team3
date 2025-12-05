-- words.lua
local M = {}

M.physiology_words = {
    "HEART", "LUNGS", "VEINS", "NERVE", "BRAIN",
    "CELLS", "GLAND", 'FEMUR', "ILEUM", "RENAL",
    "OVARY", "NASAL", "AXIAL", "LOBES", "TIBIA",
    "ULNAE", "RADII", "ILIAC", "HUMOR", "VILLI"
}

M.device_words = {
    "STENT", "CLAMP", "LASER", "PROBE", "SHUNT",
    "VALVE", "SCOPE", "DRILL", "GUIDE", "METER",
    "PATCH", "GLOVE", "PLATE", "TUBES", "MASKS",
    "PUMPS", "GAUGE", "SHEET", "SCREW", "STICK"
}

M.signal_words = {
    "PULSE", "SPIKE", "TRACE", "SCANS", "SLICE",
    "PIXEL", "FRAME", "DEPTH", "SHAPE", "PHASE",
    "ANGLE", "NOISE", "CLEAR", "FOCUS", "LEVEL",
    "WIDTH", "RANGE", "WAVES", "TONES", "IMAGE"
}

return M
