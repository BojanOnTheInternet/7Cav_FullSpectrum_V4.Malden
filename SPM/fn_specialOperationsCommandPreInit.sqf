/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include "strongpoint.h"

OO_TRACE_DECL(SPM_MissionInterceptCourier_InteractionCondition) =
{
	params ["_target", "_player"];

	if (side _target == east) exitWith { false };

	if (speed _target > 0) exitWith { false };

	private _distance = ([getPos _player, _target, 5] call JB_fnc_distanceToObjectSurface) select 2;

	if (_distance < 0.0 || _distance > 3.5) exitWith { false };

	true
};

OO_TRACE_DECL(SPM_MissionInterceptCourier_Interaction) =
{
	_this spawn
	{
		params ["_target", "_caller"];

		private _doors = ["door_rf", "door_lf", "door_rm", "door_lm", "door_rear"];

		while { count _doors > 0 } do
		{
			[_target, [_doors deleteAt (floor random count _doors), 1]] remoteExec ["animateDoor", _target];
			sleep 0.5 + (random 0.5);
		};
	};
};

if (not isServer && hasInterface) exitWith {};

#ifdef TEST
#define MISSION_REVIEW_DELAY 10
#define CONVOY_START_DELAY 10
#else
#define MISSION_REVIEW_DELAY 120
#define CONVOY_START_DELAY (60 + random 120)
#endif

SPM_SOC_PaddedBlacklist =
{
	params ["_blacklist", "_distance"];

	_blacklist = +_blacklist;
	{
		_x set [0, (_x select 0) + _distance];
	} forEach _blacklist;

	_blacklist
};

SPM_Chain_PositionToConvoyRoute =
{
	params ["_data", "_direction", "_distanceToRoad", "_lengthOfRoute", "_blacklist"];

	private _roads = [];

	if (_direction == -1) then
	{
		_roads = [_data, "convoy-start-roads"] call SPM_Util_GetDataValue;
	}
	else
	{
		private _position = [_data, "position"] call SPM_Util_GetDataValue;

		_roads = [];
		{
			private _road = _x;
			{
				_roads pushBack [_road, _x];
			} forEach roadsConnectedTo _x;
		} forEach (_position nearRoads _distanceToRoad);

		[_data, "convoy-start-roads", _roads] call SPM_Util_SetDataValue;
	};

	private _route = [];

	while { count _roads > 0 } do
	{
		private _road = _roads deleteAt (floor random count _roads);

		_route = [_road select 0, _road select 1, (_road select 0) getDir (_road select 1), _lengthOfRoute, _blacklist] call SPM_Nav_FollowRoute;

		if (count _route > 0) exitWith
		{
			// Remove visited road segments near to the start point from our list of start roads.  No point in duplicating a search on the same path.
			private _nearbyRoads = _route select [0, floor (_distanceToRoad / 10)];
			{
				private _nearbyRoad = _x;
				{ if (_x select 1 == _nearbyRoad) exitWith { _roads deleteAt _forEachIndex } } forEach _roads;
			} forEach _nearbyRoads;

			[_data, "convoy-start-roads", _roads] call SPM_Util_SetDataValue;
		};
	};

	if (count _route == 0) exitWith { false };

#ifdef OO_TRACE
	diag_log format ["SPM_Chain_PositionToConvoyRoute: from %1 to %2 (direct %3m)", _route select 0, _route select (count _route - 1), (_route select 0) distance (_route select (count _route - 1))];
#endif
	[_data, "convoy-route", _route] call SPM_Util_SetDataValue;

	true
};

OO_TRACE_DECL(SPM_SOC_SendNotification) =
{
	params ["_mission", "_origin", "_message", "_type"];

	if (OO_GET(_mission,Mission,Announced) == "none") exitWith
	{
		OO_GET(_mission,Mission,NotificationsAccumulator) pushBack [OO_REFERENCE(_mission), OO_REFERENCE(_origin), _message, _type];
	};

	switch (_type) do
	{
		case "mission-description";
		case "mission-status":
		{
			[_message, ["log-specops", "printout-specops"], OO_GET(_mission,Mission,ParticipantFilter)] call SPM_Mission_Message;
		};

		case "objective-status";
		case "objective-description":
		{
			if (OO_GET(_mission,Mission,MissionState) == "unresolved") then
			{
				[_message, ["log-specops", "printout"], OO_GET(_mission,Mission,ParticipantFilter)] call SPM_Mission_Message;
			};
		};

		case "event":
		{
			if (OO_GET(_mission,Mission,MissionState) == "unresolved") then
			{
				[_message, ["printout"], OO_GET(_mission,Mission,ParticipantFilter)] call SPM_Mission_Message;
			};
		};
	};
};

