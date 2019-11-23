/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_MissionRaidTown_Update) =
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

SPM_Util_CivilianRelocateProbabilityByTimeOfDay =
{
	private _high = 0.010;
	private _medium = 0.005;
	private _low = 0.0001;

	private _map =
	[
		[0.0, _low],
		[6.5, _low],
		[9.0, _high],
		[12.0, _medium],
		[17.0, _high],
		[20.0, _medium],
		[22.0, _low],
		[24.0, _low]
	];

	[dayTime, _map] call SPM_Util_MapValueRange;
};

SPM_MissionRaidTown_Armor_CallupsEast =
[
	["LOP_US_UAZ_DshKM",
		[10, 2, 1.0, {}]],
	["LOP_US_UAZ_AGS",
		[20, 3, 1.0,{}]]
];

SPM_MissionRaidTown_Armor_RatingsEast = SPM_MissionRaidTown_Armor_CallupsEast apply { [_x select 0, (_x select 1) select [0, 2]] };

OO_TRACE_DECL(SPM_MissionRaidTown_Create) =
{
	params ["_mission", "_missionPosition", "_garrisonRadius", "_garrisonCount"];

	private _civilianInnerRadius = _garrisonRadius + 75;
	private _civilianOuterRadius = _garrisonRadius + 350;

	[_missionPosition, _garrisonRadius + 100, _garrisonRadius + 450, 2] call OO_METHOD_PARENT(_mission,Root,Create,Mission);

	OO_SET(_mission,Strongpoint,Name,"Special Operation");
	OO_SET(_mission,Strongpoint,InitializeObject,SERVER_InitializeCategoryObject);

	OO_SET(_mission,Mission,ParticipantFilter,BOTH_IsSpecOpsMember);

	private _category = OO_NULL;
	private _categories = [];

	// Air defense
	_area = [_missionPosition, 0, OO_GET(_mission,Strongpoint,ActivityRadius)] call OO_CREATE(StrongpointArea);
	_category = [_area] call OO_CREATE(AirDefenseCategory);
	OO_SET(_category,ForceCategory,RatingsWest,SPM_AirDefense_RatingsWest);
	OO_SET(_category,ForceCategory,RatingsEast,SPM_AirDefense_RatingsEast);
	OO_SET(_category,ForceCategory,CallupsEast,SPM_AirDefense_CallupsEast);
	_categories pushBack _category;

	// Transport
	_category = [] call OO_CREATE(TransportCategory);
	OO_SET(_category,TransportCategory,SeaTransports,SPM_Transport_CallupsEastSpeedboat);
	OO_SET(_category,TransportCategory,GroundTransports,SPM_Transport_CallupsEastMarid);
	OO_SET(_category,TransportCategory,AirTransports,SPM_Transport_CallupsEastMohawk);
	_categories pushBack _category;

	// Garrison
	_area = [_missionPosition, 0, _garrisonRadius] call OO_CREATE(StrongpointArea);
	_category = [_area] call OO_CREATE(InfantryGarrisonCategory);
	["Name", "Garrison"] call OO_METHOD(_category,Category,SetTagValue);
	OO_SET(_category,ForceCategory,RatingsWest,SPM_InfantryGarrison_RatingsWest);
	OO_SET(_category,ForceCategory,RatingsEast,SPM_InfantryGarrison_RatingsEast);
	OO_SET(_category,ForceCategory,CallupsEast,SPM_InfantryGarrison_CallupsEast);

	private _garrisonRatingEast = 0;
	{ _garrisonRatingEast = _garrisonRatingEast + (_x select 1 select 0) } forEach OO_GET(_category,ForceCategory,RatingsEast);
	_garrisonRatingEast = _garrisonRatingEast / count OO_GET(_category,ForceCategory,RatingsEast);

	private _garrisonReserves = _garrisonCount * _garrisonRatingEast;

	OO_SET(_category,InfantryGarrisonCategory,InitialReserves,_garrisonReserves*0.8);
	OO_SET(_category,ForceCategory,Reserves,_garrisonReserves);

	private _garrisonRatingWest = 0;
	{ _garrisonRatingWest = _garrisonRatingWest + (_x select 1 select 0) } forEach OO_GET(_category,ForceCategory,RatingsWest);
	_garrisonRatingWest = _garrisonRatingWest / count OO_GET(_category,ForceCategory,RatingsWest);

	private _minimumWestForce = [_garrisonReserves * 0.5, _garrisonRatingWest] call SPM_ForceRating_CreateForce;
	OO_SET(_category,ForceCategory,MinimumWestForce,_minimumWestForce);

	_categories pushBack _category;

	private _infantry = _category;

	// Infantry Patrols
	_area = [_missionPosition, _garrisonRadius, _garrisonRadius + 50] call OO_CREATE(StrongpointArea);
	_category = [_area, _infantry] call OO_CREATE(PerimeterPatrolCategory);
	["Name", "InnerPerimeterPatrol"] call OO_METHOD(_category,Category,SetTagValue);
	_categories pushBack _category;

	[4, true, 50, 1, 0.2, 0.0] call OO_METHOD(_category,InfantryPatrolCategory,AddPatrol);
	[4, true, 50, 1, 0.2, 0.0] call OO_METHOD(_category,InfantryPatrolCategory,AddPatrol);
	[4, false, 50, 1, 0.2, 0.0] call OO_METHOD(_category,InfantryPatrolCategory,AddPatrol);
	[4, false, 50, 1, 0.2, 0.0] call OO_METHOD(_category,InfantryPatrolCategory,AddPatrol);

	_area = [_missionPosition, _garrisonRadius + 50, _garrisonRadius + 100] call OO_CREATE(StrongpointArea);
	_category = [_area, _infantry] call OO_CREATE(PerimeterPatrolCategory);
	["Name", "OuterPerimeterPatrol"] call OO_METHOD(_category,Category,SetTagValue);
	_categories pushBack _category;

	[2, true, 50, 1, 0.5, 0.0] call OO_METHOD(_category,InfantryPatrolCategory,AddPatrol);
	[2, true, 50, 1, 0.5, 0.0] call OO_METHOD(_category,InfantryPatrolCategory,AddPatrol);
	[2, false, 50, 1, 0.5, 0.0] call OO_METHOD(_category,InfantryPatrolCategory,AddPatrol);

	private _preferredBuildingTypes = ["Structures_Village", "Structures_Town"];

	private _buildings = [] call OO_METHOD(_mission,Mission,GetBuildings);
	private _civilianBuildings = _buildings select { (getPos _x) distance _missionPosition > _civilianInnerRadius };
	_civilianBuildings = _civilianBuildings select { getText (configFile >> "CfgVehicles" >> typeOf _x >> "vehicleClass") in _preferredBuildingTypes };

	if (count _civilianBuildings > 5) then
	{
		private _civilians = (count _civilianBuildings * 0.7) min 40; // Leave at least 30% of the buildings empty

		// Civilians
		private _occupationLimits = [1,1];
		_area = [_missionPosition, _civilianInnerRadius, _civilianOuterRadius] call OO_CREATE(StrongpointArea);
		_category = [_area] call OO_CREATE(InfantryGarrisonCategory);
		["Name", "Civilians"] call OO_METHOD(_category,Category,SetTagValue);
		OO_SET(_category,ForceCategory,RatingsWest,SPM_InfantryGarrison_RatingsWest);
		OO_SET(_category,ForceCategory,SideEast,civilian);
		OO_SET(_category,ForceCategory,RatingsEast,SPM_InfantryGarrison_RatingsCivilian);
		OO_SET(_category,ForceCategory,CallupsEast,SPM_InfantryGarrison_CallupsCivilian);
		OO_SET(_category,InfantryGarrisonCategory,InitialCallupsEast,SPM_InfantryGarrison_CallupsCivilian);
		OO_SET(_category,InfantryGarrisonCategory,InitialReserves,_civilians);
		OO_SET(_category,InfantryGarrisonCategory,PlanCallupsEast,SPM_InfantryGarrison_CallupsCivilian);
		OO_SET(_category,InfantryGarrisonCategory,PlanReserves,count _civilianBuildings);
		OO_SET(_category,InfantryGarrisonCategory,OccupationLimits,_occupationLimits);
		OO_SET(_category,InfantryGarrisonCategory,HousingPreferences,_preferredBuildingTypes);
		OO_SET(_category,InfantryGarrisonCategory,HouseOutdoors,false);
		OO_SET(_category,InfantryGarrisonCategory,RelocateProbability,SPM_Util_CivilianRelocateProbabilityByTimeOfDay);
		_categories pushBack _category;

		// Civilian Vehicles
		_category = [_area] call OO_CREATE(CivilianVehiclesCategory);
		["Name", "CivilianVehicles"] call OO_METHOD(_category,Category,SetTagValue);
		_categories pushBack _category;

		private _syndikat = floor random (_civilians * 0.1);
		if (_syndikat > 0) then
		{
			_category = [_area] call OO_CREATE(InfantryGarrisonCategory);
			["Name", "Guerillas"] call OO_METHOD(_category,Category,SetTagValue);
			OO_SET(_category,ForceCategory,RatingsWest,SPM_InfantryGarrison_RatingsWest);
			OO_SET(_category,ForceCategory,SideEast,independent);
			OO_SET(_category,ForceCategory,RatingsEast,SPM_InfantryGarrison_RatingsSyndikat);
			OO_SET(_category,ForceCategory,CallupsEast,SPM_InfantryGarrison_CallupsSyndikat);
			OO_SET(_category,ForceCategory,SkillLevel,0.35);
			OO_SET(_category,InfantryGarrisonCategory,InitialCallupsEast,SPM_InfantryGarrison_InitialCallupsSyndikat);
			OO_SET(_category,InfantryGarrisonCategory,InitialReserves,_syndikat);
			_categories pushBack _category;
		};
	};

	// Armor
	_area = [_missionPosition, _garrisonRadius + 100, _garrisonRadius + 350] call OO_CREATE(StrongpointArea);
	_category = [_area] call OO_CREATE(ArmorCategory);
	["Name", "PatrolVehicles"] call OO_METHOD(_category,Category,SetTagValue);
	OO_SET(_category,ForceCategory,RatingsWest,SPM_Armor_RatingsWestAPCs+SPM_Armor_RatingsWestTanks);
	OO_SET(_category,ForceCategory,RatingsEast,SPM_MissionRaidTown_Armor_RatingsEast);
	OO_SET(_category,ForceCategory,CallupsEast,SPM_MissionRaidTown_Armor_CallupsEast);

	private _qilinRating = 0; { if (_x select 0 == "LOP_US_UAZ_DshKM") exitWith { _qilinRating = (_x select 1 select 0) * (_x select 1 select 1) } } forEach SPM_MissionRaidTown_Armor_RatingsEast;
	private _maridRating = 0; { if (_x select 0 == "LOP_US_UAZ_AGS") exitWith { _maridRating = (_x select 1 select 0) * (_x select 1 select 1) } } forEach SPM_MissionRaidTown_Armor_RatingsEast;

	private _armorReserves = _qilinRating + random [0, _maridRating * 2, 0]; // At least a Qilin, then geometrically-diminishing chances of tougher vehicles, up to 2 Marids
	OO_SET(_category,ForceCategory,Reserves,_armorReserves);

	private _minimumWestForce = [_armorReserves, _qilinRating] call SPM_ForceRating_CreateForce;
	OO_SET(_category,ForceCategory,InitialMinimumWestForce,_minimumWestForce);

	_categories pushBack _category;

	private _armor = _category;

	// Possibility of making an armor unit idle and available to players to steal
	if (random 1 < 0.25) then
	{
		_category = [_armor, 1] call OO_CREATE(ArmorIdleCategory);

		_categories pushBack _category;
	};

	{
		[_x] call OO_METHOD(_mission,Strongpoint,AddCategory);
	} forEach _categories;
};

OO_TRACE_DECL(SPM_MissionRaidTown_Delete) =
{
	params ["_mission"];

	[] call OO_METHOD_PARENT(_mission,Root,Delete,Mission);
};

OO_BEGIN_SUBCLASS(MissionRaidTown,MissionSpecialOperations);
	OO_OVERRIDE_METHOD(MissionRaidTown,Root,Create,SPM_MissionRaidTown_Create);
	OO_OVERRIDE_METHOD(MissionRaidTown,Root,Delete,SPM_MissionRaidTown_Delete);
	OO_OVERRIDE_METHOD(MissionRaidTown,Strongpoint,Update,SPM_MissionRaidTown_Update);
OO_END_SUBCLASS(MissionRaidTown);
