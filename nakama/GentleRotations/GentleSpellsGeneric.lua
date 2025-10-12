local nakamaMedia, _A, nakama = ...

-- initialize tables
nakama.SpellBook = nakama.SpellBook or {}
nakama.SpellBook.Generic = {}

-- Ranged Generic Spells
nakama.SpellBook.Generic.Throw = _A.GetSpellInfo(2764)