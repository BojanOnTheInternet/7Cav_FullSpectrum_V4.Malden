/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include "strongpoint.h"

OO_TRACE_DECL(SPM_MissionAdvance_C_SeeTasksMessage) =
{
	params ["_filter"];

	// Discard any calls not intended for the local player
	if (not isNil "_filter" && { not ([player] call _filter) }) exitWith {};

	private _message = "See the map's Tasks tab for a list of operation objectives";

	private _actionKeys = actionKeys "diary";
	if (count _actionKeys > 0) then { _message = format ["Press %1 to see a list of operation objectives", keyName (_actionKeys select 0)] };

	[[_message], ["title"], player] call SPM_Mission_Message;
};

if (not isServer && hasInterface) exitWith {};

#define UPDATE_INTERVAL 10

// The pad between control area and the edge of the strongpoint area (where spawned units appear and enter the action)
#define ACTIVITY_BORDERWIDTH 500

#define PLAYERS_USE_AAA

SPM_MissionAdvance_ObjectiveStateToTaskState =
[
	["starting", "created"],
	["active", "created"],
	["failed", "failed"],
	["succeeded", "succeeded"],
	["error", "canceled"]
];

OO_TRACE_DECL(SPM_MissionAdvance_MissionTaskIdentifier) =
{
	params ["_mission"];

	private _position = OO_GET(_mission,Strongpoint,Position);

	[floor ((_position select 0) / 100), floor ((_position select 1) / 100)]
};

OO_TRACE_DECL(SPM_MissionAdvance_ObjectiveTaskIdentifier) =
{
	params ["_objective"];

	if (OO_ISNULL(_objective)) exitWith { [] };

	private _identifier = [];
	private _lastDefined = OO_NULL;

	while { not OO_ISNULL(_objective) } do
	{
		_lastDefined = _objective;
		_identifier = OO_REFERENCE(_objective) + _identifier;
		_objective = OO_GETREF(_objective,MissionObjective,ObjectiveParent);
	};
	_identifier = ([OO_GETREF(_lastDefined,Category,Strongpoint)] call SPM_MissionAdvance_MissionTaskIdentifier) + _identifier;

	_identifier
};

OO_TRACE_DECL(SPM_MissionAdvance_ObjectiveParentTaskIdentifier) =
{
	params ["_objective"];

	private _parent = OO_GETREF(_objective,MissionObjective,ObjectiveParent);
	if (not OO_ISNULL(_parent)) exitWith { [_parent] call SPM_MissionAdvance_ObjectiveTaskIdentifier };

	[OO_GETREF(_objective,Category,Strongpoint)] call SPM_MissionAdvance_MissionTaskIdentifier
};

OO_TRACE_DECL(SPM_MissionAdvance_SendNotification) =
{
	params ["_mission", "_origin", "_message", "_type"];

	private _notifications = OO_GET(_mission,MissionAdvance,_Notifications);

	if (OO_GET(_mission,Mission,Announced) == "none") exitWith { _notifications pushBack (_this select [1,1e3]) };

	private _filter = OO_GET(_mission,Mission,ParticipantFilter);
	private _notificationType = "NotificationGeneric";
	
	switch (_type) do
	{
		case "mission-description":
		{
			_notificationType = "NotificationMissionDescription";

			[_filter, [_mission] call SPM_MissionAdvance_MissionTaskIdentifier, [], OO_GET(_mission,Strongpoint,Position), [_message select 1, _message select 0, ""], "attack", true] call SPM_Task_Create;

			if (_filter isEqualType {}) then { [_filter] remoteExec ["SPM_MissionAdvance_C_SeeTasksMessage", 0] } else { [] remoteExec ["SPM_MissionAdvance_C_SeeTasksMessage", _filter] };
		};
		case "mission-status":
		{
			_notificationType = "NotificationMissionStatus";
		};
		case "objective-description":
		{
			_notificationType = ""; // "NotificationObjectiveDescription" Disable per-objective notifications at start of mission

			[_filter, [_origin] call SPM_MissionAdvance_ObjectiveTaskIdentifier, [_origin] call SPM_MissionAdvance_ObjectiveParentTaskIdentifier, [], [_message select 1, _message select 0, ""], "", false] call SPM_Task_Create;
		};
		case "objective-status":
		{
			_notificationType = "NotificationObjectiveStatus";

			private _state = OO_GET(_origin,MissionObjective,State);
			private _index = SPM_MissionAdvance_ObjectiveStateToTaskState findIf { _x select 0 == _state };

			[_filter, [_origin] call SPM_MissionAdvance_ObjectiveTaskIdentifier, SPM_MissionAdvance_ObjectiveStateToTaskState select _index select 1] call SPM_Task_SetState;
		};
		case "event":
		{
			_notificationType = "NotificationEvent";
		};
	};
	
	if (_notificationType != "") then { [[_notificationType] + [_message select 0], ["notification"], _filter] call SPM_Mission_Message };

	// Replay any notifications that we held up at the start of the mission
	while { count _notifications > 0 } do
	{
		([_mission] + (_notifications deleteAt 0)) call SPM_MissionAdvance_SendNotification;
	};
};

OO_TRACE_DECL(SPM_MissionAdvance_Create) =
{
	params ["_mission", "_operationName", "_operationPosition", "_controlRadius"];

	private _strongpointName = format ["Advance Operation (%1)", _operationName];
	OO_SET(_mission,Strongpoint,Name,_strongpointName);
	OO_SET(_mission,Strongpoint,InitializeObject,SERVER_InitializeCategoryObject);
	OO_SET(_mission,Strongpoint,SendNotification,SPM_MissionAdvance_SendNotification);
	OO_SET(_mission,Mission,Name,_operationName);
	OO_SET(_mission,Strongpoint,ControlRadius,_controlRadius);

	[_operationPosition, _controlRadius, _controlRadius + ACTIVITY_BORDERWIDTH, 2] call OO_METHOD_PARENT(_mission,Root,Create,Mission);

	private _isUrbanEnvironment = false;
	if (locationPosition nearestLocation [_operationPosition, "NameCity"] distance _operationPosition < 200) then { _isUrbanEnvironment = true };
	if (locationPosition nearestLocation [_operationPosition, "NameCityCapital"] distance _operationPosition < 400) then { _isUrbanEnvironment = true };
	OO_SET(_mission,MissionAdvance,IsUrbanEnvironment,_isUrbanEnvironment);
};

