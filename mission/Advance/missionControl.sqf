#include "..\..\SPM\strongpoint.h"
#ifdef TEST
#define DELAY_AT_END_OF_OPERATION 0
#define DELAY_BETWEEN_OPERATIONS 0
#define DELAY_BETWEEN_OPERATIONAL_ADVANCES 5
#define DELAY_BEFORE_COUNTERATTACK 5
#else
#define DELAY_AT_END_OF_OPERATION 45
#define DELAY_BETWEEN_OPERATIONS (10 + random 5)
#define DELAY_BETWEEN_OPERATIONAL_ADVANCES (30 + random 30)
#define DELAY_BEFORE_COUNTERATTACK (10 + random 10)
#endif

// The faction influence applied in areas where no other influence has been specified
#define INFLUENCE_DEFAULT_FACTION "csat"
#define INFLUENCE_DEFAULT_LEVEL 100

// Distances which operations should stay from base and other strongpoints
#define STANDOFF_BASE 200
#define STANDOFF_STRONGPOINT 2000

// If a operation marker does not describe an area, go with a circle of radius OPERATION_SEARCH_RADIUS
#define OPERATION_SEARCH_RADIUS 200

#define SITE_IMPORTANCE_LIMIT 2.5

Advance_Sites = []; // [description, position, reserve-multiplier]
Advance_CurrentMission = OO_NULL;

OO_TRACE_DECL(Advance_GetGridSites) =
{
	private _sites = [];

	private _gridSpacing = ["AdvanceGridSiteSpacing"] call JB_MP_GetParamValue;

	for "_x" from 0 to worldSize / _gridSpacing do
	{
		for "_y" from 0 to worldSize / _gridSpacing do
		{
			private _position = [(_x * _gridSpacing) + random _gridSpacing, (_y * _gridSpacing) + random _gridSpacing, 0];
			if (not surfaceIsWater _position) then
			{
				_sites pushBack [[_position] call SPM_Util_PositionDescription, _position, -1];
			};
		};
	};

	_sites
};

OO_TRACE_DECL(Advance_GetSites) =
{
	params ["_siteMarkers"];

	//private _sites = [] call Advance_GetGridSites;
	private _sites = [];

	private _position = [];

	{
		switch (markerShape _x) do
		{
			case "ELLIPSE":
			{
				private _radius = (getMarkerSize _x) select 0; // Only circles are supported

				for "_i" from 1 to 100 do
				{
					_position = (getMarkerPos _x) vectorAdd [-_radius + random (_radius * 2), -_radius + random (_radius * 2), 0];
					if (_position distance2D getMarkerPos _x <= _radius && { not surfaceIsWater _position }) exitWith {};
				};
			};

			case "RECTANGLE":
			{
				private _size = getMarkerSize _x;

				for "_i" from 1 to 100 do
				{
					_position = [-(_size select 0) + random ((_size select 0) * 2), -(_size select 1) + random ((_size select 1) * 2), 0];
					_position = [_position, markerDir _x] call SPM_Util_RotatePosition2D;
					_position = _position vectorAdd (getMarkerPos _x);

					if (not surfaceIsWater _position) exitWith {};
				};
			};

			default
			{
				for "_i" from 1 to 100 do
				{
					_position = (getMarkerPos _x) vectorAdd [-OPERATION_SEARCH_RADIUS + random (OPERATION_SEARCH_RADIUS * 2), -OPERATION_SEARCH_RADIUS + random (OPERATION_SEARCH_RADIUS * 2), 0];
					if (not surfaceIsWater _position) exitWith {};
				};
			};
		};

		if (not surfaceIsWater _position) then
		{
			(_x splitString "_") params ["_spm", "_mo", "_name", ["_reserveMultiplier", "-1", [""]]];
			_sites pushBack [_name, _position, parseNumber _reserveMultiplier];
		};
	} forEach _siteMarkers;

	// Remove any operations that are known to be too close to a static base area
	private _baseBlacklist = [STANDOFF_BASE, -1, -1] call SERVER_OperationBlacklist;
	_sites = _sites select { _position = _x select 1; _baseBlacklist findIf { [_position, _x] call SPM_Util_PositionInArea } == -1 };

	_sites
};

