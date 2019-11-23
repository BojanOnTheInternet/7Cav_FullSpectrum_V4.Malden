// Example: [_vehicle worldToModel getPos player, boundingBoxReal _vehicle] call JB_fnc_distanceToBoundingBox
params ["_position", "_boundingBox"];

private _difference0 = 0;
private _difference1 = 0;
private _delta = [0, 0, 0];
{
	_difference0 = (_boundingBox select 0 select _x) - (_position select _x);
	_difference1 = (_position select _x) - (_boundingBox select 1 select _x);
	_delta set [_x, if (abs _difference0 < abs _difference1) then { _difference0 } else { _difference1 }];
} forEach [0, 1, 2];

if ({ _x <= 0 } count _delta == 3) exitWith { (_delta select 0) max (_delta select 1) max (_delta select 2) };

vectorMagnitude (_delta apply { _x max 0 })