OO_TRACE_DECL(SPM_SOC_MissionInterceptConvoy) =
{
	params ["_soc", "_escortType"];

	_convoyStartTime = diag_tickTime + CONVOY_START_DELAY;

	private _referencePosition = OO_GET(_soc,SpecialOperationsCommand,ReferencePosition);
	private _blacklist = ([1000, 2000, -1] call SERVER_OperationBlacklist) + ([OO_GET(_soc,SpecialOperationsCommand,Blacklist), 1000] call SPM_SOC_PaddedBlacklist);

	// Generate the convoy route

	private _data = [];
	private _chain =
		[
			[SPM_Chain_NearestLocation, [_referencePosition, 10000, ["NameLocal", "NameVillage","NameCity","NameCityCapital"]]],
			[SPM_Chain_PositionToIsolatedPosition, [_blacklist]],
			[SPM_Chain_PositionToConvoyRoute, [100, 6000, _blacklist]]
		];
	private _complete = [_data, _chain] call SPM_Chain_Execute;

	if (not _complete) exitWith { OO_NULL }; // This shouldn't happen

	private _convoyRoute = [_data, "convoy-route"] call SPM_Util_GetDataValue;
	private _convoyPositions = _convoyRoute apply { getPos _x };
	_convoyPositions deleteAt 0; // Move away from starting intersection

	// Spacing before a given vehicle
	private _normalSpacing = [] call OO_CREATE(ConvoySpacing);
	private _wideSpacing = [50^2, 60^2, 80^2, 100^2, 150^2] call OO_CREATE(ConvoySpacing);

	private _teamDescriptor = [(configfile >> "CfgGroups" >> "East" >> "LOP_US" >> "Infantry" >> "LOP_US_FT_section")] call SPM_fnc_groupFromConfig;

	private _convoyDescription = [];

	switch (_escortType) Do
	{
		case 1:
		{
			_convoyDescription pushBack (["LOP_US_UAZ_DshKM", [{},[0]], [], _normalSpacing] call OO_CREATE(ConvoyVehicle));
			_convoyDescription pushBack (["rhs_tigr_m_vdv", [{},[0]], [_teamDescriptor, _teamDescriptor], _wideSpacing] call OO_CREATE(ConvoyVehicle));
			_convoyDescription pushBack (["LOP_US_UAZ_DshKM", [{},[0]], [_teamDescriptor, _teamDescriptor, _teamDescriptor, _teamDescriptor], _normalSpacing] call OO_CREATE(ConvoyVehicle));
			_convoyDescription pushBack (["LOP_US_UAZ_AGS", [{},[0]], [], _normalSpacing] call OO_CREATE(ConvoyVehicle));
		};

		case 2:
		{
			_convoyDescription pushBack (["LOP_US_UAZ_DshKM", [{},[0]], [], _normalSpacing] call OO_CREATE(ConvoyVehicle));
			_convoyDescription pushBack (["rhs_tigr_m_vdv", [{},[0]], [_teamDescriptor, _teamDescriptor], _wideSpacing] call OO_CREATE(ConvoyVehicle));
			_convoyDescription pushBack (["rhs_tigr_m_vdv", [{},[0]], [_teamDescriptor, _teamDescriptor, _teamDescriptor, _teamDescriptor], _normalSpacing] call OO_CREATE(ConvoyVehicle));
			_convoyDescription pushBack (["LOP_US_UAZ_AGS", [{},[0]], [], _normalSpacing] call OO_CREATE(ConvoyVehicle));
		};

		case 3:
		{
			_convoyDescription pushBack (["LOP_US_UAZ_DshKM", [{},[0]], [], _normalSpacing] call OO_CREATE(ConvoyVehicle));
			_convoyDescription pushBack (["LOP_US_BMP2D", [{},[0]], [_teamDescriptor], _wideSpacing] call OO_CREATE(ConvoyVehicle));
			_convoyDescription pushBack (["LOP_US_Ural", [{},[0]], [_teamDescriptor, _teamDescriptor], _normalSpacing] call OO_CREATE(ConvoyVehicle));
			_convoyDescription pushBack (["LOP_US_UAZ_AGS", [{},[0]], [_teamDescriptor], _normalSpacing] call OO_CREATE(ConvoyVehicle));
		};

		case 4:
		{
			_convoyDescription pushBack (["O_G_Offroad_01_armed_F", [{},[0]], [], _normalSpacing] call OO_CREATE(ConvoyVehicle));
			_convoyDescription pushBack (["O_G_Offroad_01_armed_F", [{},[0]], [], _wideSpacing] call OO_CREATE(ConvoyVehicle));
			_convoyDescription pushBack (["O_G_Offroad_01_F", [{},[0]], [_teamDescriptor], _normalSpacing] call OO_CREATE(ConvoyVehicle));
			_convoyDescription pushBack (["O_G_Offroad_01_F", [{},[0]], [_teamDescriptor], _normalSpacing] call OO_CREATE(ConvoyVehicle));
		};
	};

	private _convoySpeed = 40;

	private _mission = [_convoyPositions, _convoyDescription, _convoyStartTime, _convoySpeed] call OO_CREATE(MissionInterceptConvoy);
	OO_SET(_mission,Strongpoint,SendNotification,SPM_SOC_SendNotification);

	_mission
};

OO_TRACE_DECL(SPM_SOC_MissionInterceptObjectiveVehicles) =
{
	params ["_soc"];

	_convoyStartTime = diag_tickTime + CONVOY_START_DELAY;

	private _referencePosition = OO_GET(_soc,SpecialOperationsCommand,ReferencePosition);
	private _blacklist = ([1000, 2000, -1] call SERVER_OperationBlacklist) + ([OO_GET(_soc,SpecialOperationsCommand,Blacklist), 1000] call SPM_SOC_PaddedBlacklist);

	// Generate the convoy route

	private _data = [];
	private _chain =
		[
			[SPM_Chain_NearestLocation, [_referencePosition, 10000, ["NameLocal", "NameVillage","NameCity","NameCityCapital"]]],
			[SPM_Chain_PositionToIsolatedPosition, [_blacklist]],
			[SPM_Chain_PositionToConvoyRoute, [100, 6000, _blacklist]]
		];
	private _complete = [_data, _chain] call SPM_Chain_Execute;

	if (not _complete) exitWith { OO_NULL }; // This shouldn't happen

	private _convoyRoute = [_data, "convoy-route"] call SPM_Util_GetDataValue;
	private _convoyPositions = _convoyRoute apply { getPos _x };

	private _convoyDescription = [];
	private _convoySpeed = 60;

	private _mission = [_convoyPositions, _convoyDescription, _convoyStartTime, _convoySpeed] call OO_CREATE(MissionInterceptConvoy);
	OO_SET(_mission,Strongpoint,SendNotification,SPM_SOC_SendNotification);

	_mission
};

