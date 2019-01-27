private _position = param [0, [], [[]]];
private _closest = param [1, 1000, [0]];
private _farthest = param [2, 3000, [0]];
private _deviation = param [3, 70, [0]];

private _path = [nearestLocation [_position, ""]];

while { true } do
{
	private _strongpoint = [_path select ((count _path) - 1), _path, _closest, _farthest, _deviation] call SPM_StrongPointLocation;

	if (isNull _strongPoint) exitWith {};

	_path pushBack _strongPoint;
};

_path