OO_TRACE_DECL(SPM_MissionAdvance_CreateRadioTower) =
{
	params ["_garrison", "_area", "_objectives", "_objectiveSupportCategories", "_availableForDuty"];

	// Find a position in the garrison area
	private _center = OO_GET(_area,StrongpointArea,Position);
	private _outerRadius = OO_GET(_area,StrongpointArea,OuterRadius);

	private _position = [0,0,0];
	while { not ([_position] call OO_METHOD(_area,StrongpointArea,PositionInArea)) || { surfaceIsWater _position } } do
	{
		_position = _center vectorAdd [-(_outerRadius / 2) + random _outerRadius, -(_outerRadius / 2) + random _outerRadius, 0];
	};

	// Create a 50 meter radius area in which the tower can be placed, giving it some room to look for a good spot
	private _towerArea = [_position, 0, 50] call OO_CREATE(StrongpointArea);
	private _radioTower = ["Land_Communication_F", _towerArea] call OO_CREATE(RadioTowerCategory);
	_objectiveSupportCategories pushBack _radioTower;

	private _objective = [_radioTower] call OO_CREATE(ObjectiveMarkRadioTower);
	_objectives pushBack _objective;

	private _pulse = [_objective, 0.8] call OO_CREATE(DamagePulseCategory);
	_objectiveSupportCategories pushBack _pulse;

	if (_availableForDuty > 0) then
	{
		private _assignedToDuty = _availableForDuty min 2;
		_availableForDuty = _availableForDuty - _assignedToDuty;

		private _guardableObject = [] call OO_CREATE(GuardableObjectiveObject);
		OO_SET(_guardableObject,GuardableObjectiveObject,Objective,_objective);

		_category = [_guardableObject, _garrison, _assignedToDuty] call OO_CREATE(GuardObjectCategory);
		_objectiveSupportCategories pushBack _category;
	};

	_availableForDuty
};

OO_TRACE_DECL(SPM_MissionAdvance_CreateSatelliteCommunicationCenter) =
{
	params ["_description", "_garrison", "_forceSupportCategories", "_objectives", "_objectiveSupportCategories", "_availableForDuty"];

	// Create the communications center
	private _category = [_garrison] call OO_CREATE(SatelliteCommunicationCenterCategory);
	_forceSupportCategories pushBack _category;

	private _communicationCenter = _category;

	// And the objective to destroy it
	private _objective = [_category] call OO_CREATE(ObjectiveDestroyCommunicationCenter);
	OO_SET(_objective,ObjectiveDestroyCommunicationCenter,Description,_description);

	_objectives pushBack _objective;

	if (_availableForDuty > 0) then
	{
		private _guardableObject = [] call OO_CREATE(GuardableObjectiveObject);
		OO_SET(_guardableObject,GuardableObjectiveObject,Objective,_objective);

		_assignedToDuty = _availableForDuty min 4.0;
		_availableForDuty = _availableForDuty - _assignedToDuty;

		private _category = [_guardableObject, _garrison, _assignedToDuty] call OO_CREATE(GuardObjectCategory);
		_objectiveSupportCategories pushBack _category;
	};

	[_communicationCenter, _availableForDuty]
};