OO_TRACE_DECL(SPM_SOC_MissionDisruptMeeting) =
{
	params ["_soc"];

	private _missionRadius = 500;
	private _meetingCount = 8; // Half to each faction
	private _meetingRadius = 50;
	private _guardCount = 16;
	private _guardRadius = 100;
	private _civilianCount = 40;
	private _civilianRadius = 200;

	private _referencePosition = OO_GET(_soc,SpecialOperationsCommand,ReferencePosition);
	private _blacklist = ([1000, 2000, -1] call SERVER_OperationBlacklist) + ([OO_GET(_soc,SpecialOperationsCommand,Blacklist), 2000] call SPM_SOC_PaddedBlacklist);

	_data = [];
	_chain =
		[
			[SPM_Chain_NearestLocation, [_referencePosition, 10000, ["NameLocal", "NameVillage","NameCity","NameCityCapital"]]],
			[SPM_Chain_PositionToIsolatedPosition, [_blacklist]],
			[SPM_Chain_PositionToBuildings, [0, 700]],
			[SPM_Chain_BuildingsToEnterableBuildings, []],
			[SPM_Chain_EnterableBuildingsToOccupancyBuildings, [_meetingCount / 2]],
			[SPM_Chain_OccupancyBuildingsToGarrisonPosition, [_meetingRadius, _meetingCount, false]]
		];
	private _complete = [_data, _chain] call SPM_Chain_Execute;

	if (not _complete) exitWith { OO_NULL };

	private _position = [_data, "garrison-position"] call SPM_Util_GetDataValue;

	private _mission = [_position, _missionRadius, _meetingCount, _meetingRadius, _guardCount, _guardRadius, _civilianCount, _civilianRadius] call OO_CREATE(MissionDisruptMeeting);
	OO_SET(_mission,Strongpoint,SendNotification,SPM_SOC_SendNotification);

	_mission
};

OO_TRACE_DECL(SPM_SOC_MissionRaidTown) =
{
	params ["_soc", "_garrisonRadius", "_garrisonCount"];

	private _referencePosition = OO_GET(_soc,SpecialOperationsCommand,ReferencePosition);
	private _blacklist = ([1000, 2000, -1] call SERVER_OperationBlacklist) + ([OO_GET(_soc,SpecialOperationsCommand,Blacklist), 2000] call SPM_SOC_PaddedBlacklist);

	_data = [];
	_chain =
		[
			[SPM_Chain_NearestLocation, [_referencePosition, 10000, ["NameLocal", "NameVillage","NameCity","NameCityCapital"]]],
			[SPM_Chain_PositionToIsolatedPosition, [_blacklist]],
			[SPM_Chain_PositionToBuildings, [0, 700]],
			[SPM_Chain_BuildingsToEnterableBuildings, []],
			[SPM_Chain_EnterableBuildingsToOccupancyBuildings, [4]],
			[SPM_Chain_OccupancyBuildingsToGarrisonPosition, [_garrisonRadius, _garrisonCount, false]]
		];
	private _complete = [_data, _chain] call SPM_Chain_Execute;

	if (not _complete) exitWith { OO_NULL };

	private _position = [_data, "garrison-position"] call SPM_Util_GetDataValue;

	private _mission = [_position, _garrisonRadius, _garrisonCount] call OO_CREATE(MissionRaidTown);
	OO_SET(_mission,Strongpoint,SendNotification,SPM_SOC_SendNotification);

	_mission
};

OO_TRACE_DECL(SPM_SOC_MissionCaptureOfficer) =
{
	params ["_soc"];

	private _mission = [_soc, 50, 40] call SPM_SOC_MissionRaidTown;

	if (OO_ISNULL(_mission)) exitWith { _mission };

	private _infantryGarrison = OO_NULL;
	{
		if (OO_INSTANCE_ISOFCLASS(_x,InfantryGarrisonCategory)) exitWith { _infantryGarrison = _x };
	} forEach OO_GET(_mission,Strongpoint,Categories);

	private _category = [_infantryGarrison, nil, nil, "O_officer_F", nil, nil, "OFFICER"] call OO_CREATE(ProvideGarrisonUnit);
	[_category] call OO_METHOD(_mission,Strongpoint,AddCategory);

	private _unitProvider = _category;

	private _specopsTest = { [player] call BOTH_IsSpecOpsMember };

	private _objective = [_unitProvider] call OO_CREATE(ObjectiveCaptureMan);
	OO_SET(_objective,ObjectiveCaptureMan,ClientActionTest,_specopsTest);
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);

	private _debriefingArea = [0, getPos SpecOpsHQ] + triggerArea SpecOpsHQ;
	private _objective = [_unitProvider, _debriefingArea, "SpecOps headquarters"] call OO_CREATE(ObjectiveDebriefMan);
	OO_SET(_objective,ObjectiveDebriefMan,ClientActionTest,_specopsTest);
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);

	private _objective = [] call OO_CREATE(ObjectiveProtectCivilians);
	OO_SET(_objective,ObjectiveProtectCivilians,DeathsPermitted,5);
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);

	_mission
};

OO_TRACE_DECL(SPM_SOC_GetGuardableObject) =
{
	params ["_guardableObject"];

	private _objective = OO_GET(_guardableObject,GuardableObjectiveObject,Objective);
	OO_GET(_objective,MissionObjective,ObjectiveObject)
};

OO_TRACE_DECL(SPM_SOC_GetGuardablePositions) =
{
	params ["_guardableObject", "_numberPositions"];

	private _objective = OO_GET(_guardableObject,GuardableObjectiveObject,Objective);
	private _object = OO_GET(_objective,MissionObjective,ObjectiveObject);

	private _positions = [];

	// Start searching for positions at the XY radius of the object
	private _vector = (boundingBoxReal _object) select 0;
	_vector set [2, 0];
	private _innerRadius = vectorMagnitude _vector;
	private _startingRadius = _innerRadius;

	private _guardPositions = [];

	while { count _guardPositions < _numberPositions && _innerRadius < _startingRadius + 50  } do
	{
		_positions = [getPos _object, _innerRadius, _innerRadius + 4.0, 1.0] call SPM_Util_SampleAreaGrid;
		[_positions, ["#GdtRoad", "#GdtWater"]] call SPM_Util_ExcludeSamplesBySurfaceType;
		[_positions, 1.0, ["WALL", "BUILDING", "HOUSE", "ROCK", "ROAD", "ENTITY"]] call SPM_Util_ExcludeSamplesByProximity;

		_guardPositions append _positions;

		_innerRadius = _innerRadius + 4.0;
	};

	_guardPositions
};

OO_BEGIN_SUBCLASS(GuardableObjectiveObject,GuardableObject);
	OO_OVERRIDE_METHOD(GuardableObjectiveObject,GuardableObject,GetObject,SPM_SOC_GetGuardableObject);
	OO_OVERRIDE_METHOD(GuardableObjectiveObject,GuardableObject,GetPositions,SPM_SOC_GetGuardablePositions);
	OO_DEFINE_PROPERTY(GuardableObjectiveObject,Objective,"#OBJ",OO_NULL);