Advance_StructureImportance =
[
	["Structures_Military", 0.00010],
	["Structures_Fortifications", 0.00010],
	["Structures_Industrial", 0.00008],
	["Structures_Transport", 0.00008],
	["Structures_Infrastructure", 0.00008],
	["Structures_Town", 0.00005],
	["Structures_Commercial", 0.00005],
	["Structures_Village", 0.00004]
];

Advance_GetSiteImportance =
{
	params ["_sitePosition", "_controlRadius"];

	// Check to see if it's some labeled location of significance

	private _weight = 0.0;

	private _locals = nearestLocations [_sitePosition, ["NameLocal"], _controlRadius];
	_weight = _weight + 1.0 * ({ text _x == "storage" } count _locals);
	_weight = _weight + 1.5 * ({ text _x == "factory" } count _locals);
	_weight = _weight + 1.5 * ({ text _x == "power plant" } count _locals);
	_weight = _weight + 2.5 * ({ text _x == "military" } count _locals);

	// Otherwise, look at the buildings in the garrisoned area to determine its importance

	private _boundingBox = [];
	private _corner1 = [];
	private _corner2 = [];
	private _width = 0;
	private _height = 0;
	private _importance = 0;
		
	{
		_importance = [Advance_StructureImportance, getText (configFile >> "CfgVehicles" >> typeOf _x >> "vehicleClass")] call BIS_fnc_getFromPairs;
		if (not isNil "_importance") then
		{
			_boundingBox = boundingBoxReal _x;
			_corner1 = _boundingBox select 0;
			_corner2 = _boundingBox select 1;
			_width = (_corner2 select 0) - (_corner1 select 0);
			_length = (_corner2 select 1) - (_corner1 select 1);

			_weight = _weight + (_width * _length) * _importance
		};

	} forEach (_sitePosition nearObjects ["House", _controlRadius]);

	_weight
};

OO_TRACE_DECL(Advance_NoMedicNearby) =
{
	params ["_soldier", "_distance"];

	{ _x getUnitTrait "medic" && { _x distance2D _soldier < _distance } && { lifestate _x in ["HEALTHY", "INJURED"] } && { side _x == side _soldier } && { not (_x isKindOf "HeadlessClient_F") } } count allPlayers == 0
};

// Cover (trees and rocks) per square meter versus garrison radius multiplier (greater density means smaller areas)
Advance_CoverDensityMap =
[
	[0.0000, 1.5],
	[0.0029, 1.25],
	[0.0080, 1.0],
	[100, 1.0]
];

Advance_KnownOperations = [];

