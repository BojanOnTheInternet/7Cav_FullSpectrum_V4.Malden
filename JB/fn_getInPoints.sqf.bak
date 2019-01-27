JBGIP_GetInPoints =
{
	params ["_config", "_stations"];

	private _points = [];
	{
		private _station = if (_x == "commander") then { "codriver" } else { _x };

		private _property = _config >> ("memoryPointsGetIn" + _station);
		if (isText _property) then
		{
			private _text = getText _property;
			private _textDir = getText (_config >> "memoryPointsGetIn" + _station + "Dir");

			_points pushBack [_station, [[_text, _textDir]]];
		}
		else
		{
			if (isArray _property) then
			{
				private _array = getArray _property;
				private _arrayDir = getArray (_config >> "memoryPointsGetIn" + _station + "Dir");

				private _combined = [];
				for "_i" from 0 to count _array - 1 do
				{
					_combined pushBack [_array select _i, _arrayDir select _i];
				};

				_points pushBack [_station, _combined];
			}
		};
	} forEach _stations;

	_points;
};

JBGIP_TurretPoints =
{
	params ["_config", "_turretPath"];

	if (!(isClass (_config >> "Turrets"))) exitWith { [] };

	private _turretNumber = 0;
	private _points = [];
	{
		private _localTurretPath = _turretPath + [_turretNumber];
		private _turretPoints = ([_x, ["gunner"]] call JBGIP_GetInPoints);
		private _gunnerName = getText (_x >> "gunnerName");
		{
			_x set [0, [_gunnerName, _localTurretPath]];
		} forEach _turretPoints;
		_points = _points + _turretPoints;

		_points = _points + ([_x, _localTurretPath] call JBGIP_TurretPoints);

		_turretNumber = _turretNumber + 1;
	} forEach ("true" configClasses (_config >> "Turrets"));

	_points;
};

// return value is array of [station-name,[[point,dir],...]] and [[turret-gunner-name, turret-path],[[point,dir],...]]

// stations could be "gunner", but off a turret.  We need the station name to provide with a way of saying that we
// want to get in or out of that station.  Right now, it's just whatever word gave the getinpoint values.  moveInDriver,
// moveInGunner, moveInCommander, moveInCargo, moveInTurret.  See if a turret path is on the Turrets stuff.

private _vehicle = param [0, objNull, [objNull]];
private _stations = param [1, [], [[]]];
private _worldCoordinates = param [2, true, [true]];

private _vehicleConfig = (configfile >> "CfgVehicles" >> typeOf _vehicle);

// Collect the names of the selections so they can be converted into positions
private _points = [_vehicleConfig, _stations] call JBGIP_GetInPoints;

if ("turret" in _stations && { isClass (_vehicleConfig >> "Turrets") }) then
{
	_points = _points + ([_vehicleConfig, []] call JBGIP_TurretPoints);
};

// Turrets have a "gunnerName" to describe the seat ("Turrets" >> turret >> "gunnerName")
// Cargo seems to just be "ride in back"
// gunnerGetInAction for turrets e.g. gunnerGetInAction = "GetInHeli_Light_01bench";

// Get the coordinates for the positions and directions
{
	{
		_x set [0, _vehicle selectionPosition [_x select 0, "Memory"]];
		_x set [1, _vehicle selectionPosition [_x select 1, "Memory"]];
	} forEach (_x select 1);
} forEach _points;

// If world coordinates are requested
if (_worldCoordinates) then
{
	{
		{
			_x set [0, _vehicle modelToWorld (_x select 0)];
			_x set [1, _vehicle modelToWorld (_x select 1)];
		} forEach (_x select 1);
	} forEach _points;
};

_points;