//BUG: All the in-place sorting of routes and then passing them back to the caller is horribly structured.  Another call could resort them in a different order while they're being used.

// Markers numbered in increasing index from landing spot to airfield departure (name, index, height, speed)
//AIRTRANSPORT_ALPHA_1_10_10
JB_AT_InitializeNamedRoutes =
{
	private _pieces = [];
	private _markers = allMapMarkers select { _x find "AIRTRANSPORT_" == 0 } apply { _pieces = _x splitString "_"; [_pieces select 1, parseNumber (_pieces select 2), markerPos _x, parseNumber (_pieces select 3), parseNumber (_pieces select 4)] };
	_markers sort true;

	JB_AT_NamedRoutes = [];
	while { count _markers > 0 } do
	{
		private _firstMarker = _markers deleteAt 0;
		private _currentRoute = [_firstMarker select 0, [_firstMarker select [1, 1e3]]];

		while { count _markers > 0 && { _markers select 0 select 0 == _currentRoute select 0 }} do
		{
			_currentMarker = _markers deleteAt 0;
			(_currentRoute select 1) pushBack (_currentMarker select [1, 1e3]);
		};

		JB_AT_NamedRoutes pushBack _currentRoute;
	};
};

JB_AT_ConfigureAircraft =
{
	params ["_aircraft", "_height", "_speed"];

	_aircraft flyInHeight _height;
	_aircraft limitspeed _speed;
};

JB_AT_WS_ConfigureAircraft =
{
	params ["_leader", "_units", "_passthrough"];

	_passthrough params ["_height", "_speed"];

	[vehicle _leader, _height, _speed] call JB_AT_ConfigureAircraft;
};

// Set up waypoints for a departure or arrival
JB_AT_Transition =
{
	params ["_aircraft", "_key", "_transition"];

	private _routes = _aircraft getVariable ["JB_AT_Aircraft_Routes", []];
	private _index = _routes findIf { _x select 0 == _key };
	if (_index == -1) exitWith {};

	private _stops = _routes select _index select 1;
	_stops sort (_transition == "departure");

	private _waypoint = [];
	private _crew = group driver _aircraft;

	private _firstStop = 0;
	private _stop = _stops select 0;
	if (_aircraft distance2D (_stop select 1) < 50) then
	{
		[leader _crew, units _crew, [_stop select 2, _stop select 3]] call JB_AT_WS_ConfigureAircraft;
		_firstStop = 1;
	};

	for "_i" from _firstStop to count _stops - 1 do
	{
		_waypoint = [_crew, (_stops select _i) select 1] call SPM_AddPatrolWaypoint;

		switch (_transition) do
		{
			case "arrival":
			{
				if (_i + 1 < count _stops) then
				{
					_stop = _stops select (_i + 1);
					[_waypoint, JB_AT_WS_ConfigureAircraft, [_stop select 2, _stop select 3]] call SPM_AddPatrolWaypointStatements;
				};
			};

			case "departure":
			{
				_stop = _stops select _i;
				[_waypoint, JB_AT_WS_ConfigureAircraft, [_stop select 2, _stop select 3]] call SPM_AddPatrolWaypointStatements;
			};
		};
	};

	if (_transition == "arrival") then
	{
		[_waypoint, { vehicle (_this select 0) land "land" }] call SPM_AddPatrolWaypointStatements;
//		_waypoint setWaypointType "tr unload";
	};
};

// Find the route with the interface stop that is closest to the specified position.  An interface stop is the last stop in the route for departures
JB_AT_ClosestInterface =
{
	params ["_routes", "_position", "_toLanding"];

	{
		(_x select 1) sort _toLanding; // If a landing point, then sort true.  If a departure point, then sort false.
	} forEach _routes;

	// Compute the distance from the specified position to the departure point of each route, then find the one closest to that point
	private _departureDistances = _routes apply { [_position distance2D (_x select 1 select 0 select 1), _x]};
	_departureDistances sort true;

	_departureDistances select 0 select 1
};

JB_AT_C_MessagePlayer =
{
	params ["_message", ["_duration", 1]];

	titleText [_message, "plain down", _duration / 10];
};