OO_TRACE_DECL(Advance_AnimateEnemyControl) =
{
	_this spawn
	{
		params ["_areaPosition", "_areaRadius", "_delay", "_waveDuration", "_getExpansionTime", "_getExpansionInterval"];

		private _marker = createMarker [format ["ADVANCE_EHA_%1_%2", floor (_areaPosition select 0), floor (_areaPosition select 1)], _areaPosition]; // Enemy held area marker
		_marker setMarkerShape "ellipse";
		_marker setMarkerColor "colorred";
		_marker setMarkerAlpha 0.0;
		_marker setMarkerBrush "solid";
		_marker setMarkerSize [1, 1];

		private _arty_mark = createMarker [format ["ARTY_ZONE_%1_%2", floor (_areaPosition select 0), floor (_areaPosition select 1)], _areaPosition];
		_arty_mark setMarkerType "Minefield";
		_arty_mark setMarkerColor "colorOPFOR";
		_arty_mark setMarkerText "Active Artillery Zone";

		private _border = createMarker [_marker + "_BORDER", _areaPosition]; // The limit of expansion
		_border setMarkerShape "ellipse";
		_border setMarkerColor "colorred";
		_border setMarkerAlpha 1.0;
		_border setMarkerBrush "border";
		_border setMarkerSize [_areaRadius, _areaRadius];

		private _message = if (_delay < 2) then { "LEAVE THIS AREA.  ENEMY FORCES ARE TAKING CONTROL." } else { format ["LEAVE THIS AREA.  ENEMY FORCES WILL BEGIN TAKING CONTROL IN %1 SECONDS.", round _delay] };
		{
			[_message, 2] remoteExec ["JB_fnc_showBlackScreenMessage", _x];
		} forEach (allPlayers select { _x distance _areaPosition < _areaRadius });
	
		sleep _delay;

		private _steps = [call _getExpansionInterval]; 
		_waveDuration = _waveDuration + (_steps select 0); // We're going to expand the first interval at time zero. 
 
		while { _steps select (count _steps - 1) < _waveDuration } do 
		{ 
			_steps pushBack (((call _getExpansionInterval) + (_steps select (count _steps - 1))) min _waveDuration); 
		}; 
 
		_steps = _steps apply { [_x, _areaRadius * _x / _waveDuration] }; 

		private _step = [];
		private _expansionTime = 0;
		while { count _steps > 0 } do
		{
			_step = _steps deleteAt 0;
			_expansionTime = call _getExpansionTime;
			[_areaPosition, _step select 1, _expansionTime] remoteExec ["CLIENT_ExpandEnemyControl", 0];
			sleep _expansionTime;
			_marker setMarkerSize [_step select 1, _step select 1];
			if (count _steps > 0) then { sleep ((_steps select 0 select 0) - (_step select 0) - _expansionTime) };
		};

		sleep 1.0;

		_marker setMarkerAlpha 0.5;

		[_areaPosition, -1, 0] remoteExec ["CLIENT_ExpandEnemyControl", 0];

		deleteMarker _border;
	};
};

OO_TRACE_DECL(Advance_RunMission) =
{
	params ["_mission"];

	private _position = +OO_GET(_mission,Strongpoint,Position);
	private _controlRadius = OO_GET(_mission,Strongpoint,ControlRadius);

	private _missionScript = [_mission] spawn
		{
			params ["_mission"];

			scriptName "RunMission";

			[] call OO_METHOD(_mission,Strongpoint,Run);
		};

	Advance_CurrentMission = _mission;
	missionNamespace setVariable ["Advance_CurrentMissionPosition", [_position, OO_GET(_mission,Strongpoint,ActivityRadius)], true];

	while { OO_GET(_mission,Mission,MissionState) == "unresolved" && not (OO_GET(_mission,Strongpoint,RunState) in ["stopped", "deleted"]) } do
	{
		sleep 1;
	};

	Advance_CurrentMission = OO_NULL;
	missionNamespace setVariable ["Advance_CurrentMissionPosition", [], true];

	if (OO_GET(_mission,Mission,MissionState) == "completed-failure") then
	{
		[_position, _controlRadius, 10, 120, { 2 + random 2 }, { 10 + random 10 }] call Advance_AnimateEnemyControl;
	};

	if (serverTime > MissionEndTime) then {
		["end1", true] remoteExec ["BIS_fnc_endMission"];
	};
};

OO_TRACE_DECL(Advance_ControlRadius) =
{
	params ["_numberUnits"];

	private _areaPerUnit = ["AdvanceAreaPerUnit"] call JB_MP_GetParamValue; // m^2
	private _controlRadius = sqrt ((_numberUnits * _areaPerUnit) / pi);
	_controlRadius = _controlRadius max 50;

	_controlRadius
};

