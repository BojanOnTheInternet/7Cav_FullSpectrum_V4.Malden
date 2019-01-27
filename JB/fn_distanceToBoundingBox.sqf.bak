// Example: [_vehicle modelToWorld getPos player, boundingBoxReal _vehicle] call JB_fnc_distanceToBoundingBox
params ["_position", "_boundingBox"];

private _delta = [0, 0, 0];
{
	if (_position select _x < _boundingBox select 0 select _x) then { _delta set [_x, (_position select _x) - (_boundingBox select 0 select _x)] };
	if (_position select _x > _boundingBox select 1 select _x) then { _delta set [_x, (_position select _x) - (_boundingBox select 1 select _x)] };
} forEach [0, 1, 2];

vectorMagnitude _delta