private _classes = param [0, [], [[]]];

if (count _classes == 0) exitWith { [] };

private _side = [getNumber (configFile >> "CfgVehicles" >> _classes select 0 >> "side")] call JB_fnc_side;

private _descriptor = [];
{
	_descriptor pushBack [_x, "PRIVATE", [0, 0, 0], 0, nil];
} forEach _classes;

[_side, _descriptor]