// Note that the reserve is determined by the initial population AFTER limits are applied to it.  For example, if the initial population should be 200 with a site importance of 2.5, then the reserve
// would be 450 if there were no limits.  But if the infantry upper limit is 100, then the initial population will be 100 and the reserve will be 100 * 2.5, or 250.
OO_TRACE_DECL(Advance_ExecuteOperation) =
{
	params ["_siteName", "_sitePosition", "_siteImportance"];

	private _numberPlayers = call SPM_Util_NumberPlayers;
	private _garrisonCount = ((_numberPlayers * (["NumberInfantryPerPlayer"] call JB_MP_GetParamValue)) max (["MinimumInfantryPerOperation"] call JB_MP_GetParamValue)) min (["MaximumInfantryPerOperation"] call JB_MP_GetParamValue);
	private _controlRadius = [_garrisonCount] call Advance_ControlRadius;

	_siteImportance = [_sitePosition, _controlRadius] call Advance_GetSiteImportance;
	_siteImportance = _siteImportance min SITE_IMPORTANCE_LIMIT;

	// Possibly enlarge the radius if minimal cover
	private _cover = (count nearestTerrainObjects [_sitePosition, ["tree", "rock"], _controlRadius, false, true]) * 1.0 + (count (_sitePosition nearObjects ["House", _controlRadius])) * 5.0;
	private _density = _cover / (pi * _controlRadius * _controlRadius);
	_controlRadius = _controlRadius * ([_density, Advance_CoverDensityMap] call SPM_Util_MapValueRange);

	// Determine the influence of various factions
	private _influence = [["csat", 0], ["aaf", 0], ["fia", 0], ["syndikat", 0]];
	{
		if (_sitePosition inArea (_x select 2)) then
		{
			private _index = [_influence, _x select 0] call BIS_fnc_findInPairs;
			if (_index != -1) then { (_influence select _index) set [1, _x select 1] };
		};
	} forEach Advance_Influence;

	private _totalInfluence = 0.0; { _totalInfluence = _totalInfluence + (_x select 1) } forEach _influence;
	_influence = _influence apply { [_x select 0, (_x select 1) / _totalInfluence ] };

	// If the site importance translates to an insignificant reserve, don't bother with a reserve
	private _garrisonReserves = if (_siteImportance < 0.2) then { 0 } else { _garrisonCount * _siteImportance };

#ifndef TEST_COUNTERATTACK
	// Create the mission and add the factions
	private _mission = [_siteName, _sitePosition, _controlRadius] call OO_CREATE(MissionAdvance);
	{
		[(_x select 0), _garrisonCount * (_x select 1), _garrisonCount * (_x select 1), _garrisonReserves * (_x select 1), _x select 1] call OO_METHOD(_mission,MissionAdvance,AddFaction);
	} forEach _influence;

	private _missionResult = "";

	// If no faction wants to be involved, skip the whole thing
	if (count OO_GET(_mission,Mission,Objectives) == 0) exitWith { call OO_DELETE(_mission) };

	[_mission] call Advance_RunMission;

	// If the mission system is stopped, we're out
	if ((["Advance"] call JB_MP_GetParamValueText) != "Started") exitWith {};

	// If the mission wasn't a success, no counterattack
	if (OO_GET(_mission,Mission,MissionState) != "completed-success") exitWith {};

	// If the enemy doesn't want to counterattack, no counterattack
	if (random 100 > ((["CounterattackProbability"] call JB_MP_GetParamValue) * _siteImportance)) exitWith {};
#endif

	// Counterattack

	// No initial garrison, so add them to the attacking reserve
	_garrisonReserves = _garrisonReserves + _garrisonCount;
	_mission = [_siteName + " (counterattack)", _sitePosition, _controlRadius] call OO_CREATE(MissionAdvance);
	{
		[(_x select 0), _garrisonCount * (_x select 1), 0, _garrisonReserves * (_x select 1), _x select 1] call OO_METHOD(_mission,MissionAdvance,AddFaction);
	} forEach _influence;

	// Only counterattack if any enemies are interested
	if (count OO_GET(_mission,Mission,Objectives) == 0) exitWith { call OO_DELETE(_mission) };

	// Delay before the counterattack, making sure to skip it if the advance is stopped during the delay
	if (not ([{ (["Advance"] call JB_MP_GetParamValueText) != "Started" }, DELAY_BEFORE_COUNTERATTACK] call JB_fnc_timeoutWaitUntil)) then { [_mission] call Advance_RunMission };
};