OO_TRACE_DECL(SPM_MissionAdvance_AddFactionCSAT) =
{
	params ["_mission", "_garrisonCount", "_garrisonCountInitial", "_garrisonCountReserve", "_factionPriority"];

	private _operationPosition = OO_GET(_mission,Strongpoint,Position);
	private _activityRadius = OO_GET(_mission,Strongpoint,ActivityRadius);
	private _controlRadius = OO_GET(_mission,Strongpoint,ControlRadius);
	private _isUrbanEnvironment = OO_GET(_mission,MissionAdvance,IsUrbanEnvironment);

	private _garrisonRatingsEast = SPM_InfantryGarrison_RatingsEast;
	private _garrisonCallupsEast = SPM_InfantryGarrison_CallupsEast;
	private _garrisonInitialCallupsEast = SPM_InfantryGarrison_InitialCallupsEast;

	// Determine if any garrison units can be formed either initially or as reinforcements
	private _smallestCallup = 1e10; { _smallestCallup = _smallestCallup min (_x select 1 select 1) } forEach _garrisonCallupsEast;
	private _smallestInitialCallup = 1e10; { _smallestInitialCallup = _smallestInitialCallup min (_x select 1 select 1) } forEach _garrisonInitialCallupsEast;

	_garrisonCountReserve = floor (_garrisonCountReserve / _smallestCallup) * _smallestCallup;
	_garrisonCountInitial = floor (_garrisonCountInitial / _smallestInitialCallup) * _smallestInitialCallup;

	// If no garrison units can be formed, don't add anything
	if (_garrisonCountReserve == 0 && _garrisonCountInitial == 0) exitWith {};

	private _isReinforcedGarrison = (_garrisonCountInitial > 0 && { _garrisonCountReserve > 0 });
	private _isBivouackedGarrison = (_garrisonCountInitial > 0 && { _garrisonCountReserve == 0 });
	private _isCounterattack = (_garrisonCountInitial == 0 && { _garrisonCountReserve > 0 });

	private _garrisonRadius = _controlRadius;

	private _area = OO_NULL;
	private _category = OO_NULL;
	private _objective = OO_NULL;

	private _forceCategories = []; // Categories that originate units
	private _forceSupportCategories = []; // Categories that are dependent on those units
	private _objectives = []; // Objectives
	private _objectiveSupportCategories = []; // Categories that are dependent on those objectives

	private _headquartersCommanded = [];

	// If the garrison has an effective reserve, create a transport category so they can come in
	private _transport = OO_NULL;
	if (_isReinforcedGarrison || _isCounterattack) then
	{
		_category = [] call OO_CREATE(TransportCategory);
		["Name", "Novorossiya Armed Forces Transport"] call OO_METHOD(_category,Category,SetTagValue);
		OO_SET(_category,TransportCategory,SeaTransports,SPM_Transport_CallupsEastSpeedboat);
		OO_SET(_category,TransportCategory,GroundTransports,SPM_Transport_CallupsEastMarid);
		OO_SET(_category,TransportCategory,AirTransports,SPM_Transport_CallupsEastMohawk);
		_forceCategories pushBack _category;
		_headquartersCommanded pushBack _category;

		_transport = _category;
	};

	// If the csat have at least a 50% role in the operation, give them support units
	if (_factionPriority >= 0.5) then
	{
		_area = [_operationPosition, 0, _activityRadius] call OO_CREATE(StrongpointArea);
		_category = [_area] call OO_CREATE(AirDefenseCategory);
		["Name", "EastAirDefense"] call OO_METHOD(_category,Category,SetTagValue);
		OO_SET(_category,ForceCategory,RatingsWest,SPM_AirDefense_RatingsWest);
		OO_SET(_category,ForceCategory,RatingsEast,SPM_AirDefense_RatingsEast);
		OO_SET(_category,ForceCategory,CallupsEast,SPM_AirDefense_CallupsEast);
		OO_SET(_category,ForceCategory,RangeWest,10000);
		_forceCategories pushBack _category;
		_headquartersCommanded pushBack _category;

		// Armor for armor
		_area = [_operationPosition, _garrisonRadius, _activityRadius] call OO_CREATE(StrongpointArea);
		_category = [_area] call OO_CREATE(ArmorCategory);
		["Name", "EastVersusArmor"] call OO_METHOD(_category,Category,SetTagValue);
		OO_SET(_category,ArmorCategory,PatrolType,"target");
		OO_SET(_category,ForceCategory,RatingsWest,SPM_Armor_RatingsWestAPCs+SPM_Armor_RatingsWestTanks);
		OO_SET(_category,ForceCategory,RatingsEast,SPM_Armor_RatingsEastAPCs+SPM_Armor_RatingsEastTanks+SPM_Armor_RatingsEastAir);
		OO_SET(_category,ForceCategory,CallupsEast,SPM_Armor_CallupsEastAPCs+SPM_Armor_CallupsEastTanks+SPM_Armor_CallupsEastAir);
		OO_SET(_category,ForceCategory,RangeWest,1500);
		OO_SET(_category,ForceCategory,UnitsCanRetire,true);
		OO_SET(_category,ForceCategory,SkillLevel,1.0);
		_forceCategories pushBack _category;
		_headquartersCommanded pushBack _category;

		// Armor for attack aircraft
		_area = [_operationPosition, _garrisonRadius, _activityRadius] call OO_CREATE(StrongpointArea);
		_category = [_area] call OO_CREATE(ArmorCategory);
		["Name", "EastVersusCAS"] call OO_METHOD(_category,Category,SetTagValue);
		OO_SET(_category,ForceCategory,RatingsWest,SPM_Armor_RatingsWestAir);
		OO_SET(_category,ForceCategory,RatingsEast,SPM_Armor_RatingsEastAPCs+SPM_Armor_RatingsEastTanks+SPM_Armor_RatingsEastAir);
		OO_SET(_category,ForceCategory,CallupsEast,SPM_Armor_CallupsEastAPCs+SPM_Armor_CallupsEastTanks+SPM_Armor_CallupsEastAir);
		OO_SET(_category,ForceCategory,RangeWest,10000);
		OO_SET(_category,ForceCategory,UnitsCanRetire,true);
		_forceCategories pushBack _category;
		_headquartersCommanded pushBack _category;

#ifdef PLAYERS_USE_AAA
		// Attack aircraft for air defense armor
		_area = [_operationPosition, _garrisonRadius, _activityRadius] call OO_CREATE(StrongpointArea);
		_category = [_area] call OO_CREATE(ArmorCategory);
		["Name", "EastVersusAirDefense"] call OO_METHOD(_category,Category,SetTagValue);
		OO_SET(_category,ArmorCategory,PatrolType,"target");
		OO_SET(_category,ForceCategory,RatingsWest,SPM_Armor_RatingsWestAirDefense);
		OO_SET(_category,ForceCategory,RatingsEast,SPM_Armor_RatingsEastAir);
		OO_SET(_category,ForceCategory,CallupsEast,SPM_Armor_CallupsEastAir);
		OO_SET(_category,ForceCategory,RangeWest,2500);
		OO_SET(_category,ForceCategory,UnitsCanRetire,true);
		_forceCategories pushBack _category;
		_headquartersCommanded pushBack _category;
#endif
	};

	// Patrol vehicles
	_area = [_operationPosition, _garrisonRadius + 20, _garrisonRadius + 120] call OO_CREATE(StrongpointArea);
	_category = [_area] call OO_CREATE(ArmorCategory);
	["Name", "EastPatrolVehicles"] call OO_METHOD(_category,Category,SetTagValue);
	OO_SET(_category,ForceCategory,RatingsWest,SPM_MissionAdvance_Patrol_RatingsWest);
	OO_SET(_category,ForceCategory,RatingsEast,SPM_MissionAdvance_Patrol_RatingsEast);
	OO_SET(_category,ForceCategory,CallupsEast,SPM_MissionAdvance_Patrol_CallupsEast);
	OO_SET(_category,ForceCategory,RangeWest,5000);

	private _ifritRating = -1; { if (_x select 0 == "LOP_US_UAZ_DshKM") exitWith { _ifritRating = (_x select 1 select 0) * (_x select 1 select 1) } } forEach SPM_MissionAdvance_Patrol_RatingsEast;
	private _armorReserves = _ifritRating * round (_garrisonCountInitial / 16); // An Ifrit as support for every two squads in the initial garrison
	_armorReserves = _armorReserves * (["AdvancePatrolVehicleStrength"] call JB_MP_GetParamValue);

	OO_SET(_category,ForceCategory,Reserves,_armorReserves);

//	private _minimumWestForce = [_armorReserves, _ifritRating] call SPM_ForceRating_CreateForce;
//	OO_SET(_category,ForceCategory,InitialMinimumWestForce,_minimumWestForce);

	_forceCategories pushBack _category;
	_headquartersCommanded pushBack _category;

	// Main garrison

	_area = [_operationPosition, 0, _garrisonRadius] call OO_CREATE(StrongpointArea);
	_category = [_area] call OO_CREATE(InfantryGarrisonCategory);
	["Name", "Novorossiya Armed Forces Garrison"] call OO_METHOD(_category,Category,SetTagValue);
	OO_SET(_category,ForceCategory,RangeWest,500);
	if (not OO_ISNULL(_transport)) then { OO_SET(_category,InfantryGarrisonCategory,Transport,_transport) };
	OO_SET(_category,ForceCategory,RatingsWest,SPM_InfantryGarrison_RatingsWest);
	OO_SET(_category,ForceCategory,RatingsEast,_garrisonRatingsEast);
	OO_SET(_category,ForceCategory,CallupsEast,_garrisonCallupsEast);
	OO_SET(_category,InfantryGarrisonCategory,ActivityBorder,200);
	OO_SET(_category,InfantryGarrisonCategory,InitialCallupsEast,_garrisonInitialCallupsEast);

	private _soldierRatingEast = 0;
	{ _soldierRatingEast = _soldierRatingEast + (_x select 1 select 0) } forEach OO_GET(_category,ForceCategory,RatingsEast);
	_soldierRatingEast = _soldierRatingEast / count OO_GET(_category,ForceCategory,RatingsEast);

	private _soldierRatingWest = 0;
	{ _soldierRatingWest = _soldierRatingWest + (_x select 1 select 0) } forEach OO_GET(_category,ForceCategory,RatingsWest);
	_soldierRatingWest = _soldierRatingWest / count OO_GET(_category,ForceCategory,RatingsWest);

	OO_SET(_category,InfantryGarrisonCategory,InitialReserves,_garrisonCountInitial*_soldierRatingEast);
	OO_SET(_category,ForceCategory,Reserves,_garrisonCountInitial*_soldierRatingEast); // Only the initial force.  Additional forces will be provided by a headquarters unit at the appropriate time.

	_forceCategories pushBack _category;
	_headquartersCommanded pushBack _category;

	private _garrison = _category;

	private _availableForDuty = _garrisonCountInitial * 0.5;
	private _assignedToDuty = 0;

	// Headquarters according to the situation

	private _headquarters = OO_NULL;

	switch (true) do
	{
		case _isCounterattack:
		{
			_headquarters = [] call OO_CREATE(HeadquartersCounterattackCategory);
			OO_SETREF(_headquarters,HeadquartersCategory,Garrison,_garrison);
			_headquartersCommanded = _headquartersCommanded apply { OO_REFERENCE(_x) };
			OO_SET(_headquarters,HeadquartersCategory,Commanded,_headquartersCommanded);
			private _description =
			[
				"Defend marked area against Novorossiya Armed Forces counterattack",
				"Novorossiya Armed Forces forces are attempting to take back the marked area.  They will send infantry by air, sea or land, and will also send armor units to deal with any friendly armor.  Maintain a presence inside the marked area at all times."
			];
			OO_SET(_headquarters,HeadquartersCategory,Description,_description);

			_objectives pushBack _headquarters;

			// Set the minimum west force on the garrison so it will always try to match that from its reserves
			private _minimumWestForce = [_garrisonCount * _soldierRatingEast, _soldierRatingWest] call SPM_ForceRating_CreateForce;
			OO_SET(_garrison,ForceCategory,InitialMinimumWestForce,_minimumWestForce);
			OO_SET(_garrison,ForceCategory,MinimumWestForce,_minimumWestForce);

			// Set the reserve level directly on the garrison because they're all immediately available
			OO_SET(_garrison,ForceCategory,Reserves,_garrisonCountReserve*_soldierRatingEast);
		};

		case _isBivouackedGarrison:
		{
			// Create a satellite communications center
			private _description =
			[
				"Destroy Novorossiya Armed Forces satellite communications center",
				"Novorossiya Armed Forces forces are using a satellite phone at their field communications center to stay in contact with their headquarters.  Locate the satellite phone and destroy it with a grenade or other explosives.  Be alert for the sound of comms chatter."
			];
			private _result = [_description, _garrison, _forceSupportCategories, _objectives, _objectiveSupportCategories, _availableForDuty] call SPM_MissionAdvance_CreateSatelliteCommunicationCenter;
			private _communicationCenter = _result select 0;
			_availableForDuty = _result select 1;

			_headquarters = [] call OO_CREATE(HeadquartersBivouackedCategory);
			OO_SETREF(_headquarters,HeadquartersCategory,Garrison,_garrison);
			_headquartersCommanded = _headquartersCommanded apply { OO_REFERENCE(_x) };
			OO_SET(_headquarters,HeadquartersCategory,Commanded,_headquartersCommanded);
			OO_SET(_headquarters,HeadquartersBivouackedCategory,SurrenderRating,8*_soldierRatingEast);
			private _description =
			[
				"Destroy bivouacked Novorossiya Armed Forces garrison",
				"A Novorossiya Armed Forces garrison is camped at the marked location.  Destroy the garrison."
			];
			OO_SET(_headquarters,HeadquartersCategory,Description,_description);

			_objectives pushBack _headquarters;
		};

		case _isReinforcedGarrison:
		{
			// Send in reinforcements when the garrison is significantly understrength
			private _garrisonCountReact = _garrisonCount * 0.50;
			// Reserves become available over a period of time (3-8 minutes)
			private _mobilizationTime = (3*60) + random (5*60);

			// Create a satellite communications center
			private _description =
			[
				"Destroy Novorossiya Armed Forces satellite communications center",
				"Novorossiya Armed Forces forces are using a satellite phone to mobilize infantry reinforcements.  Find the communication center and put it out of action by use of a grenade or other explosive to destroy that phone.  There are two types of communications centers, urban and field.  Urban centers can be found inside buildings.  The satellite dish will be mounted to the roof and the satellite phone will be somewhere inside the building.  Field centers can be found under a large camoflaged netting that covers a vehicle.  In both cases, you should be able to hear comms chatter when you're close."
			];
			private _result = [_description, _garrison, _forceSupportCategories, _objectives, _objectiveSupportCategories, _availableForDuty] call SPM_MissionAdvance_CreateSatelliteCommunicationCenter;
			private _communicationCenter = _result select 0;
			_availableForDuty = _result select 1;

			// Create a reinforcing headquarters that depends on the communications center
			_headquarters = [_communicationCenter] call OO_CREATE(HeadquartersReinforcedCategory);
			OO_SETREF(_headquarters,HeadquartersCategory,Garrison,_garrison);
			_headquartersCommanded = _headquartersCommanded apply { OO_REFERENCE(_x) };
			OO_SET(_headquarters,HeadquartersCategory,Commanded,_headquartersCommanded);

			private _mobilizationRate = 1e30;
			if (_mobilizationTime > 0) then { _mobilizationRate = _garrisonCountReserve * _soldierRatingEast / _mobilizationTime };

			OO_SET(_headquarters,HeadquartersReinforcedCategory,ReinforcementPool,_garrisonCountReserve*_soldierRatingEast);
			OO_SET(_headquarters,HeadquartersReinforcedCategory,ReinforceRating,_garrisonCountReact*_soldierRatingEast);
			OO_SET(_headquarters,HeadquartersReinforcedCategory,MobilizationRate,_mobilizationRate);
			private _description =
			[
				"Destroy reinforced Novorossiya Armed Forces garrison",
				"Novorossiya Armed Forces forces are entrenched at the marked location, so you should expect stiff resistance.  The enemy will certainly have an infantry garrison with patrolling light armor.  In addition, expect mine fields, checkpoints, heavy machine guns and other support units.  If friendly forces dispatch air or armor units, the enemy will counter those units."
			];
			OO_SET(_headquarters,HeadquartersCategory,Description,_description);

			_objectives pushBack _headquarters;

			// Set the minimum west force on the garrison so it will always try to match that from its reserves
			private _minimumWestForce = [_garrisonCount * _soldierRatingEast, _soldierRatingWest] call SPM_ForceRating_CreateForce;
			OO_SET(_garrison,ForceCategory,MinimumWestForce,_minimumWestForce);

			// Create the mine fields
			private _fieldRadius = _garrisonRadius min 200.0;
			private _fieldWidth = (floor ln _garrisonCountInitial) * 5.0;
			_area = [_operationPosition, _fieldRadius - _fieldWidth, _fieldRadius] call OO_CREATE(StrongpointArea);
			_category = [] call OO_CREATE(MinesCategory);
			OO_SET(_category,MinesCategory,Area,_area);

			_forceSupportCategories pushBack _category;
		};
	};

	// Mortars

	if ((_isReinforcedGarrison || _isBivouackedGarrison) && { _availableForDuty > 0 } && { random 1 < (_garrisonCountInitial * 0.01) }) then
	{
		_assignedToDuty = _availableForDuty min 4.0;
		_availableForDuty = _availableForDuty - _assignedToDuty;

		_category = [1, _garrison] call OO_CREATE(MortarCategory);
		OO_SET(_category,MortarCategory,TeamSize,_assignedToDuty);
		_forceSupportCategories pushBack _category;

		OO_GET(_garrison,InfantryGarrisonCategory,Mortars) pushBack _category;
	};

	// SAM site

	if ((_isReinforcedGarrison || _isBivouackedGarrison) && { random 1 < (_garrisonCountInitial * 0.005) }) then
	{
		assignedToDuty = _availableForDuty min 4.0;
		_availableForDuty = _availableForDuty - _assignedToDuty;

		private _area = OO_GET(_garrison,ForceCategory,Area);
		private _center = OO_GET(_area,StrongpointArea,Position);
		private _outerRadius = OO_GET(_area,StrongpointArea,OuterRadius);

		private _position = [0,0,0];
		while { not ([_position] call OO_METHOD(_area,StrongpointArea,PositionInArea)) || { surfaceIsWater _position } } do
		{
			_position = _center vectorAdd [-(_outerRadius / 2) + random _outerRadius, -(_outerRadius / 2) + random _outerRadius, 0];
		};

		// Create a 500 meter radius area in which the SAM site can be placed, giving it some room to look for a good spot
		_area = [_position, 0, 500] call OO_CREATE(StrongpointArea);
		private _samSite = [_area] call OO_CREATE(SAMCategory);
		_forceSupportCategories pushBack _samSite;
		
		private _objective = [_samSite] call OO_CREATE(ObjectiveDestroySAM);
		_objectives pushBack _objective;
	};


	// Ammo dump

	if (_isReinforcedGarrison && { _availableForDuty > 0 } && { random 1 < (_garrisonCountInitial * 0.01) }) then
	{
		_assignedToDuty = _availableForDuty min 4.0;
		_availableForDuty = _availableForDuty - _assignedToDuty;

		private _area = OO_GET(_garrison,ForceCategory,Area);
		private _center = OO_GET(_area,StrongpointArea,Position);
		private _outerRadius = OO_GET(_area,StrongpointArea,OuterRadius);

		private _position = [0,0,0];
		while { not ([_position] call OO_METHOD(_area,StrongpointArea,PositionInArea)) || { surfaceIsWater _position } } do
		{
			_position = _center vectorAdd [-(_outerRadius / 2) + random _outerRadius, -(_outerRadius / 2) + random _outerRadius, 0];
		};

		// Create a 50 meter radius area in which the dump can be placed, giving it some room to look for a good spot
		_area = [_position, 0, 50] call OO_CREATE(StrongpointArea);
		private _ammoDump = [_area] call OO_CREATE(AmmoDumpCategory);
		_forceSupportCategories pushBack _ammoDump;

		private _objective = [_ammoDump] call OO_CREATE(ObjectiveMarkAmmoDump);
		_objectives pushBack _objective;

		private _pulse = [_objective, 8.0] call OO_CREATE(DamagePulseCategory);
		OO_SET(_pulse,DamagePulseCategory,DamageScale,0.06); // Make the barrel very durable
		_forceSupportCategories pushBack _pulse;

		private _guardableObject = [] call OO_CREATE(GuardableObjectiveObject);
		OO_SET(_guardableObject,GuardableObjectiveObject,Objective,_objective);

		_category = [_guardableObject, _garrison, _assignedToDuty] call OO_CREATE(GuardObjectCategory);
		_objectiveSupportCategories pushBack _category;
	};

	// Checkpoints

	if (_isReinforcedGarrison && { _availableForDuty > 0 } && { random 1 < (_garrisonCountInitial * 0.02) }) then
	{
		_assignedToDuty = _availableForDuty min floor (_garrisonCountInitial * 0.12); // 12 guys for garrison of 100, 3 guys per checkpoint = 4 checkpoints
		_availableForDuty = _availableForDuty - _assignedToDuty;

		//TODO: Find players within 5km and average their positions.  Create the checkpoints on that side of the mission (Coverage property)
		private _area = OO_GET(_garrison,ForceCategory,Area);
		_category = [_area, _garrison, _assignedToDuty] call OO_CREATE(CheckpointsCategory);

		_forceSupportCategories pushBack _category;
	};

	// Radio towers

	if (_isReinforcedGarrison && { random 1 < (_garrisonCountInitial * 0.01) }) then
	{
		private _numberTowers = 1;
		if (_isUrbanEnvironment) then { _numberTowers = _numberTowers + round random 2 };

		_area = OO_GET(_garrison,ForceCategory,Area);

		if (_numberTowers == 1) then
		{
			_availableForDuty = [_garrison, _area, _objectives, _objectiveSupportCategories, _availableForDuty] call SPM_MissionAdvance_CreateRadioTower;
		}
		else
		{
			private _description = [format ["Mark radio towers (%1) for demolition", _numberTowers], "Locate each radio tower and use its scroll wheel action to mark the location of the tower for the EOD team."];
			private _compoundObjective = [_description] call OO_CREATE(ObjectiveCompound);
			[_compoundObjective] call OO_METHOD(_mission,Mission,AddObjective); // Compound must be added to the mission before adding the children to the compound

			private _childObjectives = [];
			for "_i" from 1 to _numberTowers do
			{
				_availableForDuty = [_garrison, _area, _childObjectives, _objectiveSupportCategories, _availableForDuty] call SPM_MissionAdvance_CreateRadioTower;
			};

			private _succeededOrError = ["succeeded", "error"];
			{
				OO_SET(_x,MissionObjective,CompletionStates,_succeededOrError); // When multiple towers, just let failing ones pass silently
				[_x] call OO_METHOD(_compoundObjective,ObjectiveCompound,AddObjective);
			} forEach _childObjectives;
		};
	};

	// Infantry Patrols

	// Small chance of no patrols and no movement by garrisoned soldiers in urban environments
	if (_isUrbanEnvironment && random 1 < 0.15) then
	{
		OO_SET(_garrison,InfantryGarrisonCategory,RelocateProbability,0.0);
	}
	else
	{
		private _innerPatrolSize = 4.0;
		private _outerPatrolSize = 2.0;
		if (_availableForDuty > (_innerPatrolSize max _outerPatrolSize)) then
		{
			private _innerPatrols = OO_NULL;
			private _outerPatrols = OO_NULL;

			while { _availableForDuty >= (_innerPatrolSize min _outerPatrolSize) } do
			{
				if (_availableForDuty >= _innerPatrolSize) then
				{
					if (OO_ISNULL(_innerPatrols)) then
					{
						_area = [_operationPosition, _garrisonRadius * 0.25, _garrisonRadius * 0.75] call OO_CREATE(StrongpointArea);
						_innerPatrols = [_area, _garrison] call OO_CREATE(PerimeterPatrolCategory);
						["Name", "NovorossiyaArmedForcesInnerPerimeterPatrol"] call OO_METHOD(_innerPatrols,Category,SetTagValue);
						OO_SET(_innerPatrols,InfantryPatrolCategory,OnStartPatrol,SERVER_Infantry_OnStartPatrol);
					};
					_availableForDuty = _availableForDuty - _innerPatrolSize;
					[_innerPatrolSize, selectRandom [true, false], 50, 1, 0.2, 0.0] call OO_METHOD(_innerPatrols,InfantryPatrolCategory,AddPatrol);
				};

				if (_availableForDuty >= _outerPatrolSize) then
				{
					if (OO_ISNULL(_outerPatrols)) then
					{
						_area = [_operationPosition, _garrisonRadius * 0.75, _garrisonRadius * 1.25] call OO_CREATE(StrongpointArea);
						_outerPatrols = [_area, _garrison] call OO_CREATE(PerimeterPatrolCategory);
						["Name", "NovorossiyaArmedForcesOuterPerimeterPatrol"] call OO_METHOD(_outerPatrols,Category,SetTagValue);
						["Name", "NovorossiyaArmedForcesSpecialForcesPatrol"] call OO_METHOD(_outerPatrols,Category,SetTagValue);
						OO_SET(_outerPatrols,InfantryPatrolCategory,OnStartPatrol,SERVER_Infantry_OnStartPatrol);
					};
					_availableForDuty = _availableForDuty - _outerPatrolSize;
					[_outerPatrolSize, selectRandom [true, false], 50, 1, 0.2, 0.0] call OO_METHOD(_outerPatrols,InfantryPatrolCategory,AddPatrol);
				};
			};

			if (not OO_ISNULL(_innerPatrols)) then { _forceSupportCategories pushBack _innerPatrols };
			if (not OO_ISNULL(_outerPatrols)) then { _forceSupportCategories pushBack _outerPatrols };
		};
	};

	// Static trucks to provide fiction of garrison transport
	if (_isReinforcedGarrison || _isBivouackedGarrison) then
	{
		private _numberPlayerTransports = 1;
		OO_SET(_mission,MissionAdvance,NumberPlayerTransports,_numberPlayerTransports);

		private _numberTransports = (round (_garrisonCountInitial / 16)) max _numberPlayerTransports;
		private _trucks = [];
		for "_i" from 1 to _numberTransports do
		{
			_trucks pushBack "LOP_US_Ural";
		};
		_category = [_operationPosition, _trucks, 7.0] call OO_CREATE(ParkedVehiclesCategory);

		_forceCategories pushBack _category;
	};

	// Add all the categories
	{
		[_x] call OO_METHOD(_mission,Strongpoint,AddCategory);
	} forEach _forceCategories;
	{
		[_x] call OO_METHOD(_mission,Strongpoint,AddCategory);
	} forEach _forceSupportCategories;
	{
		[_x] call OO_METHOD(_mission,Mission,AddObjective);
	} forEach _objectives;
	{
		[_x] call OO_METHOD(_mission,Strongpoint,AddCategory);
	} forEach _objectiveSupportCategories;
};

