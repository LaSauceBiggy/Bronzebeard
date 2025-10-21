--------------------------------------------------------------------------------
-- GentleRogue - Spell Library
-- Author: Gentleman
--------------------------------------------------------------------------------
local nakama, _A, nakama = ...
nakama.spellBook = nakama.spellBook or {}
nakama.spellBook.Rogue = {
    SinisterStrike = _A.GetSpellInfo(1101752),
    SliceAndDice   = _A.GetSpellInfo(1105171),
    Eviscerate     = _A.GetSpellInfo(1102098),
    Evasion        = _A.GetSpellInfo(1105277),
    Throw          = _A.GetSpellInfo(2764),
}