OO_END_SUBCLASS(GuardableObjectiveObject);

OO_TRACE_DECL(SPM_SOC_MissionRescueSoldier) =
{
	params ["_soc"];

	private _mission = [_soc, 50, 40] call SPM_SOC_MissionRaidTown;

	if (OO_ISNULL(_mission)) exitWith { _mission };

	private _infantryGarrison = OO_NULL;
	{
		if (OO_INSTANCE_ISOFCLASS(_x,InfantryGarrisonCategory)) exitWith { _infantryGarrison = _x };
	} forEach OO_GET(_mission,Strongpoint,Categories);

	private _category = [_infantryGarrison, ["garrisoned-housed", "garrisoned-outdoor"], nil, "B_survivor_F", nil, nil, "SOLDIER"] call OO_CREATE(ProvideGarrisonUnit);
	[_category] call OO_METHOD(_mission,Strongpoint,AddCategory);

	private _unitProvider = _category;

	private _objective = [_unitProvider] call OO_CREATE(ObjectiveRescueMan);
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);

	private _guardableObject = [] call OO_CREATE(GuardableObjectiveObject);
	OO_SET(_guardableObject,GuardableObjectiveObject,Objective,_objective);

	private _category = [_guardableObject, _infantryGarrison, 4] call OO_CREATE(GuardObjectCategory);
	[_category] call OO_METHOD(_mission,Strongpoint,AddCategory);

	private _specopsTest = { [player] call BOTH_IsSpecOpsMember };

	private _debriefingArea = [0, getPos SpecOpsHQ] + triggerArea SpecOpsHQ;
	private _objective = [_unitProvider, _debriefingArea, "SpecOps headquarters"] call OO_CREATE(ObjectiveDebriefMan);
	OO_SET(_objective,ObjectiveDebriefMan,ClientActionTest,_specopsTest);
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);

	private _objective = [] call OO_CREATE(ObjectiveProtectCivilians);
	OO_SET(_objective,ObjectiveProtectCivilians,DeathsPermitted,5);
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);

	_mission
};

OO_TRACE_DECL(SPM_SOC_MissionDestroyAmmoDump) =
{
	params ["_soc"];

	private _mission = [_soc, 50, 40] call SPM_SOC_MissionRaidTown;

	if (OO_ISNULL(_mission)) exitWith { _mission };

	private _infantryGarrison = OO_NULL;
	{
		if (OO_INSTANCE_ISOFCLASS(_x,InfantryGarrisonCategory)) exitWith { _infantryGarrison = _x };
	} forEach OO_GET(_mission,Strongpoint,Categories);

	private _position = OO_GET(_mission,Strongpoint,Position);
	private _area = [_position, 0, 50] call OO_CREATE(StrongpointArea);
	private _ammoDump = [_area] call OO_CREATE(AmmoDumpCategory);
	[_ammoDump] call OO_METHOD(_mission,Strongpoint,AddCategory);

	private _objective = [_ammoDump] call OO_CREATE(ObjectiveDestroyAmmoDump);
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);

	private _pulse = [_objective, 8.0] call OO_CREATE(DamagePulseCategory);
	OO_SET(_pulse,DamagePulseCategory,DamageScale,0.06); // Make the barrel very durable
	[_pulse] call OO_METHOD(_mission,Strongpoint,AddCategory);

	private _guardableObject = [] call OO_CREATE(GuardableObjectiveObject);
	OO_SET(_guardableObject,GuardableObjectiveObject,Objective,_objective);

	private _category = [_guardableObject, _infantryGarrison, 4] call OO_CREATE(GuardObjectCategory);
	[_category] call OO_METHOD(_mission,Strongpoint,AddCategory);

	private _objective = [] call OO_CREATE(ObjectiveProtectCivilians);
	OO_SET(_objective,ObjectiveProtectCivilians,DeathsPermitted,5);
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);

	_mission
};

OO_TRACE_DECL(SPM_SOC_MissionDestroyRadioTower) =
{
	params ["_soc"];

	private _mission = [_soc, 50, 40] call SPM_SOC_MissionRaidTown;

	if (OO_ISNULL(_mission)) exitWith { _mission };

	private _infantryGarrison = OO_NULL;
	{
		if (OO_INSTANCE_ISOFCLASS(_x,InfantryGarrisonCategory)) exitWith { _infantryGarrison = _x };
	} forEach OO_GET(_mission,Strongpoint,Categories);

	private _position = OO_GET(_mission,Strongpoint,Position);
	private _area = [_position, 0, 50] call OO_CREATE(StrongpointArea);

	private _radioTower = ["Land_Communication_F", _area] call OO_CREATE(RadioTowerCategory);
	[_radioTower] call OO_METHOD(_mission,Strongpoint,AddCategory);

	private _objective = [_radioTower] call OO_CREATE(ObjectiveDestroyRadioTower);
	OO_SET(_objective,ObjectiveDestroyObject,ObjectiveObjectDescription,"communications tower");
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);

	private _pulse = [_objective, 0.8] call OO_CREATE(DamagePulseCategory);
	[_pulse] call OO_METHOD(_mission,Strongpoint,AddCategory);

	private _guardableObject = [] call OO_CREATE(GuardableObjectiveObject);
	OO_SET(_guardableObject,GuardableObjectiveObject,Objective,_objective);

	private _category = [_guardableObject, _infantryGarrison, 2] call OO_CREATE(GuardObjectCategory);
	[_category] call OO_METHOD(_mission,Strongpoint,AddCategory);

	private _objective = [] call OO_CREATE(ObjectiveProtectCivilians);
	OO_SET(_objective,ObjectiveProtectCivilians,DeathsPermitted,5);
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);

	_mission
};

SPM_SOC_DestroyVehicleDescriptors =
[
	["rhs_mi28n_vvsc",[{}, [0]]],
	["RHS_Mi24Vt_vvsc",[{}, [0]]]
];

