// Prevent assembly of objects too close to vehicles

Assemble_Override =
{
	private _assemblyPosition = player modelToWorld [0,2,1];

	private _intersection = [];
	private _tooClose = objNull;
	{
		_intersection = [_assemblyPosition, _x, 30] call JB_fnc_distanceToObjectSurface;
		if (_intersection select 2 < 5.0) exitWith { _tooClose = _x };
	} forEach nearestObjects [_assemblyPosition, ["Plane", "Helicopter", "Ship", "Tank", "Car"], 30, false];

	if (isNull _tooClose) exitWith { false };

	titleText [format ["You cannot assemble that here.  It is too close to the %1", getText (configFile >> "CfgVehicles" >> typeOf _tooClose >> "displayName")], "plain", 0.3];
	true
};

["Assemble", Assemble_Override, Assemble_Override, Assemble_Override] call CLIENT_OverrideAction;