OO_TRACE_DECL(SPM_MissionAdvance_AddFactionSyndikat) =
{
	params ["_mission", "_garrisonCount", "_garrisonCountInitial", "_garrisonCountReserve", "_factionPriority"];

	private _activityRadius = OO_GET(_mission,Strongpoint,ActivityRadius);
	private _controlRadius = OO_GET(_mission,Strongpoint,ControlRadius);
	private _operationPosition = OO_GET(_mission,Strongpoint,Position);

	private _garrisonRatingsEast = SPM_InfantryGarrison_RatingsSyndikat;
	private _garrisonCallupsEast = SPM_InfantryGarrison_CallupsSyndikat;
	private _garrisonInitialCallupsEast = SPM_InfantryGarrison_InitialCallupsSyndikat;

	// Determine if any garrison units can be formed either initially or as reinforcements
	private _smallestCallup = 1e10; { _smallestCallup = _smallestCallup min (_x select 1 select 1) } forEach _garrisonCallupsEast;
	private _smallestInitialCallup = 1e10; { _smallestInitialCallup = _smallestInitialCallup min (_x select 1 select 1) } forEach _garrisonInitialCallupsEast;

	_garrisonCountReserve = floor (_garrisonCountReserve / _smallestCallup) * _smallestCallup;
	_garrisonCountInitial = floor (_garrisonCountInitial / _smallestInitialCallup) * _smallestInitialCallup;

	// If no garrison units can be formed, don't add anything
	if (_garrisonCountReserve == 0 && _garrisonCountInitial == 0) exitWith {};

	private _isReinforcedGarrison = (_garrisonCountInitial > 0 && { _garrisonCountReserve > 0 });
	private _isBivouackedGarrison = (_garrisonCountInitial > 0 && { _garrisonCountReserve == 0 });
	private _isCounterattack = (_garrisonCountInitial == 0 && { _garrisonCountReserve > 0 });

	// Syndikat isn't involved in counterattacks
	if (_isCounterattack) exitWith {};

	private _garrisonRadius = _controlRadius;

	private _area = OO_NULL;
	private _category = OO_NULL;
	private _objective = OO_NULL;

	private _forceCategories = []; // Categories that originate units
	private _forceSupportCategories = []; // Categories that are dependent on those units
	private _objectives = []; // Objectives
	private _objectiveSupportCategories = []; // Categories that are dependent on those objectives

	private _headquartersCommanded = [];

	// If the garrison has an effective reserve, create a transport category so they can come in
	private _transport = OO_NULL;
	if (_isReinforcedGarrison && false) then // Vehicle transport is currently disabled
	{
		_category = [] call OO_CREATE(TransportCategory);
		["Name", "PMCTransport"] call OO_METHOD(_category,Category,SetTagValue);
		OO_SET(_category,TransportCategory,GroundTransports,SPM_Transport_CallupsEastTruck);
		OO_SET(_category,TransportCategory,SeaTransports,[]);
		OO_SET(_category,TransportCategory,AirTransports,[]);
		OO_SET(_category,TransportCategory,SideEast,independent);
		_forceCategories pushBack _category;
		_headquartersCommanded pushBack _category;

		_transport = _category;
	};

	// Patrol vehicles
	_area = [_operationPosition, _garrisonRadius + 20, _garrisonRadius + 120] call OO_CREATE(StrongpointArea);
	_category = [_area] call OO_CREATE(ArmorCategory);
	["Name", "PMCPatrolVehicles"] call OO_METHOD(_category,Category,SetTagValue);
	OO_SET(_category,ForceCategory,SideEast,independent);
	OO_SET(_category,ForceCategory,RatingsWest,SPM_MissionAdvance_Patrol_RatingsWest);
	OO_SET(_category,ForceCategory,RatingsEast,SPM_MissionAdvance_Patrol_RatingsSyndikat);
	OO_SET(_category,ForceCategory,CallupsEast,SPM_MissionAdvance_Patrol_CallupsSyndikat);
	OO_SET(_category,ForceCategory,RangeWest,5000);

	private _offroadRating = -1; { if (_x select 0 == "LOP_US_UAZ_DshKM") exitWith { _offroadRating = (_x select 1 select 0) * (_x select 1 select 1) } } forEach SPM_MissionAdvance_Patrol_RatingsSyndikat;
	private _armorReserves = _offroadRating * round (_garrisonCountInitial / 16); // An offroad as support for every two squads in the initial garrison
	_armorReserves = _armorReserves * (["AdvancePatrolVehicleStrength"] call JB_MP_GetParamValue);

	OO_SET(_category,ForceCategory,Reserves,_armorReserves);

//	private _minimumWestForce = [_armorReserves, _offroadRating] call SPM_ForceRating_CreateForce;
//	OO_SET(_category,ForceCategory,InitialMinimumWestForce,_minimumWestForce);

	_forceCategories pushBack _category;
	_headquartersCommanded pushBack _category;

	// Main garrison

	_area = [_operationPosition, 0, _garrisonRadius] call OO_CREATE(StrongpointArea);
	_category = [_area] call OO_CREATE(InfantryGarrisonCategory);
	["Name", "PMCGarrison"] call OO_METHOD(_category,Category,SetTagValue);
	OO_SET(_category,ForceCategory,RangeWest,500);
	if (not OO_ISNULL(_transport)) then { OO_SET(_category,InfantryGarrisonCategory,Transport,_transport) };
	OO_SET(_category,ForceCategory,RatingsWest,SPM_InfantryGarrison_RatingsWest);
	OO_SET(_category,ForceCategory,SideEast,independent);
	OO_SET(_category,ForceCategory,RatingsEast,_garrisonRatingsEast);
	OO_SET(_category,ForceCategory,CallupsEast,_garrisonCallupsEast);
	OO_SET(_category,ForceCategory,SkillLevel,0.4);
	OO_SET(_category,InfantryGarrisonCategory,ActivityBorder,200);
	OO_SET(_category,InfantryGarrisonCategory,InitialCallupsEast,_garrisonInitialCallupsEast);

	private _soldierRatingEast = 0;
	{ _soldierRatingEast = _soldierRatingEast + (_x select 1 select 0) } forEach OO_GET(_category,ForceCategory,RatingsEast);
	_soldierRatingEast = _soldierRatingEast / count OO_GET(_category,ForceCategory,RatingsEast);

	private _soldierRatingWest = 0;
	{ _soldierRatingWest = _soldierRatingWest + (_x select 1 select 0) } forEach OO_GET(_category,ForceCategory,RatingsWest);
	_soldierRatingWest = _soldierRatingWest / count OO_GET(_category,ForceCategory,RatingsWest);

	OO_SET(_category,InfantryGarrisonCategory,InitialReserves,_garrisonCountInitial*_soldierRatingEast);
	OO_SET(_category,ForceCategory,Reserves,_garrisonCountInitial*_soldierRatingEast+_garrisonCountReserve*_soldierRatingEast); // Initial force plus reserve immediately.

	private _minimumWestForce = [_garrisonCountInitial * _soldierRatingEast, _soldierRatingWest] call SPM_ForceRating_CreateForce;
	OO_SET(_category,ForceCategory,InitialMinimumWestForce,_minimumWestForce);
	OO_SET(_category,ForceCategory,MinimumWestForce,_minimumWestForce);

	_forceCategories pushBack _category;
	_headquartersCommanded pushBack _category;

	private _garrison = _category;

	private _availableForDuty = _garrisonCountInitial * 0.8;
	private _assignedToDuty = 0;

	// Create the communications center
	_category = [_garrison] call OO_CREATE(RadioCommunicationCenterCategory);
	_forceSupportCategories pushBack _category;

	_objective = [_category] call OO_CREATE(ObjectiveDestroyCommunicationCenter);
	private _description =
	[
		"Destroy PMC radio communications center",
		"Radio communications centers in cities consist of a transmitter tower on a small communication building.  Centers outside of cities are mobile, taking the form of a van with communications gear inside.  The urban center can be destroyed with three grenades or with sufficient explosives to otherwise destroy the building.  The field centers can be destroyed with a single grenade on the generator in the back of the van.  Comms chatter should help you locate each center."
	];
	OO_SET(_objective,ObjectiveDestroyCommunicationCenter,Description,_description);

	_objectives pushBack _objective;

	if (_availableForDuty > 0) then
	{
		private _guardableObject = [] call OO_CREATE(GuardableObjectiveObject);
		OO_SET(_guardableObject,GuardableObjectiveObject,Objective,_objective);

		_assignedToDuty = _availableForDuty min 4.0;
		_availableForDuty = _availableForDuty - _assignedToDuty;

		private _category = [_guardableObject, _garrison, _assignedToDuty] call OO_CREATE(GuardObjectCategory);
		_objectiveSupportCategories pushBack _category;
	};

	// Simple headquarters
	private _headquartersCategories = [];

	_objective = [] call OO_CREATE(HeadquartersGarrisonCategory);
	OO_SETREF(_objective,HeadquartersCategory,Garrison,_garrison);
	_headquartersCommanded = _headquartersCommanded apply { OO_REFERENCE(_x) };
	OO_SET(_objective,HeadquartersCategory,Commanded,_headquartersCommanded);
	OO_SET(_objective,HeadquartersGarrisonCategory,SurrenderRating,_garrisonCountInitial*0.20*_soldierRatingEast);
	OO_SET(_objective,HeadquartersCategory,FlagpoleType,"Flag_Syndikat_F");
	private _description =
	[
		"Destroy PMC forces",
		"PMC light infantry is operating at the marked location and must be wiped out. This infantry is supported by light patrol vehicles."
	];
	OO_SET(_objective,HeadquartersCategory,Description,_description);

	_objectives pushBack _objective;

	// Infantry Patrols for whoever else is available for duty

	private _perimeterPatrolSize = 4.0;
	private _perimeterPatrols = OO_NULL;

	_area = [_operationPosition, _garrisonRadius * 0.50, _garrisonRadius * 1.25] call OO_CREATE(StrongpointArea);

	while { _availableForDuty >= _perimeterPatrolSize } do
	{
		if (OO_ISNULL(_perimeterPatrols)) then
		{
			_perimeterPatrols = [_area, _garrison] call OO_CREATE(PerimeterPatrolCategory);
			["Name", "PMCPerimeterPatrol"] call OO_METHOD(_perimeterPatrols,Category,SetTagValue);
			OO_SET(_perimeterPatrols,InfantryPatrolCategory,OnStartPatrol,SERVER_Infantry_OnStartPatrol);
		};
		_availableForDuty = _availableForDuty - _perimeterPatrolSize;
		[_perimeterPatrolSize, selectRandom [true, false], 50, 1, 0.2, 0.0] call OO_METHOD(_perimeterPatrols,InfantryPatrolCategory,AddPatrol);
	};

	if (not OO_ISNULL(_perimeterPatrols)) then { _forceSupportCategories pushBack _perimeterPatrols };

	// Possibility of ammunition caches

	if (random 1 < (_garrisonCountInitial * 0.005)) then
	{
		private _numberCaches = round (_garrisonCountInitial / 8);
		if (_numberCaches > 0) then
		{
			private _containerTypes = [[["Box_Syndicate_Ammo_F", 500], ["Box_IED_Exp_F", 5000], ["Box_Syndicate_WpsLaunch_F", 2000, true], ["Box_Syndicate_Wps_F", 1000]]];

			private _category = [_garrison, _numberCaches, [2,5], _containerTypes] call OO_CREATE(AmmoCachesCategory);
			_forceSupportCategories pushBack _category;

			private _objective = [_category, 0.75] call OO_CREATE(ObjectiveMarkAmmoCaches);
			_objectives pushBack _objective;
		};
	};

	// Add all the categories
	{
		[_x] call OO_METHOD(_mission,Strongpoint,AddCategory);
	} forEach _forceCategories;
	{
		[_x] call OO_METHOD(_mission,Strongpoint,AddCategory);
	} forEach _forceSupportCategories;
	{
		[_x] call OO_METHOD(_mission,Mission,AddObjective);
	} forEach _objectives;
	{
		[_x] call OO_METHOD(_mission,Strongpoint,AddCategory);
	} forEach _objectiveSupportCategories;
};