OO_TRACE_DECL(Advance_CreateAirOperations) =
{
	// Put the strongpoint center off the map so it doesn't interfere with anything.  The AirPatrol category itself patrols the whole island.

	private _airOperationsStrongpoint = [[-STANDOFF_STRONGPOINT,-STANDOFF_STRONGPOINT,0], 10, 10] call OO_CREATE(Strongpoint);
	OO_SET(_airOperationsStrongpoint,Strongpoint,Name,"Advance Air Patrol");

	private _patrolArea = [[worldSize/2.0,worldSize/2.0,0], 0, 10] call OO_CREATE(StrongpointArea);
	private _airPatrol = [_patrolArea] call OO_CREATE(AirPatrolCategory);
	OO_SET(_airPatrol,ForceCategory,RatingsWest,SPM_AirPatrol_RatingsWest);
	OO_SET(_airPatrol,ForceCategory,RatingsEast,SPM_AirPatrol_RatingsEast);
	OO_SET(_airPatrol,ForceCategory,CallupsEast,SPM_AirPatrol_CallupsEast);
	OO_SET(_airPatrol,ForceCategory,RangeWest,worldSize);
	OO_SET(_airPatrol,ForceCategory,UnitsCanRetire,true);
	OO_SET(_airPatrol,AirPatrolCategory,PatrolType,"target");

	[_airPatrol] call OO_METHOD(_airOperationsStrongpoint,Strongpoint,AddCategory);

	private _airOperationsScript = [_airOperationsStrongpoint] spawn
	{
		params ["_airOperationsStrongpoint"];
		scriptName "AirPatrolStrongpoint_Run";
		[] call OO_METHOD(_airOperationsStrongpoint,Strongpoint,Run);
	};

	[_airOperationsStrongpoint, _airPatrol, _airOperationsScript]
};

OO_TRACE_DECL(Advance_DeleteAirOperations) =
{
	params ["_airOperations"];

	if (count _airOperations == 0) exitWith {};

	[_airOperations select 0, _airOperations select 2] spawn
	{
		params ["_airOperationsStrongpoint", "_airOperationsScript"];

		[] call OO_METHOD(_airOperationsStrongpoint,Strongpoint,Stop);
		[_airOperationsStrongpoint] call OP_S_NotifyRemovedMission;

		waitUntil { sleep 1; scriptDone _airOperationsScript};

		call OO_DELETE(_airOperationsStrongpoint);
	};

	while { count _airOperations > 0 } do { _airOperations deleteAt 0 };
};

