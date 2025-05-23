-- Base class: Support
return {
    LaserBeam = {
        Name        = 'LaserBeam',
        Cooldown    = 0.3,
        ManaCost    = 0,
        Range       = 40,
        Damage      = 8,
        Type        = 'Magic',
        AnimationId = 0,
        Visual      = 'Laser',
    },
    RepulsorBlast = {
        Name        = 'RepulsorBlast',
        Cooldown    = 8,
        ManaCost    = 25,
        Radius      = 6,
        Knockback   = true,
        AnimationId = 0,
        Visual      = 'ConcussivePulse',
    },
    OverclockedCircuits = {
        Name    = 'OverclockedCircuits',
        Type    = 'Passive',
        Effects = {
            {Stat='CooldownReductionPercentPerSupport', Value=0.05},
        },
        Duration = 4,
        StackCap = 5,
    },
    NanoMend = {
        Name         = 'NanoMend',
        Cooldown     = 6,
        ManaCost     = 20,
        Duration     = 4,
        HealPercentPerSec = 0.0375,
        ShieldPercentOnOverheal = 0.05,
        AnimationId  = 0,
        Visual       = 'Nanobots',
    },
    KineticWard = {
        Name         = 'KineticWard',
        Cooldown     = 12,
        ManaCost     = 25,
        Duration     = 6,
        ShieldAmount = 100,
        AnimationId  = 0,
        Visual       = 'HexShield',
    },
    NeuralLink = {
        Name         = 'NeuralLink',
        Cooldown     = 18,
        ManaCost     = 35,
        Duration     = 6,
        DamageReductionPct = 0.08,
        JumpOnKill   = true,
        AnimationId  = 0,
        Visual       = 'EnergyTether',
    },
}