OO_TRACE_DECL(SPM_MissionAdvance_AddFactionAAF) =
{
	params ["_mission", "_garrisonCount", "_garrisonCountInitial", "_garrisonCountReserve", "_factionPriority"];
};

OO_TRACE_DECL(SPM_MissionAdvance_AddFactionFIA) =
{
	params ["_mission", "_garrisonCount", "_garrisonCountInitial", "_garrisonCountReserve", "_factionPriority"];
};

OO_TRACE_DECL(SPM_MissionAdvance_AddFaction) =
{
	params ["_mission", "_faction", "_garrisonCount", "_garrisonCountInitial", "_garrisonCountReserve", "_factionPriority"];

	switch (_faction) do
	{
		case "csat": { [_mission, _garrisonCount, _garrisonCountInitial, _garrisonCountReserve, _factionPriority] call SPM_MissionAdvance_AddFactionCSAT };
		case "syndikat": { [_mission, _garrisonCount, _garrisonCountInitial, _garrisonCountReserve, _factionPriority] call SPM_MissionAdvance_AddFactionSyndikat };
		case "aaf": { [_mission, _garrisonCount, _garrisonCountInitial, _garrisonCountReserve, _factionPriority] call SPM_MissionAdvance_AddFactionAAF };
		case "fia": { [_mission, _garrisonCount, _garrisonCountInitial, _garrisonCountReserve, _factionPriority] call SPM_MissionAdvance_AddFactionFIA };
	};
};