JB_AT_WS_ParadropAtMission =
{
	params ["_leader", "_units"];

	private _startPosition = getPos _leader;

	private _distanceToDropPosition = (_startPosition distance (Advance_CurrentMissionPosition select 0)) - (Advance_CurrentMissionPosition select 1);

	private _vectorToDropPosition = _startPosition vectorFromTo (Advance_CurrentMissionPosition select 0);
	private _vectorPerpendicular = [_vectorToDropPosition select 1, -(_vectorToDropPosition select 0), 0];

	private _dropPosition = _startPosition vectorAdd (_vectorToDropPosition vectorMultiply _distanceToDropPosition);

	private _crew = group _leader;
	private _waypoint = [];

	[_crew] call SPM_DeletePatrolWaypoints;

	private _startDropPosition = _dropPosition vectorAdd (_vectorPerpendicular vectorMultiply 1000);
	private _approachStartDropPosition = _startDropPosition vectorAdd (_vectorPerpendicular vectorMultiply 500) vectorAdd (_vectorToDropPosition vectorMultiply -500);
	_waypoint = [_crew, _approachStartDropPosition] call SPM_AddPatrolWaypoint;
	_waypoint = [_crew, _startDropPosition] call SPM_AddPatrolWaypoint;

	private _endDropPosition = _dropPosition vectorAdd (_vectorPerpendicular vectorMultiply -1000);
	private _departEndDropPosition = _endDropPosition vectorAdd (_vectorPerpendicular vectorMultiply -500) vectorAdd (_vectorToDropPosition vectorMultiply -500);
	_waypoint = [_crew, _endDropPosition] call SPM_AddPatrolWaypoint;
	_waypoint = [_crew, _departEndDropPosition] call SPM_AddPatrolWaypoint;

	[_waypoint, { (vehicle (_this select 0)) setVariable ["JB_AT_Aircraft_State", "returning"] }] call SPM_AddPatrolWaypointStatements;
	[_waypoint, JB_AT_WS_Return] call SPM_AddPatrolWaypointStatements;

	[vehicle _leader] call JB_AT_FlyThroughWaypoint;
};

JB_AT_FlyThroughWaypoint =
{
	params ["_aircraft"];

	private _group = group driver _aircraft;
	private _waypointIndex = currentWaypoint _group;
	private _waypoints = waypoints _group;

	if (_waypointIndex > count _waypoints) exitWith { diag_log "JB_AT_FlyThroughWaypoint: Aircraft has no waypoints" };

	private _startPosition = getPos _aircraft;
	if (_waypointIndex <= count _waypoints - 2) then	{ _startPosition = waypointPosition (_waypoints select count _waypoints - 2) };
	_endPosition = waypointPosition (_waypoints select count _waypoints - 1);

	private _vector = _startPosition vectorFromTo _endPosition;

	[_group, _endPosition vectorAdd (_vector vectorMultiply 200)] call SPM_AddPatrolWaypoint;
};

JB_AT_Return =
{
	params ["_aircraft"];

	private _crew = group driver _aircraft;

	[_crew] call SPM_DeletePatrolWaypoints;

	private _routes = _aircraft getVariable ["JB_AT_Aircraft_Routes", []];
	private _arrivalRoute = [_routes, getPos _aircraft, false] call JB_AT_ClosestInterface;
	_waypoint = [_crew, _arrivalRoute select 1 select 0 select 1] call SPM_AddPatrolWaypoint;

	[_waypoint, { (vehicle (_this select 0)) setVariable ["JB_AT_Aircraft_State", "arriving"] }] call SPM_AddPatrolWaypointStatements;
	[_waypoint, JB_AT_WS_Arrive] call SPM_AddPatrolWaypointStatements;

	[_aircraft] call JB_AT_FlyThroughWaypoint;
};

JB_AT_WS_Return =
{
	params ["_leader", "_units"];

	[vehicle _leader] call JB_AT_Return;
};

JB_AT_WS_Arrive =
{
	params ["_leader", "_units"];

	private _aircraft = vehicle _leader;
	private _crew = group _leader;

	[_crew] call SPM_DeletePatrolWaypoints;

	private _routes = _aircraft getVariable ["JB_AT_Aircraft_Routes", []];
	private _arrivalRoute = [_routes, getPos _aircraft, false] call JB_AT_ClosestInterface;
	[_aircraft, _arrivalRoute select 0, "arrival"] call JB_AT_Transition;
};

