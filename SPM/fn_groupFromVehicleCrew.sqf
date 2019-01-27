params ["_vehicle"];

private _crewType = getText (configFile >> "CfgVehicles" >> typeOf _vehicle >> "crew");
private _side = getNumber (configFile >> "CfgVehicles" >> typeOf _vehicle >> "side");

_side = [_side] call JB_fnc_side;

private _fullCrew = fullCrew [_vehicle, "", true];

if (_vehicle isKindOf "StaticWeapon") then
{
	_fullCrew deleteAt 0; // Remove driver position
};

private _descriptor = [];
{
	private _role = _x select 1;
	if (_role in ["driver", "commander", "gunner"] || (_role == "Turret" && not (_x select 4))) then
	{
		_descriptor pushBack [_crewType, "PRIVATE", [0, 0, 0], 0, nil];
	}
} forEach _fullCrew;

[_side, _descriptor]