SPM_MissionAdvance_MissionDescriptionLong = "Complete the listed objectives.<br/><br/>Be sure to read the map briefing to understand how to reach the mission site and to use the various mission systems.";

OO_TRACE_DECL(SPM_MissionAdvance_Update) =
{
	params ["_mission"];

	[] call OO_METHOD_PARENT(_mission,Strongpoint,Update,Mission);

	switch (OO_GET(_mission,Mission,Announced)) do
	{
		case "none":
		{
			if ({ OO_GET(_x,MissionObjective,State) == "starting" } count OO_GET(_mission,Mission,Objectives) == 0) then
			{
				OO_SET(_mission,Mission,Announced,"start-of-mission");
				[_mission, OO_NULL, [format ["Action at %1", OO_GET(_mission,Mission,Name)], SPM_MissionAdvance_MissionDescriptionLong], "mission-description"] call OO_GET(_mission,Strongpoint,SendNotification);
			};
		};

		case "start-of-mission":
		{
			switch (OO_GET(_mission,Mission,MissionState)) do
			{
				case "completed-failure":
				{
					OO_SET(_mission,Mission,Announced,"end-of-mission");
					[_mission, OO_NULL, [format ["DEFEAT at %1", OO_GET(_mission,Mission,Name)]], "mission-status"] call OO_GET(_mission,Strongpoint,SendNotification);
					[_mission] call SPM_MissionAdvance_Complete;
				};
				case "completed-success":
				{
					OO_SET(_mission,Mission,Announced,"end-of-mission");
					[_mission, OO_NULL, [format ["VICTORY at %1", OO_GET(_mission,Mission,Name)]], "mission-status"] call OO_GET(_mission,Strongpoint,SendNotification);
					[_mission] call SPM_MissionAdvance_Complete;
				};
				case "command-terminated":
				{
					OO_SET(_mission,Mission,Announced,"end-of-mission");
					[_mission, OO_NULL, [format ["Operation at %1 terminated by command", OO_GET(_mission,Mission,Name)]], "mission-status"] call OO_GET(_mission,Strongpoint,SendNotification);
					[_mission] call SPM_MissionAdvance_Complete;
				};
			};
		};
	};
};

