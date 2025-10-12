local nakamaMedia, _A, nakama = ...

-- initialize empty tables
nakama.SpellBook = nakama.SpellBook or {}
nakama.SpellBook.Rogue = {}

-- Buffs

-- Defensive Spells

-- Offensive Spells
--> Builds CP
nakama.SpellBook.Rogue.SinisterStrike = _A.GetSpellInfo(1101752)

--> Finisher
nakama.SpellBook.Rogue.Eviscerate = _A.GetSpellInfo(1102098)

-- Utility Spells