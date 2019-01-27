/*
Copyright (c) 2017, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_ForceRating_CreateForce) =
{
	params ["_totalRating", "_unitRating"];

	if (_unitRating == 0) exitWith { [] };

	private _forceRating = 0;
	private _force = [];
	while { _forceRating < _totalRating } do
	{
		_force pushBack ([objNull, _unitRating] call OO_CREATE(ForceRating));
		_forceRating = _forceRating + _unitRating;
	};

	_force
};

OO_TRACE_DECL(SPM_ForceRating_Create) =
{
	params ["_forceRating", "_vehicle", "_rating"];

	OO_SET(_forceRating,ForceRating,Vehicle,_vehicle);
	OO_SET(_forceRating,ForceRating,Rating,_rating);
};

OO_BEGIN_STRUCT(ForceRating);
	OO_OVERRIDE_METHOD(ForceRating,RootStruct,Create,SPM_ForceRating_Create);
	OO_DEFINE_PROPERTY(ForceRating,Vehicle,"OBJECT",objNull);
	OO_DEFINE_PROPERTY(ForceRating,Rating,"SCALAR",0);
OO_END_STRUCT(ForceRating);

OO_TRACE_DECL(SPM_ForceUnit_GetGroups) =
{
	params ["_forceUnit"];

	private _groups = [];
	{
		if (alive _x) then { _groups pushBackUnique group _x };
	} forEach OO_GET(_forceUnit,ForceUnit,Units);

	_groups
};

OO_TRACE_DECL(SPM_ForceUnit_Create) =
{
	params ["_forceUnit", "_vehicle", "_units"];

	OO_SET(_forceUnit,ForceUnit,Vehicle,_vehicle);
	OO_SET(_forceUnit,ForceUnit,Units,_units);
};

OO_BEGIN_STRUCT(ForceUnit);
	OO_OVERRIDE_METHOD(ForceUnit,RootStruct,Create,SPM_ForceUnit_Create);
	OO_DEFINE_METHOD(ForceUnit,GetGroups,SPM_ForceUnit_GetGroups);
	OO_DEFINE_PROPERTY(ForceUnit,Vehicle,"OBJECT",objNull);
	OO_DEFINE_PROPERTY(ForceUnit,Units,"ARRAY",[]);
OO_END_STRUCT(ForceUnit);

// Ratings are case-sensitive on vehicle types
OO_TRACE_DECL(SPM_Force_GetForceRatings) =
{
	params ["_units", "_unitTypeRatings"];

	private _vehicles = [];
	{
		private _vehicle = vehicle _x;
		if (_x in [driver _vehicle, gunner _vehicle, commander _vehicle] && { not (_vehicle isKindOf "ParachuteBase") } && { not (_vehicle isKindOf "StaticWeapon") } ) then
		{
			_vehicles pushBackUnique _vehicle;
		}
		else
		{
			_vehicles pushBackUnique _x;
		};
	} forEach _units;

	private _force = [];
	private _rating = 0;
	private _ratingMultiplier = 0;
	private _vehicleType = "";
	private _unitTypeIndex = -1;
	private _unitTypeRating = [];
	{
		_vehicleType = typeOf _x;
		_unitTypeIndex = _unitTypeRatings findIf { _x select 0 == _vehicleType };

		if (_unitTypeIndex >= 0) then
		{
			_unitTypeRating = _unitTypeRatings select _unitTypeIndex select 1;

			_rating = 0;

			if (canFire _x) then
			{
				_ratingMultiplier = 0;

				switch (true) do
				{
					case (_x isKindOf "Man"):
					{
						if (lifeState _x in ["HEALTHY", "INJURED"]) then { _ratingMultiplier = 1.0 };
					};

					case (_x isKindOf "Plane" && { isTouchingGround _x }):
					{
					};

					case (_x isKindOf "Helicopter" && { not isEngineOn _x }):
					{
					};

					default
					{
						_ratingMultiplier = _unitTypeRating select 1; // Always rate as if fully crewed
						//_ratingMultiplier = { lifeState _x in ["HEALTHY", "INJURED"] } count [driver _x, gunner _x, commander _x];
					};
				};

//				if (not canMove _x) then { _ratingMultiplier = _ratingMultiplier * 0.5 };

				_rating = (_unitTypeRating select 0) * _ratingMultiplier;
			};

			if (_rating > 0) then { _force pushBack ([_x, _rating] call OO_CREATE(ForceRating)) };

			if (not (_x isKindOf "Man")) then { [_x, "ForceRating", format ["R%1", _rating]] call TRACE_SetObjectString };
		};
	} forEach _vehicles;

	_force
};

// Rebalance east versus west.  If a side is going to be left with an advantage, it will always be west.
OO_TRACE_DECL(SPM_Force_Rebalance) =
{
	params ["_category", "_westForce", "_eastForce"];

	// West

	private _westRating = 0;
	{ _westRating = _westRating + OO_GET(_x,ForceRating,Rating) } forEach _westForce;

	private _minimumWestForce = if (OO_GET(_category,ForceCategory,_FirstRebalance)) then { OO_GET(_category,ForceCategory,InitialMinimumWestForce) } else { OO_GET(_category,ForceCategory,MinimumWestForce) };

	private _minimumWestRating = 0;
	{ _minimumWestRating = _minimumWestRating + OO_GET(_x,ForceRating,Rating) } forEach _minimumWestForce;

	{
		if (_westRating >= _minimumWestRating) exitWith {};

		_westForce pushBack _x;
		_westRating = _westRating + OO_GET(_x,ForceRating,Rating);
	} forEach _minimumWestForce;

	private _westRatingAverage = if (count _westForce == 0) then { 0 } else { _westRating / count _westForce };

	// East

	private _eastCallups = OO_GET(_category,ForceCategory,CallupsEast);
	private _eastForceReserves = OO_GET(_category,ForceCategory,Reserves);
	private _difficulty = OO_GET(_category,ForceCategory,DifficultyLevel);

	private _changes = [[], [], [], _eastForceReserves];

	private _eastUnitsActiveForce = [];
	private _eastUnitsRetiringForce = [];
	{
		private _retiring = ((group driver OO_GET(_x,ForceRating,Vehicle)) getVariable "SPM_Force_Retiring");
		if (isNil "_retiring") then { _eastUnitsActiveForce pushBack _x } else { _eastUnitsRetiringForce pushBack _x };
	} forEach _eastForce;

	private _eastRating = 0;
	{ _eastRating = _eastRating + OO_GET(_x,ForceRating,Rating) } forEach _eastUnitsActiveForce;

	private _forceAdvantageWest = (_westRating * _difficulty) - _eastRating;

	// Reinstate

	_eastUnitsRetiringForce = _eastUnitsRetiringForce select { OO_GET(_x,ForceRating,Vehicle) getVariable ["SPM_Force_AllowReinstate", true] };

	while { _forceAdvantageWest > 0 } do
	{
//		diag_log format ["Rebalance: Reinstate: FAW: %1", _forceAdvantageWest];

		private _ratingLimit = _forceAdvantageWest;

		private _idealRating = _westRatingAverage min _forceAdvantageWest;
		private _idealRatingHalf = _idealRating * 0.5;
		private _idealRatingDouble = _idealRating * 2.0;

		private _closestMatch = [-1, 1e30];
		{
			private _unitRating = OO_GET(_x,ForceRating,Rating);
			private _difference = abs (_idealRating - _unitRating);
//			diag_log format ["Rebalance: Reinstate: ideal rating: %1, unit rating: %2, unit: %3", _idealRating, _unitRating, OO_GET(_x,ForceRating,Vehicle)];
			if (_difference < (_closestMatch select 1) && { _unitRating >= _idealRatingHalf && _unitRating <= _idealRatingDouble } && { OO_GET(_x,ForceRating,Rating) < _ratingLimit }) then
			{
				_closestMatch = [_forEachIndex, _difference];
			}
		} forEach _eastUnitsRetiringForce;

		if (_closestMatch select 0 == -1) exitWith {};

		private _retiredUnit = _eastUnitsRetiringForce deleteAt (_closestMatch select 0);

		CHANGES(_changes,reinstate) pushBack OO_GET(_retiredUnit,ForceRating,Vehicle);

		_forceAdvantageWest = (_forceAdvantageWest - OO_GET(_retiredUnit,ForceRating,Rating)) max 0;
//		diag_log format ["Rebalance: Reinstate: FAW: %1, Unit: %2", _forceAdvantageWest, OO_GET(_retiredUnit,ForceRating,Vehicle)];
	};

	// Call up

#define TRACE_SYMBOL(symbol) diag_log format [#symbol + ": %1", symbol]

	while { _forceAdvantageWest > 0 && _eastForceReserves > 0 } do
	{
//		diag_log format ["Rebalance: Callup: FAW: %1", _forceAdvantageWest];

		private _ratingLimit = _forceAdvantageWest min _eastForceReserves;

		// Compute weights for each unit type that can be called up, along with a sum of those weights

		private _weightSum = 0.0;
		private _weights = _eastCallups apply
		{
			private _rating = _x select 1;
			private _ratingValue = (_rating select 0) * (_rating select 1);

			private _weight = 0;
			if (_ratingValue <= _ratingLimit) then
			{
				_weight = 1 / (abs (_ratingValue - _westRatingAverage) + 10);
				_weight = _weight * (_rating select 2);
				_weightSum = _weightSum + _weight;
			};

			_weight
		};

		if (_weightSum == 0.0) exitWith {};

		// Select a value at random from the weight sum and use that to track down which unit type it refers to.  Heavily-weighted
		// unit types will be chosen more frequently than lightly-weighted unit types.

		private _weight = random _weightSum;

		_weightSum = 0.0;
		private _match = -1;
		{
			_weightSum = _weightSum + _x;
			if (_weightSum >= _weight) exitWith { _match = _forEachIndex };
		} forEach _weights;

		private _calledUpRating = _eastCallups select _match;

		CHANGES(_changes,callup) pushBack _calledUpRating;

		private _ratings = _calledUpRating select 1;
		private _rating = (_ratings select 0) * (_ratings select 1);
		_forceAdvantageWest = (_forceAdvantageWest - _rating) max 0;
		_eastForceReserves = (_eastForceReserves - _rating) max 0;

//		diag_log format ["Rebalance: Callup: FAW: %1, Unit: %2", _forceAdvantageWest, _calledUpRating select 0];
	};

	if (OO_GET(_category,ForceCategory,UnitsCanRetire)) then
	{
		while { _forceAdvantageWest < 0 } do
		{
//			diag_log format ["Rebalance: Retire: FAW: %1", _forceAdvantageWest];

			private _ratingLimit = abs _forceAdvantageWest;

			// Respect the individual unit's settings
			_eastUnitsActiveForce = _eastUnitsActiveForce select { OO_GET(_x,ForceUnit,Vehicle) getVariable ["SPM_Force_AllowRetire", true] };

			// Find the largest active unit that fits the west force deficit
			private _closestMatch = [-1, 0];
			{
				private _rating = OO_GET(_x,ForceRating,Rating);
				if (_rating > (_closestMatch select 1) && { _rating < _ratingLimit }) then
				{
					_closestMatch = [_forEachIndex, _rating];
				}
			} forEach _eastUnitsActiveForce;

			// If no active unit fits, retire the smallest unit available to drive the west back into an advantage
			if (_closestMatch select 0 == -1) then
			{
				_closestMatch set [1, 1e10];
				{
					private _rating = OO_GET(_x,ForceRating,Rating);
					if (_rating < (_closestMatch select 1)) then
					{
						_closestMatch = [_forEachIndex, _rating];
					}
				} forEach _eastUnitsActiveForce;
			};

			private _retiredUnit = _eastUnitsActiveForce deleteAt (_closestMatch select 0);
			CHANGES(_changes,retire) pushBack OO_GET(_retiredUnit,ForceRating,Vehicle);

			_forceAdvantageWest = _forceAdvantageWest + OO_GET(_retiredUnit,ForceRating,Rating);

//			diag_log format ["Rebalance: Retire: FAW: %1, Unit: %2", _forceAdvantageWest, OO_GET(_retiredUnit,ForceRating,Vehicle)];
		};
	};

	_changes set [SPM_CHANGES_RESERVES, _eastForceReserves];

	OO_SET(_category,ForceCategory,_FirstRebalance,false);

	_changes
};

// Will leave behind dead vehicles and dead bodies on the ground
OO_TRACE_DECL(SPM_Force_DeleteForceUnit) =
{
	params ["_forceUnit"];

	private _remainingGroups = [];
	{
		if ((vehicle _x) isKindOf "ParachuteBase") then { deleteVehicle vehicle _x };
		if (alive _x) then { deleteVehicle _x } else { _remainingGroups pushBackUnique group _x };
	} forEach OO_GET(_forceUnit,ForceUnit,Units);

	{
		if ({ alive _x } count units _x == 0) then { [_x] call SPM_DeletePatrolWaypoints };
	} forEach _remainingGroups;

	private _vehicle = OO_GET(_forceUnit,ForceUnit,Vehicle);

	// The only dead bodies we delete are the ones in vehicles
	{
		if (not alive _x && vehicle _x != _x) then { deleteVehicle _x };
	} forEach crew _vehicle;

	if (alive _vehicle) then
	{
		deleteVehicle _vehicle;
	};
};

OO_TRACE_DECL(SPM_Force_DeleteForceUnits) =
{
	params ["_forceUnits", "_criterion"];

	for "_i" from (count _forceUnits - 1) to 0 step -1 do
	{
		private _x = _forceUnits select _i; // _criterion expects a variable called _x
		if (call _criterion) then { [_forceUnits deleteAt _i] call SPM_Force_DeleteForceUnit };
	};
};

OO_TRACE_DECL(SPM_Force_RemoveForceUnits) =
{
	params ["_forceUnits", "_condition"];

	private _x = [];
	for "_i" from (count _forceUnits - 1) to 0 step -1 do
	{
		_x = _forceUnits select _i;
		if (call _condition) then
		{
			_forceUnits deleteAt _i;
		};
	};
};

OO_TRACE_DECL(SPM_Force_SalvageForceUnit) =
{
	params ["_forceCategory", "_key"];

	private _forceUnits = OO_GET(_forceCategory,ForceCategory,ForceUnits);
	private _ratings = OO_GET(_forceCategory,ForceCategory,RatingsEast);
	private _reserves = OO_GET(_forceCategory,ForceCategory,Reserves);

	private _index = _key;

	if (typeName _key != typeName 0) then { _index = [_forceUnits, _key] call SPM_Force_FindForceUnit };

	if (_index < 0) exitWith { _reserves };

	private _forceUnit = _forceUnits deleteAt _index;

	private _unitForce = [OO_GET(_forceUnit,ForceUnit,Units), _ratings] call SPM_Force_GetForceRatings;
	if (count _unitForce > 0) then
	{
		_reserves = _reserves + OO_GET(_unitForce select 0,ForceRating,Rating);
	};

	[_forceUnit] call SPM_Force_DeleteForceUnit;

	OO_SET(_forceCategory,ForceCategory,Reserves,_reserves);
};

OO_TRACE_DECL(SPM_Force_RetireOnFoot) =
{
	params ["_units", "_retireCallback", "_passthrough"];

	for "_i" from (count _units - 1) to 0 step -1 do
	{
		private _forceUnit = _units select _i;
		if (not alive (OO_GET(_forceUnit,ForceUnit,Vehicle))) then
		{
			{
				if ([_x] call SPM_Util_GroupMembersAreDead) then
				{
					_units deleteAt _i;
				}
				else
				{
					if (not (_x getVariable ["SPM_Force_Retiring", false])) then
					{
						[_i, _passthrough] call _retireCallback;
					};
				};
			} forEach ([] call OO_METHOD(_forceUnit,ForceUnit,GetGroups));
		};
	};
};

OO_TRACE_DECL(SPM_Force_RetireDepleted) =
{
	params ["_units", "_retireCallback", "_passthrough"];

	private _vehicle = objNull;
	private _essentialMagazines = [];
	private _availableMagazines = [];
	private _availableTypes = [];
	private _availableCounts = [];

	private _index = 0;
	private _retire = false;

	{
		_vehicle = OO_GET(_x,ForceUnit,Vehicle);
		if (not isNull _vehicle && { alive driver _vehicle }) then
		{
			_retire = true;

			if (canFire _vehicle) then
			{
				_essentialMagazines = _vehicle getVariable ["SPM_Force_EssentialMagazines", []];

				if (count _essentialMagazines == 0) then
				{
					_retire = false;
				}
				else
				{
					_availableMagazines = magazinesAmmo _vehicle;
					_availableTypes = _availableMagazines apply { _x select 0 };
					_availableCounts = _availableMagazines apply { _x select 1 };

					{
						_index = _availableTypes find (_x select 0);

						if (_index >= 0 && { (_availableCounts select _index) > (_x select 1) }) exitWith { _retire = false };

						_availableTypes deleteAt _index;
						_availableCounts deleteAt _index;
					} forEach _essentialMagazines;
				};
			};

			if (_retire) then
			{
				[_forEachIndex, _passthrough] call _retireCallback;
			};
		};
	} forEach _units;
};

OO_TRACE_DECL(SPM_Force_DeleteEnemiesOnBases) =
{
	params ["_forceUnits", "_distance", "_baseSide"];

	private _position = [];
	private _blacklist = [_distance, -1, -1] call SERVER_OperationBlacklist;
	private _enemyOnBase =
	{
		if (side effectiveCommander OO_GET(_x,ForceUnit,Vehicle) getFriend _baseSide > 0.6) exitWith { false };

		_position = getPos OO_GET(_x,ForceUnit,Vehicle);
		
		_blacklist findIf { [_position, _x] call SPM_Util_PositionInArea } >= 0
	};

	[_forceUnits, _enemyOnBase] call SPM_Force_DeleteForceUnits;
};

OO_TRACE_DECL(SPM_Force_FindForceUnit) =
{
	params ["_units", "_key"];

	private _index = -1;

	switch (typeName _key) do
	{
		case typeName objNull:
		{
			if (not isNull _key) then
			{
				{
					if (_key == OO_GET(_x,ForceUnit,Vehicle)) exitWith
					{
						_index = _forEachIndex;
					};
				} forEach _units;
			};
		};

		case typeName grpNull:
		{
			if (not isNull _key) then
			{
				{
					if (_key in ([] call OO_METHOD(_x,ForceUnit,GetGroups))) exitWith
					{
						_index = _forEachIndex;
					};
				} forEach _units;
			};
		};

		default
		{
			_index = [_units, OO_GET(_key,ForceUnit,Vehicle)] call SPM_Force_FindForceUnit;
			if (_index == -1) then
			{
				{
					_index = [_units, _x] call SPM_Force_FindForceUnit;
					if (_index != -1) exitWith {};
				} forEach ([] call OO_METHOD(_key,ForceUnit,GetGroups));
			};
		};
	};

	_index;
};

OO_TRACE_DECL(SPM_Force_GetForceLevels) =
{
	params ["_category", "_proximity", "_units", "_ratings"];

	if (_proximity >= 0) then
	{
		private _area = OO_GET(_category,ForceCategory,Area);
		private _center = OO_GET(_area,StrongpointArea,Position);
		private _innerRadius = OO_GET(_area,StrongpointArea,InnerRadius);
		private _outerRadius = OO_GET(_area,StrongpointArea,OuterRadius);

		_innerRadius = (_innerRadius - _proximity) max 0;
		_outerRadius = (_outerRadius + _proximity);

		_units = [_center, _innerRadius, _outerRadius, _units] call SPM_Util_GetUnits;
	};

	([_units, _ratings] call SPM_Force_GetForceRatings)
};

OO_TRACE_DECL(SPM_Force_GetForceLevelsWest) =
{
	params ["_category", "_proximity"];

	private _side = OO_GET(_category,ForceCategory,SideWest);
	private _units = allUnits select { side _x == _side && { lifeState _x in ["HEALTHY", "INJURED"] } };

	([_category, _proximity, _units, OO_GET(_category,ForceCategory,RatingsWest)] call SPM_Force_GetForceLevels)
};

OO_TRACE_DECL(SPM_Force_GetForceLevelsEast) =
{
	params ["_category", "_proximity"];

	private _units = OO_GET(_category,ForceCategory,ForceUnits) apply { OO_GET(_x,ForceUnit,Vehicle) };

	([_category, _proximity, _units, OO_GET(_category,ForceCategory,RatingsEast)] call SPM_Force_GetForceLevels)
};

OO_TRACE_DECL(SPM_ForceCategory_ReplaceUnit) =
{
	params ["_category", "_oldUnit", "_newUnit"];

	private _oldVehicle = OO_GET(_oldUnit,ForceUnit,Vehicle);
	private _index = OO_GET(_category,ForceCategory,ForceUnits) findIf { _oldVehicle == OO_GET(_x,ForceUnit,Vehicle) };
	if (_index != -1) then { OO_GET(_category,ForceCategory,ForceUnits) set [_index, _newUnit] };

	_index
};

OO_TRACE_DECL(SPM_ForceCategory_Command) =
{
	params ["_category", "_command", "_parameters"];

	switch (_command) do
	{
		case "surrender":
		{
			if (OO_GET(_category,ForceCategory,_Surrendered)) exitWith {};

			OO_SET(_category,ForceCategory,_Surrendered,true);

			private _area = OO_GET(_category,ForceCategory,Area);
			private _center = OO_GET(_area,StrongpointArea,Position);
			private _outerRadius = OO_GET(_area,StrongpointArea,OuterRadius);

			private _vehicles = [];
			private _men = [];

			{
				if (not (OO_GET(_x,ForceUnit,Vehicle) isKindOf "Man")) then
				{
					_vehicles pushBack OO_GET(_x,ForceUnit,Vehicle);
				};

				_men append (OO_GET(_x,ForceUnit,Units) select { alive _x });
			} forEach OO_GET(_category,ForceCategory,ForceUnits);

			[_men, _vehicles, _center, _outerRadius, _parameters] call SPM_Util_Surrender;
		};

		case "minimize":
		{
			[_category] call SPM_ForceCategory_DeleteAllUnits;
		};
	};
};

OO_TRACE_DECL(SPM_ForceCategory_DeleteAllUnits) =
{
	params ["_category"];

	private _sideWest = OO_GET(_category,ForceCategory,SideWest);
	private _forceUnits = OO_GET(_category,ForceCategory,ForceUnits);
	while { count _forceUnits > 0 } do
	{
		private _forceUnit = _forceUnits deleteAt 0;
		private _vehicle = OO_GET(_forceUnit,ForceUnit,Vehicle);
		if (alive _vehicle && { side _vehicle != _sideWest }) then
		{
			[_forceUnit] call SPM_Force_DeleteForceUnit;
		};
	};
};

OO_TRACE_DECL(SPM_ForceCategory_Delete) =
{
	params ["_category"];

	[_category] call SPM_ForceCategory_DeleteAllUnits;

	[] call OO_METHOD_PARENT(_category,Root,Delete,Category);
};

OO_TRACE_DECL(SPM_ForceCategory_Update) =
{
	params ["_category"];

	[] call OO_METHOD_PARENT(_category,Category,Update,Category);
};

private _defaultCallupDirection = [0,360];
private _defaultRetireDirection = [0,360];

OO_BEGIN_SUBCLASS(ForceCategory,Category);
	OO_OVERRIDE_METHOD(ForceCategory,Root,Delete,SPM_ForceCategory_Delete);
	OO_OVERRIDE_METHOD(ForceCategory,Category,Update,SPM_ForceCategory_Update);
	OO_OVERRIDE_METHOD(ForceCategory,Category,Command,SPM_ForceCategory_Command);
	OO_DEFINE_METHOD(ForceCategory,GetForceLevelsWest,SPM_Force_GetForceLevelsWest);
	OO_DEFINE_METHOD(ForceCategory,GetForceLevelsEast,SPM_Force_GetForceLevelsEast);
	OO_DEFINE_METHOD(ForceCategory,ReplaceUnit,SPM_ForceCategory_ReplaceUnit);
	OO_DEFINE_PROPERTY(ForceCategory,Area,"ARRAY",[]); // StrongpointArea structure
	OO_DEFINE_PROPERTY(ForceCategory,Reserves,"SCALAR",1e30);
	OO_DEFINE_PROPERTY(ForceCategory,SideWest,"SIDE",west);
	OO_DEFINE_PROPERTY(ForceCategory,SideEast,"SIDE",east);
	OO_DEFINE_PROPERTY(ForceCategory,RatingsWest,"ARRAY",[]);
	OO_DEFINE_PROPERTY(ForceCategory,RatingsEast,"ARRAY",[]);
	OO_DEFINE_PROPERTY(ForceCategory,RangeWest,"SCALAR",0); // How far from the edges of the ForceCategory Area that West units should be considered involved in this fight (-1 means all west units everywhere)
	OO_DEFINE_PROPERTY(ForceCategory,CallupsEast,"ARRAY",[]); // Make sure there is a rating for every callup
	OO_DEFINE_PROPERTY(ForceCategory,PendingCallups,"SCALAR",0); // The number of callups queued with a spawn manager
	OO_DEFINE_PROPERTY(ForceCategory,SkillLevel,"SCALAR",0.5); // Soldier skill
	OO_DEFINE_PROPERTY(ForceCategory,DifficultyLevel,"SCALAR",1.0); // A multiple of east forces to send in relative to a normal balanced deployment
	OO_DEFINE_PROPERTY(ForceCategory,ForceUnits,"ARRAY",[]); // The east ForceUnits
	OO_DEFINE_PROPERTY(ForceCategory,UnitsCanRetire,"BOOL",false); // Whether units can retire from an operation when too few west units are present
	OO_DEFINE_PROPERTY(ForceCategory,_Surrendered,"BOOL",false); // Whether the category has surrendered its units
	OO_DEFINE_PROPERTY(ForceCategory,InitialMinimumWestForce,"ARRAY",[]); // The minimum force against which east should deploy
	OO_DEFINE_PROPERTY(ForceCategory,MinimumWestForce,"ARRAY",[]); // The minimum west force against which east should maintain opposition
	OO_DEFINE_PROPERTY(ForceCategory,_FirstRebalance,"BOOL",true);
	OO_DEFINE_PROPERTY(ForceCategory,CallupDirection,"ARRAY",_defaultCallupDirection); // A compass direction and sweep angle.  The default says "approach from any direction"
OO_END_SUBCLASS(ForceCategory);