OO_TRACE_DECL(SPM_MissionAdvance_Complete) =
{
	params ["_mission"];

	[OO_GET(_mission,Mission,ParticipantFilter), ([_mission] call SPM_MissionAdvance_MissionTaskIdentifier)] call SPM_Task_Delete;

	// Save some transports for the players to use
	private _parkedVehicles = OO_GET(_mission,Strongpoint,Categories) select { OO_INSTANCE_ISOFCLASS(_x,ParkedVehiclesCategory) };
	if (count _parkedVehicles > 0) then
	{
		_parkedVehicles = _parkedVehicles select 0;

		private _transports = OO_GET(_parkedVehicles,ParkedVehiclesCategory,Vehicles) select { alive _x };

		// Sort surviving trucks by essential health (engine and fuel system)
		_transports = _transports apply { [(_x getHit "motor") + (_x getHit "palivo"), _x] };
		_transports sort true;
		_transports = _transports apply { _x select 1 };

		// Capture the best transports for the players
		for "_i" from 1 to OO_GET(_mission,MissionAdvance,NumberPlayerTransports) do
		{
			if (count _transports == 0) exitWith {};

			private _transport = _transports deleteAt 0;
			[_transport] call OO_METHOD(_parkedVehicles,ParkedVehiclesCategory,CaptureVehicle);

			_transport setVehicleLock "unlocked";
			[_transport] call JB_fnc_respawnVehicleInitialize;
			[_transport, 100, 120, 0, true] call JB_fnc_respawnVehicleWhenAbandoned;
		};
	};
};

