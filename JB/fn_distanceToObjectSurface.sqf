params ["_position", "_object", "_range"];

_position = AGLtoASL _position;

private _target = _position vectorAdd ((_position vectorFromTo aimPos _object) vectorMultiply _range);
private _intersections = lineIntersectsSurfaces [_position, _target, player, objNull, true, 100, "VIEW", "NONE"];

_intersections = _intersections select { _x select 2 == _object };
if (count _intersections == 0) exitWith { [[], [], -1] };

// [position-world-coordinates, normal-world-coordinates, distance]
[ASLtoAGL (_intersections select 0 select 0), _intersections select 0 select 1, _position distance (_intersections select 0 select 0)]