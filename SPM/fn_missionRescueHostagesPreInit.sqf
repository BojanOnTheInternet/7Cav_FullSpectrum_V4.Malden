/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_MissionRescueHostages_GetMissionDescription) =
{
	params ["_mission"];

	private _objectiveDescriptions = [];
	{
		_objectiveDescriptions pushBack (_x select 2 select 0);
	} forEach OO_GET(_mission,Mission,NotificationsAccumulator);

	private _positionDescription = [OO_GET(_mission,Strongpoint,Position)] call SPM_Util_PositionDescription;

	["Mission Orders"] + _objectiveDescriptions + ["Hostage site: " + _positionDescription]
};

OO_TRACE_DECL(SPM_MissionRescueHostages_Update) =
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

SPM_MissionRescueHostages_Armor_CallupsSyndikat =
[
	["I_C_Offroad_02_LMG_F", [10, 2, 1.0, {}]]
];
SPM_MissionRescueHostages_Armor_RatingsSyndikat = SPM_MissionRescueHostages_Armor_CallupsSyndikat apply { [_x select 0, (_x select 1) select [0, 2]] };

SPM_MissionRescueHostages_Transport_CallupsSyndikat =
[
	["C_Van_01_transport_F", [1, 3, 1.0, {}]]
];

OO_TRACE_DECL(SPM_MissionRescueHostages_Create) =
{
	params ["_mission", "_missionPosition", "_hostageRadius", "_hostageClasses", "_syndikatRadius", "_syndikatCount"];

	[_missionPosition, _syndikatRadius + 100, _syndikatRadius + 200, 2] call OO_METHOD_PARENT(_mission,Root,Create,Mission);

	OO_SET(_mission,Strongpoint,Name,"Special Operation");
	OO_SET(_mission,Strongpoint,InitializeObject,SERVER_InitializeCategoryObject);

	OO_SET(_mission,Mission,ParticipantFilter,BOTH_IsSpecOpsMember);

	private _category = OO_NULL;
	private _categories = [];

	// Transport to truck in a squad of guys
	_category = [] call OO_CREATE(TransportCategory);
	["Name", "Transport"] call OO_METHOD(_category,Category,SetTagValue);
	OO_SET(_category,ForceCategory,SideEast,independent);
	OO_SET(_category,TransportCategory,GroundTransports,SPM_MissionRescueHostages_Transport_CallupsSyndikat);
	OO_SET(_category,TransportCategory,AirTransports,[]);
	OO_SET(_category,TransportCategory,SeaTransports,[]);
	_categories pushBack _category;

	private _transport = _category;

	// Garrison
	_area = [_missionPosition, 0, _syndikatRadius] call OO_CREATE(StrongpointArea);
	_category = [_area] call OO_CREATE(InfantryGarrisonCategory);
	["Name", "Garrison"] call OO_METHOD(_category,Category,SetTagValue);
	OO_SET(_category,ForceCategory,RatingsWest,SPM_InfantryGarrison_RatingsWest);
	OO_SET(_category,ForceCategory,SideEast,independent);
	OO_SET(_category,ForceCategory,SkillLevel,0.35);
	OO_SET(_category,ForceCategory,RatingsEast,SPM_InfantryGarrison_RatingsSyndikat);
	OO_SET(_category,ForceCategory,CallupsEast,SPM_InfantryGarrison_CallupsSyndikat);
	OO_SET(_category,InfantryGarrisonCategory,InitialCallupsEast,SPM_InfantryGarrison_InitialCallupsSyndikat);
	OO_SET(_category,InfantryGarrisonCategory,Transport,_transport);

	private _garrisonRatingEast = 0;
	{ _garrisonRatingEast = _garrisonRatingEast + (_x select 1 select 0) } forEach OO_GET(_category,ForceCategory,RatingsEast);
	_garrisonRatingEast = _garrisonRatingEast / count OO_GET(_category,ForceCategory,RatingsEast);

	private _syndikatReserves = _syndikatCount * _garrisonRatingEast;
	private _syndikatInitialCount = _syndikatCount - 8; // Leave out a squad that arrives by vehicle
	private _syndikatInitialReserves = _syndikatInitialCount * _garrisonRatingEast;

	OO_SET(_category,InfantryGarrisonCategory,InitialReserves,_syndikatInitialReserves);
	OO_SET(_category,ForceCategory,Reserves,_syndikatReserves);

	private _garrisonRatingWest = 0;
	{ _garrisonRatingWest = _garrisonRatingWest + (_x select 1 select 0) } forEach OO_GET(_category,ForceCategory,RatingsWest);
	_garrisonRatingWest = _garrisonRatingWest / count OO_GET(_category,ForceCategory,RatingsWest);

	// Send in reinforcements as soon as anyone goes down.
	private _minimumWestForce = [(_syndikatInitialCount - 1) * _garrisonRatingEast, _garrisonRatingWest] call SPM_ForceRating_CreateForce;
	OO_SET(_category,ForceCategory,MinimumWestForce,_minimumWestForce);

	_categories pushBack _category;

	private _infantry = _category;

	// Infantry Patrols
	_area = [_missionPosition, _syndikatRadius, _syndikatRadius + 50] call OO_CREATE(StrongpointArea);
	_category = [_area, _infantry] call OO_CREATE(PerimeterPatrolCategory);
	["Name", "InnerPerimeterPatrol"] call OO_METHOD(_category,Category,SetTagValue);
	_categories pushBack _category;

	[4, true, 50, 1, 0.2, 0.0] call OO_METHOD(_category,InfantryPatrolCategory,AddPatrol);
	[4, false, 50, 1, 0.2, 0.0] call OO_METHOD(_category,InfantryPatrolCategory,AddPatrol);

	_area = [_missionPosition, _syndikatRadius + 50, _syndikatRadius + 100] call OO_CREATE(StrongpointArea);
	_category = [_area, _infantry] call OO_CREATE(PerimeterPatrolCategory);
	["Name", "OuterPerimeterPatrol"] call OO_METHOD(_category,Category,SetTagValue);
	_categories pushBack _category;

	[4, true, 50, 1, 0.5, 0.0] call OO_METHOD(_category,InfantryPatrolCategory,AddPatrol);
	[4, false, 50, 1, 0.5, 0.0] call OO_METHOD(_category,InfantryPatrolCategory,AddPatrol);

	// Armor
	_area = [_missionPosition, _syndikatRadius, _syndikatRadius + 100] call OO_CREATE(StrongpointArea);
	_category = [_area] call OO_CREATE(ArmorCategory);
	["Name", "PatrolVehicles"] call OO_METHOD(_category,Category,SetTagValue);
	OO_SET(_category,ForceCategory,RatingsWest,SPM_Armor_RatingsWestAPCs+SPM_Armor_RatingsWestTanks);
	OO_SET(_category,ForceCategory,SideEast,independent);
	OO_SET(_category,ForceCategory,RatingsEast,SPM_MissionRescueHostages_Armor_RatingsSyndikat);
	OO_SET(_category,ForceCategory,CallupsEast,SPM_MissionRescueHostages_Armor_CallupsSyndikat);

	private _offroadRating = 0; { if (_x select 0 == "LOP_US_UAZ_DshKM") exitWith { _offroadRating = (_x select 1 select 0) * (_x select 1 select 1) } } forEach SPM_MissionRescueHostages_Armor_RatingsSyndikat;

	private _armorReserves = _offroadRating * 2;
	OO_SET(_category,ForceCategory,Reserves,_armorReserves);

	private _minimumWestForce = [_armorReserves, _offroadRating] call SPM_ForceRating_CreateForce;
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

OO_TRACE_DECL(SPM_MissionRescueHostages_Delete) =
{
	params ["_mission"];

	[] call OO_METHOD_PARENT(_mission,Root,Delete,Mission);
};

OO_BEGIN_SUBCLASS(MissionRescueHostages,MissionSpecialOperations);
	OO_OVERRIDE_METHOD(MissionRescueHostages,Root,Create,SPM_MissionRescueHostages_Create);
	OO_OVERRIDE_METHOD(MissionRescueHostages,Root,Delete,SPM_MissionRescueHostages_Delete);
	OO_OVERRIDE_METHOD(MissionRescueHostages,Strongpoint,Update,SPM_MissionRescueHostages_Update);
	OO_OVERRIDE_METHOD(MissionRescueHostages,MissionSpecialOperations,GetMissionDescription,SPM_MissionRescueHostages_GetMissionDescription);
OO_END_SUBCLASS(MissionRescueHostages);
