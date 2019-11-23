params [["_position", [], [[], objNull]], ["_object", objNull, [objNull]], ["_range", 50, [0]]];

if (_position isEqualType objNull && { isNull _position }) exitWith {};
if (_position isEqualType [] && { count _position != 3 }) exitWith {};

if (isNull _object) exitWith {};

if (_range <= 0) exitWith {};

if (_position isEqualType objNull) then { _position = getPosATL _position };
_position = AGLtoASL _position;

private _target = _position vectorAdd ((_position vectorFromTo aimPos _object) vectorMultiply _range);
private _intersections = lineIntersectsSurfaces [_position, _target, player, objNull, true, 100, "VIEW", "NONE"];

_intersections = _intersections select { _x select 2 == _object };
if (count _intersections == 0) exitWith { [[], [], -1] };

// [position-world-coordinates, normal-world-coordinates, distance]
[ASLtoAGL (_intersections select 0 select 0), _intersections select 0 select 1, _position distance (_intersections select 0 select 0)]
