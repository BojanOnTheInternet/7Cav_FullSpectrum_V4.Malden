/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_MissionDisruptMeeting_GetMissionDescription) =
{
	params ["_mission"];

	private _objectiveDescriptions = [];
	{
		_objectiveDescriptions pushBack (_x select 2 select 0);
	} forEach OO_GET(_mission,Mission,NotificationsAccumulator);

	private _positionDescription = [OO_GET(_mission,Strongpoint,Position)] call SPM_Util_PositionDescription;

	["Mission Orders"] + _objectiveDescriptions + ["Location of meeting: " + _positionDescription]
};

OO_TRACE_DECL(SPM_MissionDisruptMeeting_Update) =
{
	params ["_mission"];

	[] call OO_METHOD_PARENT(_mission,Strongpoint,Update,MissionSpecialOperations);

	if (OO_GET(_mission,Mission,Announced) == "none") then
	{
		if ({ OO_GET(_x,MissionObjective,State) == "starting" } count OO_GET(_mission,Mission,Objectives) == 0) then
		{
			private _description = [] call OO_METHOD(_mission,MissionSpecialOperations,GetMissionDescription);

			OO_SET(_mission,Mission,Announced,"start-of-mission");
			[_mission, OO_NULL, _description, "mission-description"] call OO_GET(_mission,Strongpoint,SendNotification);
		};
	};
};

