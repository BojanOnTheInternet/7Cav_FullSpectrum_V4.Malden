params ["_object", ["_damage", 0, [0]], ["_hasMissiles", false, [true]]];

if (_damage <= 0) exitWith { _object setVariable ["JB_DE_ExplosiveDamage", nil, true] };

_object setVariable ["JB_DE_ExplosiveDamage", [_damage, _hasMissiles], true];