OO_TRACE_DECL(SPM_SOC_MissionDestroyVehicle) =
{
	params ["_soc"];

	private _mission = [_soc, 50, 40] call SPM_SOC_MissionRaidTown;

	if (OO_ISNULL(_mission)) exitWith { _mission };

	private _infantryGarrison = OO_NULL;
	{
		if (OO_INSTANCE_ISOFCLASS(_x,InfantryGarrisonCategory)) exitWith { _infantryGarrison = _x };
	} forEach OO_GET(_mission,Strongpoint,Categories);

	private _objective = [selectRandom SPM_SOC_DestroyVehicleDescriptors, _infantryGarrison] call OO_CREATE(ObjectiveDestroyVehicle);
	OO_SET(_objective,ObjectiveDestroyObject,CaptureDistance,1000);
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);

	private _guardableObject = [] call OO_CREATE(GuardableObjectiveObject);
	OO_SET(_guardableObject,GuardableObjectiveObject,Objective,_objective);

	private _category = [_guardableObject, _infantryGarrison, 2] call OO_CREATE(GuardObjectCategory);
	[_category] call OO_METHOD(_mission,Strongpoint,AddCategory);

	private _objective = [] call OO_CREATE(ObjectiveProtectCivilians);
	OO_SET(_objective,ObjectiveProtectCivilians,DeathsPermitted,5);
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);

	_mission
};

OO_TRACE_DECL(SPM_SOC_DetonateWhenKilled) =
{
	params ["_vehicle"];

	_vehicle addEventHandler ["Killed",
		{
			params ["_vehicle"];

			private _explosives = [] call JB_fnc_detonateGetExplosives;
			private _positions = (boundingBoxReal _vehicle + (boundingBoxReal _vehicle apply { _x set [0, -(_x select 0)]; _x }) + [[0,0,0]]) apply { _vehicle modelToWorld _x };
			{
				[_explosives select 0, _x] call JB_fnc_detonateExplosive; // Put the largest explosive on each bounding corner plus the origin
			} forEach _positions;
		}];
};

SPM_SOC_ConvoyTargetVehicles =
[
	[["Capture the device, move 500m clear of capture location", ""], 1, ["RHS_BM21_VDV_01", [{},[0]]]],
	[["Capture the communications gear, move 500m clear of capture location", ""], 3, ["RHS_Ural_Repair_VDV_01", [{ (_this select 0) setRepairCargo 0 },[0]]]],
	[["Capture the advanced weaponry, move 500m clear of capture location", ""], 1, ["rhs_gaz66_ammo_vdv", [{ (_this select 0) setAmmoCargo 0 },[0]]]],
	[["Capture the rocket fuel, move 500m clear of capture location", ""], 4, ["RHS_Ural_Fuel_VDV_01", [{ (_this select 0) setFuelCargo 0; [_this select 0] call SPM_SOC_DetonateWhenKilled },[0]]]],
	[["Capture the biological materials, move 500m clear of capture location", ""], 2, ["rhs_gaz66_ap2_vdv", [{},[0]]]]
];

OO_TRACE_DECL(SPM_SOC_MissionCaptureTruck) =
{
	params ["_soc"];

	private _target = selectRandom SPM_SOC_ConvoyTargetVehicles;
	//_target = SPM_SOC_ConvoyTargetVehicles select 3;//TEST

	private _mission = [_soc, _target select 1] call SPM_SOC_MissionInterceptConvoy;

	private _normalSpacing = [] call OO_CREATE(ConvoySpacing);
	private _convoyVehicle = [_target select 2 select 0, _target select 2 select 1, [], _normalSpacing] call OO_CREATE(ConvoyVehicle);
	private _objective = [_convoyVehicle, _target select 0] call OO_CREATE(ObjectiveCaptureConvoyVehicle);
	OO_SET(_objective,ObjectiveCaptureConvoyVehicle,CaptureDistance,500);
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);

	_mission
};

OO_TRACE_DECL(SPM_SOC_MissionRescueHostages) =
{
	params ["_soc"];

	private _hostageRadius = 50;
	private _garrisonRadius = 50;
	private _garrisonCount = 40;

	private _referencePosition = OO_GET(_soc,SpecialOperationsCommand,ReferencePosition);
	private _blacklist = ([1000, 2000, -1] call SERVER_OperationBlacklist) + ([OO_GET(_soc,SpecialOperationsCommand,Blacklist), 2000] call SPM_SOC_PaddedBlacklist);

	_data = [];
	_chain =
		[
			[SPM_Chain_NearestLocation, [_referencePosition, 10000, ["NameLocal", "NameVillage","NameCity","NameCityCapital"]]],
			[SPM_Chain_PositionToIsolatedPosition, [_blacklist]],
			[SPM_Chain_PositionToBuildings, [0, 700]],
			[SPM_Chain_BuildingsToEnterableBuildings, []],
			[SPM_Chain_EnterableBuildingsToOccupancyBuildings, [4]],
			[SPM_Chain_OccupancyBuildingsToGarrisonPosition, [_garrisonRadius, _garrisonCount, false]]
		];
	private _complete = [_data, _chain] call SPM_Chain_Execute;

	if (not _complete) exitWith { OO_NULL };

	private _position = [_data, "garrison-position"] call SPM_Util_GetDataValue;

	private _hostageClasses = [];
	private _objectiveDescription = ["",""];
	switch (floor random 5) do
	{
		case 0: { _hostageClasses = ["C_journalist_F", "C_journalist_F"]; _objectiveDescription = ["Rescue journalist hostages", ""]; };
		case 1: { _hostageClasses = ["C_scientist_F", "C_scientist_F", "C_scientist_F"]; _objectiveDescription = ["Rescue scientist hostages", ""]; };
		case 2: { _hostageClasses = ["B_GEN_Commander_F", "B_GEN_Commander_F", "B_GEN_Soldier_F", "B_GEN_Soldier_F"]; _objectiveDescription = ["Rescue German Police officers", ""]; };
		case 3: { _hostageClasses = ["C_Man_Paramedic_01_F", "C_Man_Paramedic_01_F", "C_man_pilot_F"]; _objectiveDescription = ["Rescue paramedic and pilot hostages", ""]; };

		default
		{
			_objectiveDescription = ["Rescue hostages", ""];
			for "_i" from 1 to 4 do
			{
				_hostageClasses pushBack ((selectRandom SPM_InfantryGarrison_RatingsCivilian) select 0);
			};
		};
	};
	private _numberHostages = count _hostageClasses;

	private _mission = [_position, 50, _hostageClasses, 100, 40] call OO_CREATE(MissionRescueHostages);
	OO_SET(_mission,Strongpoint,SendNotification,SPM_SOC_SendNotification);

	private _garrison = OO_NULL;
	{
		if (OO_INSTANCE_ISOFCLASS(_x,InfantryGarrisonCategory)) exitWith { _garrison = _x };
	} forEach OO_GET(_mission,Strongpoint,Categories);

	private _providers = [];
	{
		private _provider = [_garrison, ["garrisoned-housed", "garrisoned-outdoor"], _forEachIndex, _x, civilian, "hostage", "HOSTAGE"] call OO_CREATE(ProvideGarrisonUnit);
		[_provider] call OO_METHOD(_mission,Strongpoint,AddCategory);
		_providers pushBack _provider;
	} forEach _hostageClasses;

	private _compoundObjective = [_objectiveDescription] call OO_CREATE(ObjectiveCompound);
	[_compoundObjective] call OO_METHOD(_mission,Mission,AddObjective);

	{
		private _objective = [_x] call OO_CREATE(ObjectiveRescueMan);
		[_objective] call OO_METHOD(_compoundObjective,ObjectiveCompound,AddObjective);
		[_objective] call OO_METHOD(_mission,Mission,AddObjective);
	} forEach _providers;

	private _compoundObjective = [["Release all hostages clear of area (500 meters)", "Transport the hostages to a point 500m away from the location where they were found"]] call OO_CREATE(ObjectiveCompound);
	[_compoundObjective] call OO_METHOD(_mission,Mission,AddObjective);

	{
		private _objective = [_x, ["Release hostage clear of area", ""]] call OO_CREATE(ObjectiveDeliverMan);
		OO_SET(_objective,ObjectiveDeliverMan,DeliverDistance,500);
		[_objective] call OO_METHOD(_compoundObjective,ObjectiveCompound,AddObjective);
		[_objective] call OO_METHOD(_mission,Mission,AddObjective);
	} forEach _providers;

	_mission
};

