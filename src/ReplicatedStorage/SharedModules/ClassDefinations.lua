-- ClassDefinitions.lua
-- Defines every base and evolved class in the dungeon crawler

return {
    -- Base Classes
    Warrior = {
        displayName = "Warrior",
        description = "Stalwart melee fighter with high durability.",
        evolutions = { "Ronin", "Void Knight", "Vanguard" },
    },
    Ranger = {
        displayName = "Ranger",
        description = "Agile ranged attacker, excels at kiting.",
        evolutions = { "Beastmaster", "Hunter" },
    },
    Mage = {
        displayName = "Mage",
        description = "Master of arcane arts—powerful but fragile.",
        evolutions = { "Warlock", "Necromancer", "Voidcaller" },
    },
    Support = {
        displayName = "Support",
        description = "Support specialist with deployables and utility gadgets.",
        evolutions = { "Bioengineer", "Sentinel", "Puppeteer" },
    },
    Striker = {
        displayName = "Striker",
        description = "Close‑quarters brawler with high burst potential.",
        evolutions = { "Frostfang", "Voidwarden", "Monk" },
    },

    -- Evolved Classes
    Ronin = {
        displayName = "Ronin",
        description = "Glass cannon katana master focused on bleed and precision.",
    },
    ["Void Knight"] = {
        displayName = "Void Knight",
        description = "Sustain bruiser channeling void energy to tank and deal damage.",
    },
    Vanguard = {
        displayName = "Vanguard",
        description = "Stalwart defender who taunts enemies and protects allies.",
    },
    Beastmaster = {
        displayName = "Beastmaster",
        description = "Dual‑form ranger commanding a primal companion.",
    },
    Hunter = {
        displayName = "Hunter",
        description = "Precision marksman excelling at marking and executing targets.",
    },
    Warlock = {
        displayName = "Warlock",
        description = "Tentacle‑wielding caster with eldritch resilience and debuffs.",
    },
    Voidcaller = {
        displayName = "Voidcaller",
        description = "Reckless sorcerer trading vitality for devastating void magic.",
    },
    Necromancer = {
        displayName = "Necromancer",
        description = "Warlord of the dead, commanding skeletal legions and death magic.",
    },
    Bioengineer = {
        displayName = "Bioengineer",
        description = "Healer deploying nanobots and advanced medical tech.",
    },
    Sentinel = {
        displayName = "Sentinel",
        description = "Lightning tank in an arc‑powered exosuit with shock defenses.",
    },
    Puppeteer = {
        displayName = "Puppeteer",
        description = "Manipulator of tethers, sharing buffs and debuffs tactically.",
    },
    Frostfang = {
        displayName = "Frostfang",
        description = "Ice predator commanding clones and freezing powers.",
    },
    Voidwarden = {
        displayName = "Voidwarden",
        description = "Void tank harnessing dark energy for protection and retaliation.",
    },
    Monk = {
        displayName = "Monk",
        description = "Balanced striker mastering elemental imbues and martial arts.",
    },
}