JB_AT_TransportLoopCurrentMission =
{
	params ["_aircraft", "_height", "_speed"];

	private _departureTime = 1e30;
	private _currentMissionPosition = [];
	private _haveAdvanceDestination = { (["Advance"] call JB_MP_GetParamValueText) == "Started" && { not isNil "Advance_CurrentMissionPosition" } && { count Advance_CurrentMissionPosition > 0 } };

	_aircraft setVariable ["JB_AT_Aircraft_State", "idle"];

	while { alive _aircraft } do
	{
		private _playersOnBoard = crew _aircraft select { isPlayer _x };
		private _state = _aircraft getVariable "JB_AT_Aircraft_State";

		switch (_state) do
		{
			case "idle":
			{
				if (count _playersOnBoard > 0 && call _haveAdvanceDestination) then
				{
					_currentMissionPosition = Advance_CurrentMissionPosition select 0;
					_departureTime = diag_tickTime + (if ({ isPlayer _x } count (_aircraft nearEntities [["Man"], 70]) > 0) then { 30 } else { 15 });
					_aircraft setVariable ["JB_AT_Aircraft_State", "ready-to-depart"];
					_aircraft engineOn true;
				};
			};

			case "ready-to-depart":
			{
				switch (true) do
				{
					case (count _playersOnBoard == 0 || not (call _haveAdvanceDestination)):
					{
						_currentMissionPosition = [];
						_aircraft engineOn false;
						_departureTime = 1e30;
						_aircraft setVariable ["JB_AT_Aircraft_State", "idle"];
					};

					case (diag_tickTime >= _departureTime):
					{
						private _routes = _aircraft getVariable ["JB_AT_Aircraft_Routes", []];
						private _departureRoute = [_routes, _currentMissionPosition, false] call JB_AT_ClosestInterface;
						[_aircraft, _departureRoute select 0, "departure"] call JB_AT_Transition;
						_aircraft setVariable ["JB_AT_Aircraft_State", "departing"];

						// When the aircraft completes its departure, it sets up for the paradrop at the current mission operation
						private _waypoint = (waypoints _aircraft) select (count waypoints _aircraft - 1);
						[_waypoint, JB_AT_WS_ConfigureAircraft, [_height, _speed]] call SPM_AddPatrolWaypointStatements;
						[_waypoint, { (vehicle (_this select 0)) setVariable ["JB_AT_Aircraft_State", "paradrop"] }] call SPM_AddPatrolWaypointStatements;
						[_waypoint, JB_AT_WS_ParadropAtMission] call SPM_AddPatrolWaypointStatements;

						[_aircraft] call JB_AT_FlyThroughWaypoint;
					};

					default
					{
						private _destination = [_currentMissionPosition] call SPM_Util_PositionDescription;
						private _message = format ["Departure for paradrop at %1 in %2...", _destination, [_departureTime - diag_tickTime, "MM:SS"] call BIS_fnc_secondsToString];
						[_message] remoteExec ["JB_AT_C_MessagePlayer", _playersOnBoard];
					};
				};
			};

			case "departing":
			{
			};

			case "paradrop";
			case "returning":
			{
				if (count _playersOnBoard == 0 || not (call _haveAdvanceDestination)) then //TODO: This will send aircraft home if an AO completes
				{
					if (_state == "paradrop") then
					{
						_aircraft setVariable ["JB_AT_Aircraft_State", "returning"];
						[_aircraft] call JB_AT_Return;
					};
				}
				else
				{
					if (count _currentMissionPosition > 0) then
					{
						if (count Advance_CurrentMissionPosition == 0) then
						{
							_currentMissionPosition = [];
							["Waiting for new operation", 10] remoteExec ["JB_AT_C_MessagePlayer", _playersOnBoard];
							[_aircraft] call SPM_DeletePatrolWaypoints;
						};
					}
					else
					{
						if (count Advance_CurrentMissionPosition > 0) then
						{
							_currentMissionPosition = Advance_CurrentMissionPosition select 0;
							private _destination = [_currentMissionPosition] call SPM_Util_PositionDescription;
							private _message = format ["Rerouting to paradrop at %1", _destination];
							[_message, 5] remoteExec ["JB_AT_C_MessagePlayer", _playersOnBoard];

							[_aircraft, _height, _speed] call JB_AT_ConfigureAircraft;
							_aircraft setVariable ["JB_AT_Aircraft_State", "paradrop"];
							[driver _aircraft, units group driver _aircraft] call JB_AT_WS_ParadropAtMission;
						};
					};
				}
			};

			case "arriving":
			{
				if ((getPosATL _aircraft select 2) < 1) then
				{
					_aircraft engineOn false;
					_aircraft setVariable ["JB_AT_Aircraft_State", "idle"];
				};
			};
		};

		sleep 1;
	};
};