OO_TRACE_DECL(Advance_ExecuteOperationalAdvance) =
{
	params ["_sites", "_completedSites"];

	private _airOperations = [];

	// Random start
	private _siteIndex = floor random count _sites;

	// Or site closest to mark with text of ADVANCE_START
	private _markers = allMapMarkers select { markerText _x == "ADVANCE_START" };
	if (count _markers > 0) then
	{
		private _position = getMarkerPos (_markers select 0);
		private _closestDistance = 1e30;
		{
			_distance = _position distance (_x select 1);
			if (_distance < _closestDistance) then { _closestDistance = _distance; _siteIndex = _forEachIndex };
		} forEach _sites;
	};

	private _site = _sites deleteAt _siteIndex;
	private _direction = (_site select 1) getDir [worldSize / 2, worldSize / 2, 0]; // Start out moving towards the center of the map

	private _siteDistance = 0.0;
	private _offset = 0.0;

	private _playerSpacingPad = 0.0;
	private _minSpacing = 0.0;
	private _maxSpacing = 0.0;
	private _minSpacingIdeal = 0.0;
	private _maxSpacingIdeal = 0.0;
	private _minRange = 0.0;
	private _maxRange = 0.0;
	private _deviationAngle = ["AdvanceDeviationAngle"] call JB_MP_GetParamValue;
	
	private _blacklist = [];

	private _capitalWeight = 0.0;
	private _cityWeight = 0.0;
	private _villageWeight = 0.0;
	private _directionWeight = 0.0;
	private _locationDistance = 0.0;
	private _position = [];

	private _neighbors = [];
	private _neighborsIdeal = [];

	private _sleepBeforeOperation = DELAY_BETWEEN_OPERATIONS;

#ifdef TEST_SHOW_ALGORITHM
	private _sleepBeforeOperation = 2.0;
	private _sitePositions = [];
	private _markerColor = "ColorRed";
	private _markerColorIndex = 0;
	private _markerColors = ["ColorRed", "ColorBlack", "ColorGreen", "ColorBrown", "ColorYellow"];
#endif

	while { (["Advance"] call JB_MP_GetParamValueText) in ["Started", "Suspended"] && count _site > 0 } do
	{
		switch (["Advance"] call JB_MP_GetParamValueText) do
		{
			case "Started":
			{
				_site params ["_siteName", "_sitePosition", "_siteImportance"];
#ifdef TEST_SHOW_ALGORITHM
				_sitePositions pushBack _sitePosition;
				[_sitePositions, "FOO", "ColorBlue"] call SPM_Util_MarkPositions;
#else
				if (count _airOperations == 0) then { _airOperations = [] call Advance_CreateAirOperations };
				private _patrolArea = OO_GET((_airOperations select 1),ForceCategory,Area);
				OO_SET(_patrolArea,StrongpointArea,Position,_sitePosition);

				[_siteName, _sitePosition, _siteImportance] call Advance_ExecuteOperation;
#endif
				_completedSites pushBack _site;

				if ([{ (["Advance"] call JB_MP_GetParamValueText) != "Started" }, _sleepBeforeOperation] call JB_fnc_timeoutWaitUntil) exitWith {};

				_playerSpacingPad = (["AdvanceSpacingPerPlayer"] call JB_MP_GetParamValue) * (call SPM_Util_NumberPlayers);
				_minSpacing = (["AdvanceSpacingMin"] call JB_MP_GetParamValue) + _playerSpacingPad;
				_maxSpacing = (["AdvanceSpacingMax"] call JB_MP_GetParamValue) + _playerSpacingPad;
				_minSpacingIdeal = (["AdvanceSpacingMinIdeal"] call JB_MP_GetParamValue) + _playerSpacingPad;
				_maxSpacingIdeal = (["AdvanceSpacingMaxIdeal"] call JB_MP_GetParamValue) + _playerSpacingPad;
#ifdef TEST_SHOW_ALGORITHM
				private _markerName = format ["ADV_MINI_%1", _siteName];
				createMarker [_markerName, _sitePosition];
				_markerName setMarkerShape "ellipse";
				_markerName setMarkerSize [_minSpacingIdeal,_minSpacingIdeal];
				_markerName setMarkerColor _markerColor;
				_markerName setMarkerBrush "border";
				_markerName setMarkerAlpha 1.0;

				private _markerName = format ["ADV_MAXI_%1", _siteName];
				createMarker [_markerName, _sitePosition];
				_markerName setMarkerShape "ellipse";
				_markerName setMarkerSize [_maxSpacingIdeal,_maxSpacingIdeal];
				_markerName setMarkerColor _markerColor;
				_markerName setMarkerBrush "border";
				_markerName setMarkerAlpha 1.0;
#endif
				_minRange = (_minSpacingIdeal - _minSpacing) min -1.0; // Avoid divide-by-zero errors
				_maxRange = (_maxSpacing - _maxSpacingIdeal) max 1.0;

				_neighbors = []; { _neighbors pushBack [_sitePosition distance (_x select 1), _forEachIndex] } forEach _sites; // [distance, site-index]
				_neighbors = _neighbors select { (_x select 0) >= _minSpacing && (_x select 0) <= _maxSpacing };

				if (count _neighbors == 0) exitWith { _site = [] }; // Advance ends if no neighbors within range limits

				_neighbors = _neighbors apply { [_x select 0, [_direction, _sitePosition getDir (_sites select (_x select 1) select 1)] call SPM_Util_AngleBetweenDirections, 0, _x select 1] }; // [distance, deviation-angle, 0, site-index]
				_neighbors = _neighbors select { (_x select 1) <= _deviationAngle };

				if (count _neighbors == 0) exitWith { _site = [] }; // Advance ends if no neighbors within angle limits

				_blacklist = [STANDOFF_BASE, _minSpacing, -1] call SERVER_OperationBlacklist;
				_neighbors = _neighbors select { _position = _sites select (_x select 3) select 1; _blacklist findIf { [_position, _x] call SPM_Util_PositionInArea } == -1 };

				if (count _neighbors == 0) exitWith { _site = [] }; // Advance ends if all neighbors are blacklisted

				// Compute the distance each neighbor is from the ideal range of distances
				{
					_siteDistance = _x select 0;
					switch (true) do
					{
						case (_siteDistance > _maxSpacingIdeal): { _offset = (_siteDistance - _maxSpacingIdeal) };
						case (_siteDistance < _minSpacingIdeal): { _offset = (_siteDistance - _minSpacingIdeal) }; // Negative offset value to indiate 'min' side of range
						default { _offset = 0.0 };
					};
					_x set [0, _offset];
				} forEach _neighbors;

				// [distance-from-ideal, deviation-angle, 0, site-index]

				// Take the ones in the range, if any.  If not, use whatever we found in the 'non-ideal' range.
				_neighborsIdeal = _neighbors select { _x select 0 == 0.0 };
				if (count _neighborsIdeal > 0) then { _neighbors = _neighborsIdeal };

				{
					// Convert the offset into a weight (flip back the sign on the min range)
					if (_x select 0 < 0) then { _x set [0, 1.0 - (_x select 0) / -_minRange] } else { _x set [0, 1.0 - (_x select 0) / _maxRange] };

					// Compute a weight value based on how far the advance would have to turn to go to this site
					_directionWeight = 1.0 - (_x select 1) / _deviationAngle;
					_x set [1, _directionWeight * 0.5];

					// Compute a weight value based on how desirable a turn to this site would be
					_locationDistance = ((locationPosition nearestLocation [_sites select (_x select 3) select 1, "NameCityCapital"]) distance (_sites select (_x select 3) select 1));
					_locationDistance = _locationDistance max 1.0;
					_capitalWeight = ((1000*1000) / (_locationDistance * _locationDistance)) min 1.0;
					_locationDistance = ((locationPosition nearestLocation [_sites select (_x select 3) select 1, "NameCity"]) distance (_sites select (_x select 3) select 1));
					_locationDistance = _locationDistance max 1.0;
					_cityWeight = ((500*500) / (_locationDistance * _locationDistance)) min 1.0;
					_locationDistance = ((locationPosition nearestLocation [_sites select (_x select 3) select 1, "NameVillage"]) distance (_sites select (_x select 3) select 1));
					_locationDistance = _locationDistance max 1.0;
					_villageWeight = ((100*100) / (_locationDistance * _locationDistance)) min 1.0;
					_x set [2, _capitalWeight * 1.0 + _cityWeight * 0.5 + _villageWeight * 0.3];
#ifdef TEST_SHOW_ALGORITHM
					private _markerName = format ["ADV_DATA_%1", _x select 3];
					createMarker [_markerName, _sites select (_x select 3) select 1];
					_markerName setMarkerType "mil_dot";
					_markerName setMarkerText format ["D:%1 A:%2 L:%3", round ((_x select 0) * 100) / 100, round ((_x select 1) * 100) / 100, round ((_x select 2) * 100) / 100];
					_markerName setMarkerColor _markerColor;
#endif
				} forEach _neighbors;

				// [distance-weight, direction-weight, location-weight, site-index]
				_neighbors = _neighbors apply { [(_x select 0) + (_x select 1) + (_x select 2), _x select 3] };
				_neighbors sort false;

				// [weight, site-index]

				// Select all of the highest-weighted sites
				_neighbors = _neighbors select { _x select 0 > (_neighbors select 0 select 0) * 0.60 };

				_siteIndex = (selectRandom _neighbors) select 1;
				_direction = (_site select 1) getDir (_sites select _siteIndex select 1);
				_site = _sites deleteAt _siteIndex;

#ifdef TEST_SHOW_ALGORITHM
				_markerColorIndex = (_markerColorIndex + 1) mod count _markerColors;
				_markerColor = _markerColors select _markerColorIndex;
#endif
			};

			case "Suspended":
			{
				[_airOperations] call Advance_DeleteAirOperations;
				_sleepBeforeOperation = 0;
				sleep 1;
			};
		};
	};

	// Delete the air patrol component
	[_airOperations] call Advance_DeleteAirOperations;
};

