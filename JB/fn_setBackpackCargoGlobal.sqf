params ["_unit", "_backpack", "_count"];

private _backpacks = getBackpackCargo _unit;
clearBackpackCargoGlobal _unit;

{
	if (_x != _backpack) then
	{
		_unit addBackpackCargoGlobal [_x, (_backpacks select 1) select _forEachIndex]
	}
} forEach (_backpacks select 0);

_unit addBackpackCargoGlobal [_backpack, _count];