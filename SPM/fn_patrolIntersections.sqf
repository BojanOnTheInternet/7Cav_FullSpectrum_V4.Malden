SPM_GoToNextIntersection =
{
	params ["_leader", "_units", "_task"];

	private _keypoints = [_task, "PatrolPositions", []] call SPM_TaskGetValue;

	private _numberKeypoints = count _keypoints;

	if (_numberKeypoints == 0 || ([_task] call SPM_TaskGetState) == -1) exitWith
	{
		[_task] call SPM_TaskComplete;
	};

	private _currentPosition = getPos _leader;
	{
		_x set [0, (_x select 1) distanceSqr _currentPosition];
	} forEach _keypoints;

	_keypoints sort true;

	private _keypoint = _keypoints deleteAt ((round random 1) min (_numberKeypoints - 1));

	private _waypoint = [_group, getPos (_keypoint select 1)] call SPM_AddPatrolWaypoint;
	_waypoint setWaypointType "move";
	[_waypoint, SPM_GoToNextIntersection, _task] call SPM_AddPatrolWaypointStatements;
};

private _group = _this select 0;
private _position = _this select 1;
private _radius = _this select 2;

private _task = [_group] call SPM_TaskCreate;

private _nearest = [_position, _radius, []] call BIS_fnc_nearestRoad;

if (isNull _nearest) exitWith
{
	[_task] call SPM_TaskComplete;

	_task
};

private _radiusSqr = _radius * _radius;
private _keypoints = [];
{
	private _connections = (roadsConnectedTo _x) select { _x distanceSqr _position < _radiusSqr };
	if (count _connections != 2) then { _keypoints pushBack [0, _x] };
} forEach (_position nearRoads _radius);

if (count _keypoints == 0) then
{
	[_task] call SPM_TaskComplete;
}
else
{
	[_task, "PatrolPositions", _keypoints] call SPM_TaskSetValue;
	[leader _group, units _group, _task] call SPM_GoToNextIntersection;
};

_task