OO_TRACE_DECL(SPM_SOC_MissionInterceptCourier) =
{
	params ["_soc"];

	private _mission = [_soc] call SPM_SOC_MissionInterceptObjectiveVehicles;

	private _normalSpacing = [] call OO_CREATE(ConvoySpacing);
	private _convoyVehicle = (["LOP_US_UAZ_DshKM", [
		{
				[_this select 0] call SPM_Transport_RemoveWeapons;
				(_this select 0) addMagazine "500Rnd_65x39_Belt_Tracer_Green_Splash";
				(_this select 0) addWeapon "LMG_RCWS";
		},[0]], [], _normalSpacing] call OO_CREATE(ConvoyVehicle));
	private _objective = [_convoyVehicle, ["Prevent courier vehicle from reaching destination", "Force the courier vehicle to stop before reaching its destination.  Either kill the driver or mobility-kill the vehicle."]] call OO_CREATE(ObjectiveInterceptVehicle);
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);

	private _objectiveDescription = ["Retrieve intel from courier vehicle", "Approach the vehicle and use the scroll wheel option to search the vehicle for the intel."];
	private _objective = [0] call OO_CREATE(ObjectiveInteractObjectConvoyVehicle);
	OO_SET(_objective,ObjectiveInteractObject,ObjectiveDescription,_objectiveDescription);
	OO_SET(_objective,ObjectiveInteractObject,InteractionDescription,"Search vehicle for intel");
	OO_SET(_objective,ObjectiveInteractObject,InteractionCondition,{_this call SPM_MissionInterceptCourier_InteractionCondition});
	OO_SET(_objective,ObjectiveInteractObject,Interaction,{_this call SPM_MissionInterceptCourier_Interaction});
	OO_SET(_objective,ObjectiveInteractObject,InteractionFilter,BOTH_IsSpecOpsMember);
	OO_SET(_objective,ObjectiveInteractObject,ActionHold,5.0);

	[_objective] call OO_METHOD(_mission,Mission,AddObjective);

	_mission
};

SPM_SOC_MissionTypes =
[
	[[], SPM_SOC_MissionCaptureOfficer],
	[[], SPM_SOC_MissionRescueSoldier],
	[[], SPM_SOC_MissionDisruptMeeting],
	[[], SPM_SOC_MissionDestroyAmmoDump],
	[[], SPM_SOC_MissionDestroyRadioTower],
	[[], SPM_SOC_MissionDestroyVehicle],
	[[], SPM_SOC_MissionCaptureTruck],
	[[], SPM_SOC_MissionInterceptCourier],
	[[], SPM_SOC_MissionRescueHostages]
];