OO_TRACE_DECL(SPM_MissionDisruptMeeting_Create) =
{
	params ["_mission", "_missionPosition", "_missionRadius", "_meetingCount", "_meetingRadius", "_guardCount", "_guardRadius", "_civilianCount", "_civilianRadius"];

	private _faction1Count = floor (_meetingCount / 2);
	private _faction2Count = _meetingCount - _faction1Count;

	[_missionPosition, _meetingRadius + 100, _missionRadius, _faction1Count max _faction2Count] call OO_METHOD_PARENT(_mission,Root,Create,Mission);

	OO_SET(_mission,Strongpoint,Name,"Special Operation");
	OO_SET(_mission,Strongpoint,InitializeObject,SERVER_InitializeCategoryObject);

	OO_SET(_mission,Mission,ParticipantFilter,BOTH_IsSpecOpsMember);

	private _area = [];
	private _category = OO_NULL;
	private _categories = [];

	// East participants garrison
	_area = [_missionPosition, 0, _meetingRadius] call OO_CREATE(StrongpointArea);
	_category = [_area] call OO_CREATE(InfantryGarrisonCategory);
	["Name", "Faction1"] call OO_METHOD(_category,Category,SetTagValue);
	OO_SET(_category,ForceCategory,RatingsWest,SPM_InfantryGarrison_RatingsWest);
	OO_SET(_category,ForceCategory,RatingsEast,SPM_InfantryGarrison_RatingsEast);
	OO_SET(_category,ForceCategory,CallupsEast,SPM_InfantryGarrison_CallupsEast);
	OO_SET(_category,InfantryGarrisonCategory,HousingDistribution,0.0);

	private _garrisonRatingEast = 0;
	{ _garrisonRatingEast = _garrisonRatingEast + (_x select 1 select 0) } forEach OO_GET(_category,ForceCategory,RatingsEast);
	_garrisonRatingEast = _garrisonRatingEast / count OO_GET(_category,ForceCategory,RatingsEast);

	private _garrisonReserves = _faction1Count * _garrisonRatingEast;

	OO_SET(_category,InfantryGarrisonCategory,InitialReserves,_garrisonReserves);
	OO_SET(_category,ForceCategory,Reserves,_garrisonReserves);

	private _eastParticipants = _category;

	_categories pushBack _category;

	// Syndikat participants garrison
	_area = [_missionPosition, 0, _meetingRadius] call OO_CREATE(StrongpointArea);
	_category = [_area] call OO_CREATE(InfantryGarrisonCategory);
	["Name", "Faction2"] call OO_METHOD(_category,Category,SetTagValue);
	OO_SET(_category,ForceCategory,SideEast,independent);
	OO_SET(_category,ForceCategory,RatingsWest,SPM_InfantryGarrison_RatingsWest);
	OO_SET(_category,ForceCategory,RatingsEast,SPM_InfantryGarrison_RatingsSyndikat);
	OO_SET(_category,ForceCategory,CallupsEast,SPM_InfantryGarrison_CallupsSyndikat);
	OO_SET(_category,ForceCategory,SkillLevel,0.35);
	OO_SET(_category,InfantryGarrisonCategory,InitialCallupsEast,SPM_InfantryGarrison_InitialCallupsSyndikat);
	OO_SET(_category,InfantryGarrisonCategory,HousingDistribution,0.0);

	private _garrisonRatingEast = 0;
	{ _garrisonRatingEast = _garrisonRatingEast + (_x select 1 select 0) } forEach OO_GET(_category,ForceCategory,RatingsEast);
	_garrisonRatingEast = _garrisonRatingEast / count OO_GET(_category,ForceCategory,RatingsEast);

	private _garrisonReserves = _faction2Count * _garrisonRatingEast;

	OO_SET(_category,InfantryGarrisonCategory,InitialReserves,_garrisonReserves);
	OO_SET(_category,ForceCategory,Reserves,_garrisonReserves);

	private _syndikatParticipants = _category;

	_categories pushBack _category;

	private _parkedTypes =
	[
		if (random 1 < 0.5) then { "LOP_US_UAZ_DshKM" } else { "LOP_US_UAZ" },
		if (random 1 < 0.5) then { "LOP_US_UAZ" } else { "LOP_US_UAZ_DshKM" },
		"LOP_US_UAZ",
		"LOP_US_UAZ_DshKM"
	];
	_category = [_missionPosition, _parkedTypes, 0.0] call OO_CREATE(ParkedVehiclesCategory);

	_categories pushBack _category;

	// Guards in a separate garrison
	_area = [_missionPosition, _meetingRadius, _guardRadius] call OO_CREATE(StrongpointArea);
	_category = [_area] call OO_CREATE(InfantryGarrisonCategory);
	["Name", "Guards"] call OO_METHOD(_category,Category,SetTagValue);
	OO_SET(_category,ForceCategory,RatingsWest,SPM_InfantryGarrison_RatingsWest);
	OO_SET(_category,ForceCategory,RatingsEast,SPM_InfantryGarrison_RatingsEast);
	OO_SET(_category,ForceCategory,CallupsEast,SPM_InfantryGarrison_CallupsEast);

	private _garrisonRatingEast = 0;
	{ _garrisonRatingEast = _garrisonRatingEast + (_x select 1 select 0) } forEach OO_GET(_category,ForceCategory,RatingsEast);
	_garrisonRatingEast = _garrisonRatingEast / count OO_GET(_category,ForceCategory,RatingsEast);

	private _garrisonReserves = _guardCount * _garrisonRatingEast;

	OO_SET(_category,InfantryGarrisonCategory,InitialReserves,_garrisonReserves);
	OO_SET(_category,ForceCategory,Reserves,_garrisonReserves);

	if (random 1 < 0.5) then
	{
		OO_SET(_category,ForceCategory,SideEast,independent);
		OO_SET(_category,ForceCategory,SkillLevel,0.35);
		OO_SET(_category,ForceCategory,RatingsEast,SPM_InfantryGarrison_RatingsSyndikat);
		OO_SET(_category,ForceCategory,CallupsEast,SPM_InfantryGarrison_CallupsSyndikat);
		OO_SET(_category,InfantryGarrisonCategory,InitialCallupsEast,SPM_InfantryGarrison_InitialCallupsSyndikat);
	};

	private _guards = _category;

	_categories pushBack _category;

	// Guard Patrols
	_area = [_missionPosition, _meetingRadius, _guardRadius] call OO_CREATE(StrongpointArea);
	_category = [_area, _guards] call OO_CREATE(PerimeterPatrolCategory);
	["Name", "Patrols"] call OO_METHOD(_category,Category,SetTagValue);
	_categories pushBack _category;

	private _smallPatrolSize = 2;
	private _largePatrolSize = 4;

	private _smallPatrolCount = 2;
	private _largePatrolCount = floor ((_guardCount - _smallPatrolCount * _smallPatrolSize) / _largePatrolSize);

	for "_i" from 1 to _smallPatrolCount do
	{
		[_smallPatrolSize, true, 50, 1, 0.2, 0.0] call OO_METHOD(_category,InfantryPatrolCategory,AddPatrol);
	};
	for "_i" from 1 to _largePatrolCount do
	{
		[_largePatrolSize, true, 50, 1, 0.2, 0.0] call OO_METHOD(_category,InfantryPatrolCategory,AddPatrol);
	};

	// Pick an isolated position to which the principals can flee

	private _blacklist = ([1000, 0, -1] call SERVER_OperationBlacklist) + [[_missionRadius, _missionPosition]];

	private _data = [];
	private _chain =
		[
			[SPM_Chain_NearestLocation, [_missionPosition, 10000, ["NameVillage","NameCity","NameCityCapital"]]],
			[SPM_Chain_PositionToIsolatedPosition, [_blacklist]]
		];
	private _complete = [_data, _chain] call SPM_Chain_Execute;
	private _fleeDestination = [_data, "position"] call SPM_Util_GetDataValue;

	private _positions = [_fleeDestination, 100, 10] call SPM_Util_SampleAreaPerimeter;

	[_positions, ["#GdtWater"]] call SPM_Util_ExcludeSamplesBySurfaceType;
	[_positions, 20, 90] call SPM_Util_ExcludeSamplesBySurfaceIncline;
	[_positions, 6.0, ["FENCE", "WALL", "BUILDING", "HOUSE", "ROCK", "TREE"]] call SPM_Util_ExcludeSamplesByProximity;

	if (count _positions > 0) then { _fleeDestination = selectRandom _positions };

	//BUG: It's possible to have a group signal successfully on one check, but not another.  This can cause missions
	// like this with multiple "flee" groups to have one group flee but not another.  There's no way to signal "all clear"
	// which could permit the original fleeing group to return.  Nor is there a means to ensure that all fleeing groups
	// are signalled.

	private _groupHasSignalled =
	{
		params ["_category", "_group"];

		if (not alive leader _group) exitWith { false };

		private _detectedThreat = (behaviour leader _group == "combat" && { { alive _x } count (leader _group targets [true, 400]) > 0 });

		_detectedThreat
	};

	private _getFleeDestination =
	{
		params ["_category", "_group"];

		["FleeDestination"] call OO_METHOD(_category,Category,GetTagValue)
	};

	_category = [_guards, _eastParticipants] call OO_CREATE(FleeWhenSignalledCategory);
	["Name", "EastFlee"] call OO_METHOD(_category,Category,SetTagValue);
	["FleeDestination", _fleeDestination] call OO_METHOD(_category,Category,SetTagValue);
	OO_SET(_category,FleeWhenSignalledCategory,GroupHasSignalled,_groupHasSignalled);
	OO_SET(_category,FleeWhenSignalledCategory,GetFleeDestination,_getFleeDestination);
	_categories pushBack _category;

	_category = [_guards, _syndikatParticipants] call OO_CREATE(FleeWhenSignalledCategory);
	["Name", "SydikatFlee"] call OO_METHOD(_category,Category,SetTagValue);
	["FleeDestination", _fleeDestination] call OO_METHOD(_category,Category,SetTagValue);
	OO_SET(_category,FleeWhenSignalledCategory,GroupHasSignalled,_groupHasSignalled);
	OO_SET(_category,FleeWhenSignalledCategory,GetFleeDestination,_getFleeDestination);
	_categories pushBack _category;


	// Civilians
	if (_civilianCount > 0) then
	{
		private _occupationLimits = [1,1];
		_area = [_missionPosition, _guardRadius + 25, (_guardRadius + 200) min _missionRadius] call OO_CREATE(StrongpointArea);
		_category = [_area] call OO_CREATE(InfantryGarrisonCategory);
		["Name", "Civilians"] call OO_METHOD(_category,Category,SetTagValue);
		OO_SET(_category,ForceCategory,RatingsWest,SPM_InfantryGarrison_RatingsWest);
		OO_SET(_category,ForceCategory,SideEast,civilian);
		OO_SET(_category,ForceCategory,RatingsEast,SPM_InfantryGarrison_RatingsCivilian);
		OO_SET(_category,ForceCategory,CallupsEast,SPM_InfantryGarrison_CallupsCivilian);
		OO_SET(_category,InfantryGarrisonCategory,InitialCallupsEast,SPM_InfantryGarrison_CallupsCivilian);
		OO_SET(_category,InfantryGarrisonCategory,InitialReserves,_civilianCount);
		OO_SET(_category,InfantryGarrisonCategory,OccupationLimits,_occupationLimits);
		OO_SET(_category,InfantryGarrisonCategory,HouseOutdoors,false);
		OO_SET(_category,InfantryGarrisonCategory,RelocateProbability,SPM_Util_CivilianRelocateProbabilityByTimeOfDay);
		_categories pushBack _category;

		// Civilian Vehicles
		_category = [_area] call OO_CREATE(CivilianVehiclesCategory);
		["Name", "CivilianVehicles"] call OO_METHOD(_category,Category,SetTagValue);
		_categories pushBack _category;
	};

	// Armor
	_area = [_missionPosition, _meetingRadius, _guardRadius] call OO_CREATE(StrongpointArea);
	_category = [_area] call OO_CREATE(ArmorCategory);
	["Name", "PatrolVehicles"] call OO_METHOD(_category,Category,SetTagValue);
	OO_SET(_category,ForceCategory,RatingsWest,SPM_Armor_RatingsWestAPCs+SPM_Armor_RatingsWestTanks);
	OO_SET(_category,ForceCategory,RatingsEast,SPM_MissionRaidTown_Armor_RatingsEast);
	OO_SET(_category,ForceCategory,CallupsEast,SPM_MissionRaidTown_Armor_CallupsEast);

	private _qilinRating = 0; { if (_x select 0 == "LOP_US_UAZ_DshKM") exitWith { _qilinRating = (_x select 1 select 0) * (_x select 1 select 1) } } forEach SPM_MissionRaidTown_Armor_RatingsEast;

	private _armorReserves = _qilinRating;
	OO_SET(_category,ForceCategory,Reserves,_armorReserves);

	private _minimumWestForce = [_armorReserves, _qilinRating] call SPM_ForceRating_CreateForce;
	OO_SET(_category,ForceCategory,InitialMinimumWestForce,_minimumWestForce);

	_categories pushBack _category;

	private _armor = _category;

	{
		[_x] call OO_METHOD(_mission,Strongpoint,AddCategory);
	} forEach _categories;



	// Mission objective is structured as two compound objectives, either of which may be completed.  Each compound is a capture/debrief pair.

	private _eastAppearances = ["LOP_US_Infantry_Officer", "LOP_US_Infantry_TL", "LOP_US_Infantry_SL"];
	private _syndikatAppearances = ["I_officer_F", "I_C_Soldier_Para_8_F", "I_C_Soldier_Para_2_F", "I_C_Soldier_Bandit_6_F", "C_Man_Messenger_01_F"];

	private _eastAppearance = selectRandom _eastAppearances;
	private _syndikatAppearance = selectRandom _syndikatAppearances;

	private _eastUnitDescription = [_eastAppearance] call SPM_ProvideGarrisonUnit_MemberDescription;
	private _syndikatUnitDescription = [_syndikatAppearance] call SPM_ProvideGarrisonUnit_MemberDescription;

	// Three tiers of objectives.  There's a top-level "any" objective that completes if either east or syndikat objective completes.  Then the two mid-tier objectives for the two factions that require success by both of their third-tier objectives to capture and debrief the target soldier.

	private _description = [format ["Disrupt meeting between %1 and %2, capture either of the participants, and debrief them at SpecOps headquarters", _eastUnitDescription, _syndikatUnitDescription], ""];
	private _compoundObjective = [_description] call OO_CREATE(ObjectiveCompoundAny);
	[_compoundObjective] call OO_METHOD(_mission,Mission,AddObjective);

	private _debriefingArea = [0, getPos SpecOpsHQ] + triggerArea SpecOpsHQ;


	private _specopsTest = { [player] call BOTH_IsSpecOpsMember };

	// Capture east officer.  A compound objective to capture/debrief the csat member.
	private _eastObjective = [["",""]] call OO_CREATE(ObjectiveCompound);
	[_eastObjective] call OO_METHOD(_compoundObjective,ObjectiveCompound,AddObjective);
	[_eastObjective] call OO_METHOD(_mission,Mission,AddObjective);

	_category = [_eastParticipants, ["garrisoned-housed", "garrisoned-outdoor"], nil, _eastAppearance, east, nil, "CSAT REPRESENTATIVE"] call OO_CREATE(ProvideGarrisonUnit);
	[_category] call OO_METHOD(_mission,Strongpoint,AddCategory);

	private _unitProvider = _category;

	private _objective = [_unitProvider] call OO_CREATE(ObjectiveCaptureMan);
	OO_SET(_objective,ObjectiveCaptureMan,ClientActionTest,_specopsTest);
	[_objective] call OO_METHOD(_eastObjective,ObjectiveCompound,AddObjective);
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);

	private _objective = [_unitProvider, _debriefingArea, "SpecOps headquarters"] call OO_CREATE(ObjectiveDebriefMan);
	OO_SET(_objective,ObjectiveDebriefMan,ClientActionTest,_specopsTest);
	[_objective] call OO_METHOD(_eastObjective,ObjectiveCompound,AddObjective);
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);



	// Capture syndikat leader.  A compound objective to capture/debrief the syndikate member
	private _syndikatObjective = [["",""]] call OO_CREATE(ObjectiveCompound);
	[_syndikatObjective] call OO_METHOD(_compoundObjective,ObjectiveCompound,AddObjective);
	[_syndikatObjective] call OO_METHOD(_mission,Mission,AddObjective);

	_category = [_syndikatParticipants,["garrisoned-housed", "garrisoned-outdoor"], nil, _syndikatAppearance, independent, nil, "SYNDIKAT REPRESENTATIVE"] call OO_CREATE(ProvideGarrisonUnit);
	[_category] call OO_METHOD(_mission,Strongpoint,AddCategory);

	private _unitProvider = _category;

	private _objective = [_unitProvider] call OO_CREATE(ObjectiveCaptureMan);
	OO_SET(_objective,ObjectiveCaptureMan,ClientActionTest,_specopsTest);
	[_objective] call OO_METHOD(_syndikatObjective,ObjectiveCompound,AddObjective);
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);

	private _objective = [_unitProvider, _debriefingArea, "SpecOps headquarters"] call OO_CREATE(ObjectiveDebriefMan);
	OO_SET(_objective,ObjectiveDebriefMan,ClientActionTest,_specopsTest);
	[_objective] call OO_METHOD(_syndikatObjective,ObjectiveCompound,AddObjective);
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);
};

OO_TRACE_DECL(SPM_MissionDisruptMeeting_Delete) =
{
	params ["_mission"];

	[] call OO_METHOD_PARENT(_mission,Root,Delete,Mission);
};

OO_BEGIN_SUBCLASS(MissionDisruptMeeting,MissionSpecialOperations);
	OO_OVERRIDE_METHOD(MissionDisruptMeeting,Root,Create,SPM_MissionDisruptMeeting_Create);
	OO_OVERRIDE_METHOD(MissionDisruptMeeting,Root,Delete,SPM_MissionDisruptMeeting_Delete);
	OO_OVERRIDE_METHOD(MissionDisruptMeeting,Strongpoint,Update,SPM_MissionDisruptMeeting_Update);
	OO_OVERRIDE_METHOD(MissionDisruptMeeting,MissionSpecialOperations,GetMissionDescription,SPM_MissionDisruptMeeting_GetMissionDescription);
OO_END_SUBCLASS(MissionDisruptMeeting);
