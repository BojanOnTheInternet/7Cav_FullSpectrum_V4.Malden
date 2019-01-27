JB_RV_ClearVolume =
{
	params ["_vehicle", "_positionASL"];

	private _shift = _positionASL vectorDiff (getPosASL _vehicle);

	private _boundingBox = boundingBoxReal _vehicle;
	_boundingBox = [(_boundingBox select 0) vectorMultiply 0.8, (_boundingBox select 1) vectorMultiply 0.8];

	private _corner000 = [_boundingBox select 0 select 0, _boundingBox select 0 select 1, _boundingBox select 0 select 2];
	private _corner001 = [_boundingBox select 0 select 0, _boundingBox select 0 select 1, _boundingBox select 1 select 2];
	private _corner010 = [_boundingBox select 0 select 0, _boundingBox select 1 select 1, _boundingBox select 0 select 2];
	private _corner011 = [_boundingBox select 0 select 0, _boundingBox select 1 select 1, _boundingBox select 1 select 2];
	private _corner100 = [_boundingBox select 1 select 0, _boundingBox select 0 select 1, _boundingBox select 0 select 2];
	private _corner101 = [_boundingBox select 1 select 0, _boundingBox select 0 select 1, _boundingBox select 1 select 2];
	private _corner110 = [_boundingBox select 1 select 0, _boundingBox select 1 select 1, _boundingBox select 0 select 2];
	private _corner111 = [_boundingBox select 1 select 0, _boundingBox select 1 select 1, _boundingBox select 1 select 2];

	private _transform =
	{
		params ["_vehicle", "_positionModel", "_shift"];

		private _positionASL = ATLtoASL (_vehicle modelToWorld _positionModel);
		_positionASL = _positionASL vectorAdd _shift;

		_positionASL
	};

	_corner000 = [_vehicle, _corner000, _shift] call _transform;
	_corner001 = [_vehicle, _corner001, _shift] call _transform;
	_corner010 = [_vehicle, _corner010, _shift] call _transform;
	_corner100 = [_vehicle, _corner100, _shift] call _transform;
	_corner111 = [_vehicle, _corner111, _shift] call _transform;
	_corner110 = [_vehicle, _corner110, _shift] call _transform;
	_corner101 = [_vehicle, _corner101, _shift] call _transform;
	_corner011 = [_vehicle, _corner011, _shift] call _transform;

	private _objects = [];

	{
		if (_x isKindOf "AllVehicles") then
		{
			_objects pushBackUnique _x;
		};
	} forEach ((lineIntersectsWith [_corner011, _corner100]) +
			   (lineIntersectsWith [_corner101, _corner010]) +
			   (lineIntersectsWith [_corner001, _corner110]) +
			   (lineIntersectsWith [_corner111, _corner000]));

	{
		[_x] call JB_fnc_respawnVehicleReturn;
	} forEach _objects;
};

private _vehicle = param [0, objNull, [objNull]];

detach _vehicle;
_vehicle engineOn false;
_vehicle action ["LandGear", _vehicle];  // Logs a message if not present, but otherwise innocuous for non-geared vehicles

private _ejectOccupants =
{
	private _livingOccupants = false;

	{
		if (alive _x && not (_x isKindOf "B_UAV_AI")) then
		{
			moveOut _x;
			_livingOccupants = true;
		}
	} forEach crew _vehicle;

	not _livingOccupants
};

if (canSuspend) then
{
	[_ejectOccupants, 5, 1] call JB_fnc_timeoutWaitUntil;
}
else
{
	call _ejectOccupants;
};

if (not ([_vehicle] call JB_RV_HasRespawnParameters)) then
{
	deleteVehicle _vehicle;
}
else
{
	private _parameters = [_vehicle] call JB_RV_GetRespawnParameters;
	private _position = _parameters select 2;
	private _direction = _parameters select 3;

	// Move to limbo, rotate to correct orientation, move to correct location

	_vehicle setPosASL (_position vectorAdd [0,0,10000]);

	_vehicle setDir _direction;
	_vehicle setVelocity [0, 0, 0];
	_vehicle setVectorUp [0, 0, 1];

	[_vehicle, _position] call JB_RV_ClearVolume;

	_vehicle setPosASL _position;
};