OO_TRACE_DECL(SPM_SOC_RunMissionSequence) =
{
	params ["_soc"];

	OO_SET(_soc,SpecialOperationsCommand,CommandState,"running");

	private _missionSequence = OO_GET(_soc,SpecialOperationsCommand,MissionSequence);
	private _missionNumber = 0;

	private _missionComplete = false;

	while { _missionNumber < count _missionSequence && OO_GET(_soc,SpecialOperationsCommand,CommandState) == "running" } do
	{
		private _missionDescriptor = _missionSequence select _missionNumber;
		_missionNumber = _missionNumber + 1;

		private _mission = ([_soc] + (_missionDescriptor select 0)) call (_missionDescriptor select 1);

		private _missionState = "";

		if (OO_ISNULL(_mission)) then
		{
			_missionState = "internal-error";
		}
		else
		{
			OO_SET(_soc,SpecialOperationsCommand,RunningMission,_mission);
			private _script = [_mission] spawn { params ["_mission"]; scriptName "SPM_SOC_RunMissionSequence"; [] call OO_METHOD(_mission,Strongpoint,Run) }; // Cannot spawn OO_METHODs
			OO_SET(_soc,SpecialOperationsCommand,RunningMissionScript,_script);

			while { OO_GET(_mission,Mission,MissionState) == "unresolved" && not (OO_GET(_mission,Strongpoint,RunState) in ["stopped", "deleted"]) } do
			{
				sleep 1;
			};

			OO_SET(_soc,SpecialOperationsCommand,RunningMissionScript,scriptNull);
			OO_SET(_soc,SpecialOperationsCommand,RunningMission,OO_NULL);

			private _missionPosition = OO_GET(_mission,Strongpoint,Position);
			OO_SET(_soc,SpecialOperationsCommand,ReferencePosition,_missionPosition);

			// Don't revisit this location during this mission sequence
			private _blacklist = OO_GET(_soc,SpecialOperationsCommand,Blacklist);
			_blacklist pushBack [0, _missionPosition];

			_missionState = OO_GET(_mission,Mission,MissionState);
		};

		private _reviewDelay = MISSION_REVIEW_DELAY;

		switch (_missionState) do
		{
			case "internal-error";
			case "completed-error":
			{
				[["It looks like we received some bad intel", "Mission aborted", ""], ["printout"], BOTH_IsSpecOpsMember] call SPM_Mission_Message;
				[["Mission aborted due to error"], ["log-specops"], BOTH_IsSpecOpsMember] call SPM_Mission_Message;
				_reviewDelay = 0;
			};

			case "completed-failure":
			{
				_missionNumber = count _missionSequence;
			};

			case "completed-success":
			{
			};

			case "command-terminated":
			{
				[["Mission stopped by command", ""], ["printout", "log-specops"], BOTH_IsSpecOpsMember] call SPM_Mission_Message;
				_reviewDelay = 0;
			};
		};

		switch (true) do
		{
			case (OO_GET(_soc,SpecialOperationsCommand,CommandState) != "running"):
			{
				[["Mission sequence ends (stopped by command)", ""], ["printout", "log-specops"], BOTH_IsSpecOpsMember] call SPM_Mission_Message;
			};

			case (_missionNumber == count _missionSequence):
			{
				if (_missionState == "completed-success") then
				{
					[["Mission sequence completed successfully", "Well done", ""], ["printout", "log-specops"], BOTH_IsSpecOpsMember] call SPM_Mission_Message;
				};
				[["Mission sequence ends", ""], ["printout", "log-specops"], BOTH_IsSpecOpsMember] call SPM_Mission_Message;
			};

			default
			{
				[["Mission sequence continues", "Stand by", ""], ["printout"], BOTH_IsSpecOpsMember] call SPM_Mission_Message;
			};
		};

		OO_SET(_soc,SpecialOperationsCommand,ReviewEndTime,diag_tickTime+_reviewDelay);
		sleep _reviewDelay;

		OO_DELETE(_mission);
	};

	OO_SET(_soc,SpecialOperationsCommand,MissionSequence,[]);
	OO_SET(_soc,SpecialOperationsCommand,CommandState,"waiting");
};

OO_TRACE_DECL(SPM_SOC_RequestMission) =
{
	params ["_soc", "_player"];

	if (isNull _player) exitWith {};

	if (not ([_player] call BOTH_IsSpecOpsMember)) exitWith
	{
		[ "This device is restricted for use by the special operations team", 1] remoteExec ["JB_fnc_showBlackScreenMessage", _player];
	};

	if (count allPlayers >= SpecialOperations_MaxPlayers) exitWith
	{
		[ format ["Special operations is disabled while there are more than %1 players online", count allPlayers], 3] remoteExec ["JB_fnc_showBlackScreenMessage", _player];
	};

	private _cs = OO_GET(_soc,SpecialOperationsCommand,CriticalSection);
	_cs call JB_fnc_criticalSectionEnter;

		private _commandState = OO_GET(_soc,SpecialOperationsCommand,CommandState);

		if (_commandState == "requested") exitWith
		{
			_cs call JB_fnc_criticalSectionLeave;
			[["Copy", "In work", "Wait one", ""], ["printout"], _player] call SPM_Mission_Message;
		};

		if (_commandState == "running") exitWith
		{
			_cs call JB_fnc_criticalSectionLeave;

			if (OO_ISNULL(OO_GET(_soc,SpecialOperationsCommand,RunningMission))) then
			{
				private _remainingDelay = (OO_GET(_soc,SpecialOperationsCommand,ReviewEndTime) - diag_tickTime) max 0;
				private _remainingDelayString = [_remainingDelay, "MM:SS"] call BIS_fnc_secondsToString;
				[["Copy", "Reviewing results of last mission (" + _remainingDelayString + " remaining)", ""], ["printout"], _player] call SPM_Mission_Message;
			}
			else
			{
				[["Copy", "Mission sequence is underway", "Review special operations message log", ""], ["printout"], _player] call SPM_Mission_Message;
			}
		};

		OO_SET(_soc,SpecialOperationsCommand,CommandState,"requested");

	_cs call JB_fnc_criticalSectionLeave;

	[["Copy", "Mission request acknowledged", "Wait one", ""], ["printout"], _player] call SPM_Mission_Message;

	// Create mission sequence

	private _missionSequence = [];

	OO_SET(_soc,SpecialOperationsCommand,Blacklist,[]);

	// Where to start the sequence
	private _referencePosition = [0, 0, 0];
	while { surfaceIsWater _referencePosition } do
	{
		_referencePosition = [random WorldSize, random WorldSize, 0];
	};
	OO_SET(_soc,SpecialOperationsCommand,ReferencePosition,_referencePosition);

	// Random mission order utilizing up to 6 mission types
	private _missionTypes = +SPM_SOC_MissionTypes;

//	_missionTypes = [[[], SPM_SOC_MissionCaptureOfficer]];//TEST
//	_missionTypes = [[[], SPM_SOC_MissionRescueSoldier]];//TEST
//	_missionTypes = [[[], SPM_SOC_MissionDisruptMeeting]];//TEST
//	_missionTypes = [[[], SPM_SOC_MissionDestroyAmmoDump]];//TEST
//	_missionTypes = [[[], SPM_SOC_MissionDestroyRadioTower]];//TEST
//	_missionTypes = [[[], SPM_SOC_MissionDestroyVehicle]];//TEST
//	_missionTypes = [[[], SPM_SOC_MissionCaptureTruck]];//TEST
//	_missionTypes = [[[], SPM_SOC_MissionInterceptCourier]];//TEST
//	_missionTypes = [[[], SPM_SOC_MissionRescueHostages]];//TEST

	private _numberMissions = (5 + round random 1) min (count _missionTypes);
	while { count _missionSequence < _numberMissions } do
	{
		private _mission = _missionTypes deleteAt floor random count _missionTypes;
		_missionSequence pushBack _mission;
	};

	OO_SET(_soc,SpecialOperationsCommand,MissionSequence,_missionSequence);

	// Run mission sequence

	[_soc] spawn SPM_SOC_RunMissionSequence;
};