OO_TRACE_DECL(Advance_PlayerConnected) =
{
	_this spawn
	{
		params ["_id", "_uid", "_name", "_jip", "_owner"];
	
		if (_name == "__SERVER__") exitWith {}; // Server declaring its creation

		private _player = objNull;
		[{ _player = [_uid] call SERVER_GetPlayerByUID; not isNull _player }, 30, 1] call JB_fnc_timeoutWaitUntil;

		if (OO_ISNULL(Advance_CurrentMission)) exitWith {};

		[_player] call OO_METHOD(Advance_CurrentMission,MissionAdvance,NotifyPlayer);
	};
};

// Markers that indicate the influence of various factions in an area.  Smaller marked areas override larger marked areas.  The
// format is SPM_INFLUENCE_side_influence_side_influence...  For example, SPM_INFLUENCE_EAST_10_GUER_10, which places equal influence to
// CSAT and Syndikat forces in the area, and doesn't alter the influence of other factions.  To differentiate multiple markers with the
// same numbers, append a "_text".  For example SPM_INFLUENCE_EAST_10_GUER_10_A and SPM_INFLUENCE_EAST_10_GUER_10_B.
Advance_Influence = [[worldSize * worldSize, INFLUENCE_DEFAULT_FACTION, INFLUENCE_DEFAULT_LEVEL, [[worldSize / 2, worldSize / 2], worldSize / 2, worldSize / 2, 0, true]]]; // Whole map has default influence

