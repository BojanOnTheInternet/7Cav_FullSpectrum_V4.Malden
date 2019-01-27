#define TIME_STEP 1.0

JB_SV_Repair =
{
	params ["_vehicle", "_timeToRepair", "_damageLimit"];

	_damageLimit = _damageLimit max 0;

	private _vehiclePosition = getPos _vehicle;

	while { alive _vehicle && { damage _vehicle > _damageLimit } } do
	{
		if (_vehiclePosition distance (getPos _vehicle) > 5) exitWith {};

		JB_SV_Message = "Repairing...";

		sleep TIME_STEP;
		_vehicle setDamage (((damage _vehicle) - (TIME_STEP / _timeToRepair)) max _damageLimit);
	};

	_vehicle setDamage _damageLimit; // ARMA... sigh

	JB_SV_Message = "";
};

JB_SV_Refuel =
{
	params ["_vehicle", "_timeToRefuel", "_fuelLimit"];

	_fuelLimit = _fuelLimit min 1;

	private _vehiclePosition = getPos _vehicle;

	while { alive _vehicle && { fuel _vehicle < _fuelLimit } } do
	{
		if (_vehiclePosition distance (getPos _vehicle) > 5) exitWith {};

		JB_SV_Message = "Fueling...";
		sleep TIME_STEP;
		_vehicle setFuel (((fuel _vehicle) + (TIME_STEP / _timeToRefuel)) min _fuelLimit);
	};

	JB_SV_Message = "";
};

JB_SV_LoadFuel =
{
	params ["_vehicle", "_fuelRate"];

	private _fuelCapacity = _vehicle getVariable ["JBF_FuelCapacity", 0];

	if (_fuelCapacity == 0) exitWith {};

	private _fuelPerTimeStep = _fuelRate * TIME_STEP;

	private _vehiclePosition = getPos _vehicle;

	while { alive _vehicle && { (_vehicle getVariable ["JBF_FuelRemaining", 0]) < _fuelCapacity } } do
	{
		if (_vehiclePosition distance (getPos _vehicle) > 5) exitWith {};

		JB_SV_Message = "Loading fuel...";
		sleep TIME_STEP;
		[_vehicle, _fuelPerTimeStep] call JBF_LoadFuelSupply;
	};

	JB_SV_Message = "";
};

JB_SV_Rearm =
{
	params ["_vehicle", "_timeToRearm", "_magazines"];

	_magazines = magazinesAllTurrets _vehicle; //BUG: Only works correctly if _magazines == magazinesAllTurrets

	private _vehiclePosition = getPos _vehicle;
	private _allMagazines = magazinesAllTurrets _vehicle;

	if (count _magazines == 0) exitWith {};

	private _timePerMagazine = _timeToRearm / (count _magazines);
	for "_i" from 0 to (count _magazines - 1) do
	{
		if (not alive _vehicle) exitWith {};
		if (_vehiclePosition distance (getPos _vehicle) > 5) exitWith {};

		private _magazineType = _magazines select _i select 0;
		private _turret = _magazines select _i select 1;
		private _rounds = _magazines select _i select 2;

		private _magazineIsPylon = ((getText (configFile >> "CfgMagazines" >> _magazineType >> "pylonWeapon")) != "");
		private _roundsPerMagazine = getNumber (configFile >> "CfgMagazines" >> _magazineType >> "count");

		if (_rounds < _roundsPerMagazine) then
		{
			private _fraction = 1 - (_rounds / _roundsPerMagazine);

			private _magazineName = [_magazineType, "CfgMagazines"] call JB_fnc_displayName;
			JB_SV_Message = if (_magazineName == "") then { "Loading weapons..." } else { format ["Loading %1...", _magazineName] };

			private _sleepTime = _fraction * _timePerMagazine;
			while { _sleepTime > 0 && alive _vehicle } do
			{
				sleep (_sleepTime min TIME_STEP);
				_sleepTime = _sleepTime - TIME_STEP;
			};

			if (alive _vehicle) then
			{
				if (not _magazineIsPylon) then
				{
					private _previousCount = 0;
					for "_j" from 0 to (_i - 1) do
					{
						if (_allMagazines select _j select 0 == _magazineType && _allMagazines select _j select 1 isEqualTo _turret) then
						{
							_previousCount = _previousCount + 1;
						};
					};
					for "_j" from 0 to _previousCount do
					{
						_vehicle removeMagazineTurret [_magazineType, _turret];
					};
					for "_j" from 0 to _previousCount do
					{
						_vehicle addMagazineTurret [_magazineType, _turret, _roundsPerMagazine];
					};
				}
				else
				{
					private _pylonNumber = -1;
					{
						if (_x == _magazineType && (_vehicle ammoOnPylon (_forEachIndex + 1) < _roundsPerMagazine)) exitWith { _pylonNumber = _forEachIndex + 1 };
					} forEach getPylonMagazines _vehicle;
					_vehicle setAmmoOnPylon [_pylonNumber, _roundsPerMagazine];
				};
			};
		};
	};
};

private _vehicle = _this select 0;
private _services = _this select 1;

if (!alive _vehicle) exitWith { };

JB_SV_Message = "Starting service";

[] spawn
{
	scriptName "spawnJB_fnc_serviceVehicle";

	while { not isNil "JB_SV_Message" } do
	{
		titleText [JB_SV_Message, "plain down", 0.1];
		sleep 1;
		titleFadeOut 1;
		sleep 1;
	};
};

{
	if (not alive _vehicle) exitWith {};

	private _type = tolower (_x select 0);

	switch (_type) do
	{
		case "repair":
		{
			[_vehicle, _x select 1, _x select 2] call JB_SV_Repair;
		};
		case "refuel":
		{
			[_vehicle, _x select 1, _x select 2] call JB_SV_Refuel;
		};
		case "loadfuel":
		{
			[_vehicle, _x select 1] call JB_SV_LoadFuel;
		};
		case "rearm":
		{
			[_vehicle, _x select 1, _x select 2] call JB_SV_Rearm;
		};
	};
} forEach _services;

JB_SV_Message = nil;

if (alive _vehicle) then
{
	titleText ["Service complete", "plain down", 0.3];
	sleep 3;
	titleFadeOut 2;
};