OO_TRACE_DECL(SPM_SOC_NotifyPlayer) =
{
	params ["_soc", "_player"];

	if (not ([_player] call BOTH_IsSpecOpsMember)) exitWith {};

	private _mission = OO_GET(_soc,SpecialOperationsCommand,RunningMission);
	[_player] call OO_METHOD(_mission,MissionSpecialOperations,NotifyPlayer);
};

SPM_SOC_Create =
{
	params ["_soc"];

	private _cs = call JB_fnc_criticalSectionCreate;
	OO_SET(_soc,SpecialOperationsCommand,CriticalSection,_cs);
};

OO_BEGIN_CLASS(SpecialOperationsCommand);
	OO_OVERRIDE_METHOD(SpecialOperationsCommand,Root,Create,SPM_SOC_Create);
	OO_DEFINE_METHOD(SpecialOperationsCommand,RequestMission,SPM_SOC_RequestMission);
	OO_DEFINE_METHOD(SpecialOperationsCommand,NotifyPlayer,SPM_SOC_NotifyPlayer);
	OO_DEFINE_PROPERTY(SpecialOperationsCommand,CriticalSection,"ARRAY","[]");
	OO_DEFINE_PROPERTY(SpecialOperationsCommand,ReferencePosition,"ARRAY","[]"); // Position of the prior mission in the chain
	OO_DEFINE_PROPERTY(SpecialOperationsCommand,Blacklist,"ARRAY","[]");
	OO_DEFINE_PROPERTY(SpecialOperationsCommand,CommandState,"STRING","waiting"); // waiting, requested, running, stopping
	OO_DEFINE_PROPERTY(SpecialOperationsCommand,MissionSequence,"ARRAY",[]);
	OO_DEFINE_PROPERTY(SpecialOperationsCommand,RunningMission,"#OBJ",OO_NULL);
	OO_DEFINE_PROPERTY(SpecialOperationsCommand,RunningMissionScript,"SCRIPT",scriptNull);
	OO_DEFINE_PROPERTY(SpecialOperationsCommand,ReviewEndTime,"SCALAR",0);
OO_END_CLASS(SpecialOperationsCommand);

OO_TRACE_DECL(SPM_MissionSpecialOperations_GetObjectiveDescriptions) =
{
	params ["_mission"];

	private _objectiveDescriptions = [];
	{
		if (OO_ISNULL(OO_GET(_x,MissionObjective,ObjectiveParent))) then { _objectiveDescriptions pushBack format ["%1 (%2)", ([] call OO_METHOD(_x,MissionObjective,GetDescription)) select 0, OO_GET(_x,MissionObjective,State)] };
	} forEach OO_GET(_mission,Mission,Objectives);

	_objectiveDescriptions
};

OO_TRACE_DECL(SPM_MissionSpecialOperations_Update) =
{
	params ["_mission"];

	[] call OO_METHOD_PARENT(_mission,Strongpoint,Update,Mission);

	if (OO_GET(_mission,Mission,Announced) == "start-of-mission") then
	{
		switch (OO_GET(_mission,Mission,MissionState)) do
		{
			case "completed-error":
			{
				[_mission, OO_NULL, ["Mission Status Report", "Mission ABORTED"] + ([_mission] call SPM_MissionSpecialOperations_GetObjectiveDescriptions), "mission-status"] call OO_GET(_mission,Strongpoint,SendNotification);
				OO_SET(_mission,Mission,Announced,"end-of-mission");
			};

			case "completed-success":
			{
				[_mission, OO_NULL, ["Mission Status Report", "Mission COMPLETED"] + ([_mission] call SPM_MissionSpecialOperations_GetObjectiveDescriptions), "mission-status"] call OO_GET(_mission,Strongpoint,SendNotification);
				OO_SET(_mission,Mission,Announced,"end-of-mission");
			};

			case "completed-failure":
			{
				[_mission, OO_NULL, ["Mission Status Report", "Mission FAILED"] + ([_mission] call SPM_MissionSpecialOperations_GetObjectiveDescriptions), "mission-status"] call OO_GET(_mission,Strongpoint,SendNotification);
				OO_SET(_mission,Mission,Announced,"end-of-mission");
			};
		};
	};
};

OO_TRACE_DECL(SPM_MissionSpecialOperations_GetMissionDescription) =
{
	params ["_mission"];

	private _objectiveDescriptions = [];
	{
		_objectiveDescriptions pushBack (_x select 2 select 0);
	} forEach OO_GET(_mission,Mission,NotificationsAccumulator);

	private _positionDescription = [OO_GET(_mission,Strongpoint,Position)] call SPM_Util_PositionDescription;

	["Mission Orders"] + _objectiveDescriptions + ["Area of operation: " + _positionDescription]
};

OO_TRACE_DECL(SPM_MissionSpecialOperations_NotifyPlayer) =
{
	params ["_mission", "_player"];

	private _description = [] call OO_METHOD(_mission,MissionSpecialOperations,GetMissionDescription);
	[_description, ["log-specops", "printout-specops"], _player] call SPM_Mission_Message;
};

OO_BEGIN_SUBCLASS(MissionSpecialOperations,Mission);
	OO_OVERRIDE_METHOD(MissionSpecialOperations,Strongpoint,Update,SPM_MissionSpecialOperations_Update);
	OO_DEFINE_METHOD(MissionSpecialOperations,GetMissionDescription,SPM_MissionSpecialOperations_GetMissionDescription);
	OO_DEFINE_METHOD(MissionSpecialOperations,NotifyPlayer,SPM_MissionSpecialOperations_NotifyPlayer);
OO_END_SUBCLASS(MissionSpecialOperations);
