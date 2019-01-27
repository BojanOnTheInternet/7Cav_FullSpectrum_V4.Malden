params ["_object"];

private _explosives = [];

private _damage = _object getVariable ["JB_DE_ExplosiveDamage", []];

if (count _damage > 0) then
{
	_explosives = [_damage select 0, _damage select 1] call JB_fnc_detonateGetExplosivesEquivalent;
}
else
{
	private _magazines = getMagazineCargo _object;
	private _types = _magazines select 0;
	private _counts = _magazines select 1;

	_magazines = []; { _magazines pushBack [_x, _counts select _forEachIndex] } forEach _types;

	_explosives = [_magazines, false] call JB_fnc_detonateGetExplosivesEquivalent;
};

if (count _explosives == 0) then
{
	_object setDamage 1;
}
else
{
	private _position = getPos _object;
	deleteVehicle _object;
	[_explosives, _position, 1] spawn JB_fnc_detonateExplosives
};
