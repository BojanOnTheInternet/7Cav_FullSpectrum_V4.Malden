// If a player is moving faster than this speed (m/s) then they are not considered to be near a container and it can be considered abandoned
JB_CG_ABANDON_SPEED = 6.0;

// An empty container can stay empty for a limited time before it is deleted
JB_CG_CLEANUP_DELAY = 120;

// JB_CS_AbandonParameters [abandon-distance, abandon-time]

JB_CG_GetEmptyContainerCondition =
{
	params ["_containerType"];

	if (vehicle player != player) exitWith { false };

	if (not (lifeState player in ["HEALTHY", "INJURED"])) exitWith { false };

	if (not isNull ([player] call JB_CO_CarriedObject)) exitWith { false };

	true
};

JB_CG_GetEmptyContainer =
{
	params ["_source", "_containerType", "_abandonDistance", "_abandonDelay"];

	private _container = _containerType createVehicle (call JB_MDI_RandomSpawnPosition);
	[_container] call JB_fnc_containerClear;
	[_container, _abandonDistance, _abandonDelay] remoteExec ["JB_CG_S_AddContainer", 2];

	[_container] call JB_fnc_carryObjectInitObject;
	[_container] call JB_fnc_carryObjectPickUp;
};

JB_CG_SourceSetupClient =
{
	params ["_source", "_containerType", "_abandonDistance", "_abandonDelay"];

	_source addAction [format ["Get empty %1 from %2", [_containerType] call JB_fnc_displayName, [typeOf _source] call JB_fnc_displayName], compile format ["[_this select 0, ""%1"", %2, %3] call JB_CG_GetEmptyContainer", _containerType, _abandonDistance, _abandonDelay], nil, 0, false, true, "", format ["[""%1""] call JB_CG_GetEmptyContainerCondition", _containerType], 5];
};

if (not isServer && hasInterface) exitWith {};

JB_CG_CS = call JB_fnc_criticalSectionCreate;

JB_CG_Monitor = scriptNull;
JB_CG_Containers = [];

JB_CG_S_AddContainer =
{
	params ["_container", "_abandonDistance", "_abandonDelay"];

	_container setVariable ["JB_CG_AbandonParameters", [_abandonDistance, _abandonDelay]];

	JB_CG_CS call JB_fnc_criticalSectionEnter;

		JB_CG_Containers pushBack _container;

		if (isNull JB_CG_Monitor) then { JB_CG_Monitor = [] spawn JB_CG_MonitorContainers };

	JB_CG_CS call JB_fnc_criticalSectionLeave;
};

JB_CG_MonitorContainers =
{
	private _container = objNull;
	private _containers = [];
	private _discardedContainers = [];

	private _velocity = [];
	private _position = [];
	private _abandonDelay = 0;
	private _abandonParameters = [];

	private _nearbyPlayerIndex = -1;
	private _abandonTime = 0;
	private _empty = false;
	private _cleanupTime = 0;

	while { true } do
	{
		_containers = +JB_CG_Containers;
		_discardedContainers = [];

		for "_i" from count _containers - 1 to 0 step -1 do
		{
			_container = _containers select _i;

			if (isNull _container) then
			{
				_discardedContainers pushBack _container;
			}
			else
			{
				_currentlyAbandoned = true;
				_velocity = velocity _container;
				_position = getPosASL _container;

				// If somewhere on the world map, check to see if it has been abandoned or has been left empty for too long a time
				if (_position findIf { _x < 0 || _x > worldSize } in [-1,2]) then
				{
					_abandonParameters = _container getVariable "JB_CG_AbandonParameters";
					_abandonTime = _container getVariable ["JB_CG_AbandonTime", 1e30];
					_cleanupTime = _container getVariable ["JB_CG_CleanupTime", 1e30];
			
					_nearbyPlayerIndex = (allPlayers select { not (_x isKindOf "HeadlessClient_F") }) findIf { ((getPosASL _x distance _position) <= (_abandonParameters select 0) && vectorMagnitude (_velocity vectorDiff (velocity _x)) < JB_CG_ABANDON_SPEED) };
					_abandonTime = if (_nearbyPlayerIndex != -1) then { 1e30 } else { _abandonTime min (diag_tickTime + (_abandonParameters select 1)) };
					_container setVariable ["JB_CG_AbandonTime", _abandonTime];

					_empty = [_container] call JB_fnc_containerIsEmpty;
					_cleanupTime = if (not _empty) then { 1e30 } else { _cleanupTime min (diag_tickTime + JB_CG_CLEANUP_DELAY) };
					_container setVariable ["JB_CG_CleanupTime", _cleanupTime];

					if (_abandonTime < diag_tickTime || _cleanupTime < diag_tickTime) then { _discardedContainers pushBack _container };
				};
			};
		};

		if (count _discardedContainers > 0) then
		{
			JB_CG_CS call JB_fnc_criticalSectionEnter;

				JB_CG_Containers = JB_CG_Containers - _discardedContainers;

			JB_CG_CS call JB_fnc_criticalSectionLeave;

			for "_i" from count _discardedContainers - 1 to 0 step -1 do
			{
				_container = _discardedContainers select _i;
				if (not isNull _container) then
				{
					_container setVelocity [0,0,1]; sleep 0.1; // Jostle the object to cause nearby objects to react to its movement
					deleteVehicle _container;
				};
			};
		};

		sleep 5;
	};
};
