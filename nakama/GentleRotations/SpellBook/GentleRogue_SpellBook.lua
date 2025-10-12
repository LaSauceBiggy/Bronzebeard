local nakamaMedia, _A, nakama = ...

-- initialize tables
nakama.spellBook = nakama.spellBook or {}
nakama.spellBook.Rogue = {}

-- Buffs

-- Defensive Spells

-- Offensive Spells
--> Builds CP
nakama.spellBook.Rogue.SinisterStrike = _A.GetSpellInfo(1101752)

--> Finisher
nakama.spellBook.Rogue.Eviscerate = _A.GetSpellInfo(1102098)

-- Utility Spells