OO_TRACE_DECL(SPM_MissionAdvance_Delete) =
{
	params ["_mission"];

	[OO_GET(_mission,Mission,ParticipantFilter), [_mission] call SPM_MissionAdvance_MissionTaskIdentifier] call SPM_Task_Delete;

	[] call OO_METHOD_PARENT(_mission,Root,Delete,Strongpoint);
};

OO_TRACE_DECL(SPM_MissionAdvance_NotifyPlayer) =
{
	params ["_mission", "_player"];

	[["NotificationMissionDescription"] + [format ["Action at %1", OO_GET(_mission,Mission,Name)]], ["notification", "log"], _player] call SPM_Mission_Message;
	[] remoteExec ["SPM_MissionAdvance_C_SeeTasksMessage", _player];
};

OO_BEGIN_SUBCLASS(MissionAdvance,Mission);
	OO_OVERRIDE_METHOD(MissionAdvance,Root,Create,SPM_MissionAdvance_Create);
	OO_OVERRIDE_METHOD(MissionAdvance,Root,Delete,SPM_MissionAdvance_Delete);
	OO_OVERRIDE_METHOD(MissionAdvance,Strongpoint,Update,SPM_MissionAdvance_Update);
	OO_DEFINE_METHOD(MissionAdvance,AddFaction,SPM_MissionAdvance_AddFaction);
	OO_DEFINE_METHOD(MissionAdvance,NotifyPlayer,SPM_MissionAdvance_NotifyPlayer);
	OO_DEFINE_PROPERTY(MissionAdvance,NumberPlayerTransports,"SCALAR",0);
	OO_DEFINE_PROPERTY(MissionAdvance,IsUrbanEnvironment,"BOOL",false);
	OO_DEFINE_PROPERTY(MissionAdvance,_Notifications,"ARRAY",[]);
OO_END_SUBCLASS(MissionAdvance);