private _parts = [];
private _size = [];
private _area = [];
{
	_size = getMarkerSize _x;
	_area = [getMarkerPos _x] + _size + [markerDir _x, markerShape _x == "rectangle"];

	_parts = _x splitString "_";
	for "_i" from 1 to (count _parts - 2) / 2 do
	{
		Advance_Influence pushBack [(_size select 0) * (_size select 1), toLower (_parts select (_i * 2 + 0)), parseNumber (_parts select (_i * 2 + 1)), _area];
	};
	deleteMarker _x;
} forEach (allMapMarkers select { _x find "SPM_INFLUENCE_" == 0 });

Advance_Influence sort false; // Largest to smallest area
{ _x deleteAt 0 } forEach Advance_Influence;

private _allSiteMarkers = allMapMarkers select { _x find "SPM_MO_" == 0 };
Advance_AllSites = [_allSiteMarkers] call Advance_GetSites;
Advance_AvailableSites = + Advance_AllSites;
Advance_CompletedSites = [];
{ deleteMarker _x } forEach _allSiteMarkers;

addMissionEventHandler ["PlayerConnected", Advance_PlayerConnected];

MissionEndWarningGiven = false;
MissionEndTime = serverTime + 14400;

[] spawn {
	while {true} do {
		if (serverTime > MissionEndTime && !MissionEndWarningGiven ) then {
			[["The map will rotate after this AO is completed. Inform Zeus if you want the time extended.", "plain",1]] remoteExec ["titleText"];
			MissionEndWarningGiven = true;
		};
		sleep 15;
	};
};

while { true } do
{
	while { (["Advance"] call JB_MP_GetParamValueText) in ["Stopped", "Suspended"] } do
	{
		sleep 1;

		//if ((["Advance"] call JB_MP_GetParamValueText) == "Stopped") then { Advance_AvailableSites = [] };
	};

	if (count Advance_AvailableSites == 0) exitWith {};

	Advance_CompletedSites = [];

	private _advance = [] spawn
	{
		scriptName "ExecuteOperationalAdvance";
		
		[Advance_AvailableSites, Advance_CompletedSites] call Advance_ExecuteOperationalAdvance;
	};

	waitUntil { sleep 5; scriptDone _advance };

	// Notify everyone that the advance is over
	private _sleep = 0;
	if ((["Advance"] call JB_MP_GetParamValueText) == "Started" && count Advance_CompletedSites > 2) then
	{
		["NotificationEndAdvance", ["This operational advance is complete."]] remoteExec ["BIS_fnc_showNotification", 0];
		_sleep = DELAY_BETWEEN_OPERATIONAL_ADVANCES;
	};

	// Sleep between advances
	[{ (["Advance"] call JB_MP_GetParamValueText) != "Started" }, _sleep] call JB_fnc_timeoutWaitUntil;
};

["end1", true] remoteExec ["BIS_fnc_endMission"];
