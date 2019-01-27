#include "..\OO\oo.h"

// JBA_S_TransportStores and JBA_C_TransportStores: [[magazine-type, round-count], [magazine-type, round-count], ...]

#define IDC_OK 1
#define IDC_CANCEL 2

JBA_FromUnit = objNull;
JBA_ToUnit = objNull;
JBA_WaitingForTransfer = false;

#define TRANSFER_DISPLAY 2700
#define FROM_AMMO_LIST 1200
#define CHOSEN_COUNT 1300
#define TO_AMMO_LIST 1500
#define TO_SOURCES 1600
#define FROM_AMMO_TITLE 1700
#define FROM_CAPACITY 1800
#define TO_CAPACITY 1900

#define AMMO_BOX_CAPACITY 65

// By default, a vehicle will only permit transfers to the current player, and only if the player is near the edge of the vehicle.  This
// exists to cover vehicles that have ammo, but which are not ammo transport vehicles.  Ammo transporters have an explicit transfer filter on them.
#define DEFAULT_DIRECT_TRANSFER_FILTER [10, JBA_TransferOnlyToPlayer]

OO_TRACE_DECL(JBA_IsLogisticsSpecialist) =
{
	params ["_unit"];

	_unit getVariable ["JBA_LogisticsSpecialist", false]
};

OO_TRACE_DECL(JBA_TransferOnlyToPlayer) =
{
	params ["_unit", "_candidate"];

	if (not ([_candidate, _unit, 2] call JBA_IsNearUnit)) exitWith { false };

	// If player is a logistics specialist and the candidate is a nearby trolly, allow it
	if (([player] call JBA_IsLogisticsSpecialist) && (((typeOf _candidate) find "Land_PalletTrolley_01_") == 0)) exitWith { true };

	// If the candidate is the player's associated ammo source, allow it
	if (_candidate == ([player] call JBA_PlayerAmmoSource)) exitWith { true };

	false
};

// [magazine-name, [weight-per-round, weapon-name]]
JBA_Magazines =
[
	["200Rnd_65x39_Belt_Tracer_Red", [0.016, "LMG_M200"]],
	["200Rnd_762x51_Belt_T_Red", [0.025, "LMG_M200_body"]],
	["500Rnd_127x99_mag_Tracer_Red", [0.117, "HMG_127"]],
	["200Rnd_127x99_mag_Tracer_Red", [0.117, "HMG_127"]],
	["100Rnd_127x99_mag_Tracer_Red", [0.117, "HMG_M2"]],
	["130Rnd_338_Mag", [0.020, "MMG_02_vehicle"]],
	["24Rnd_120mm_APFSDS_shells_Tracer_Red", [18.6, "cannon_120mm"]],
	["12Rnd_120mm_APFSDS_shells_Tracer_Red", [18.6, "cannon_120mm"]],
	["12Rnd_120mm_HEAT_MP_T_Red", [24.2, "cannon_120mm"]],
	["8Rnd_120mm_HEAT_MP_T_Red", [24.2, "cannon_120mm"]],
	["140Rnd_30mm_MP_shells_Tracer_Red", [1.460, "autocannon_30mm_CTWS"]],
	["60Rnd_30mm_APFSDS_shells_Tracer_Red", [1.460, "autocannon_30mm_CTWS"]],
	["4Rnd_120mm_LG_cannon_missiles", [15.8, "cannon_120mm"]],
	["4Rnd_Titan_long_missiles", [15.8, "missiles_titan"]],
	["680Rnd_35mm_AA_shells_Tracer_Red", [1.565, "autocannon_35mm"]],
	["40Rnd_20mm_G_belt", [0.150, "GMG_20mm"]],
	["200Rnd_40mm_G_belt", [0.230, "GMG_40mm"]],

	["8Rnd_82mm_Mo_shells", [3.1, "mortar_82mm"]],
	["8Rnd_82mm_Mo_Flare_white", [3.1, "mortar_82mm"]],
	["8Rnd_82mm_Mo_Smoke_white", [3.1, "mortar_82mm"]],

	["32Rnd_155mm_Mo_shells", [8.0, "mortar_155mm_AMOS"]],
	["2Rnd_155mm_Mo_Cluster", [47.0, "mortar_155mm_AMOS"]],
	["2Rnd_155mm_Mo_LG", [62.4, "mortar_155mm_AMOS"]],
	["2Rnd_155mm_Mo_guided", [62.4, "mortar_155mm_AMOS"]],
	["6Rnd_155mm_Mo_smoke", [8.6, "mortar_155mm_AMOS"]],

	["Laserbatteries", [1, "Laserdesignator_mounted"]],
	["SmokeLauncherMag", [6, "SmokeLauncher"]],

	["2000Rnd_65x39_Belt_Tracer_Red", [0.016, "LMG_Minigun_Transport"]],
	["1000Rnd_20mm_shells", [0.56, "gatling_20mm"]],
	["1000Rnd_Gatling_30mm_Plane_CAS_01_F", [0.397, "Gatling_30mm_Plane_CAS_01_F"]],
	["500Rnd_65x39_Belt_Tracer_Red_Splash", [0.016, "LMG_Minigun_Transport"]],
	["120Rnd_CMFlare_Chaff_Magazine", [0.175, "CMFlareLauncher"]],
	["168Rnd_CMFlare_Chaff_Magazine", [0.175, "CMFlareLauncher"]],
	["240Rnd_CMFlare_Chaff_Magazine", [0.175, "CMFlareLauncher"]],
	["24Rnd_missiles", [15.8, "missiles_DAR"]],
	["24Rnd_PG_missiles", [15.8, "missiles_DAGR"]],
	["2Rnd_GBU12_LGB", [230, "GBU12BombLauncher"]],
	["2Rnd_Missile_AA_03_F", [85.3, "Missile_AA_03_Plane_CAS_02_F"]],
	["4Rnd_AAA_missiles", [88, "missiles_ASRAAM"]],
	["4Rnd_Bomb_04_F", [230, "Bomb_04_Plane_CAS_01_F"]],
	["4Rnd_GAA_missiles", [88, "missiles_Zephyr"]],
	["500Rnd_Cannon_30mm_Plane_CAS_02_F", [0.397, "Cannon_30mm_Plane_CAS_02_F"]],
	["6Rnd_LG_scalpel", [45.3, "missiles_SCALPEL"]],
	["6Rnd_Missile_AGM_02_F", [45.5, "Missile_AGM_02_Plane_CAS_01_F"]],
	["7Rnd_Rocket_04_AP_F", [6.2, "Rocket_04_AP_Plane_CAS_01_F"]],
	["7Rnd_Rocket_04_HE_F", [6.2, "Rocket_04_HE_Plane_CAS_01_F"]],
	["SmokeLauncherMag_boat", [6, "SmokeLauncher"]],

	["100Rnd_127x99_mag_Tracer_Green", [0.117, "HMG_M2"]],
	["200Rnd_762x51_Belt_T_Green", [0.025, "LMG_Coax"]],
	["200Rnd_65x39_Belt_Tracer_Green", [0.016, "LMG_M200"]],
	["16Rnd_125mm_APFSDS_T_Green", [20.4, "cannon_125mm"]],
//	["12Rnd_125mm_HE_T_Green", [33, "cannon_125mm"]],
	["12Rnd_125mm_HEAT_T_Green", [19, "cannon_125mm"]],
	["140Rnd_30mm_MP_shells_Tracer_Green", [1.460, "autocannon_30mm_CTWS"]],
	["60Rnd_30mm_APFSDS_shells_Tracer_Green", [1.46, "autocannon_30mm_CTWS"]],
	["450Rnd_127x108_Ball", [0.133, "HMG_NSVT"]],

	["100Rnd_127x99_mag_Tracer_Yellow", [0.117, "HMG_M2"]],
	["200Rnd_762x51_Belt_T_Yellow", [0.025, "LMG_Coax"]],
	["200Rnd_65x39_Belt_Tracer_Yellow", [0.016, "LMG_M200"]],
	["20Rnd_120mm_APFSDS_shells_Tracer_Yellow", [18.6, "cannon_120mm_long"]],
	["12Rnd_120mm_HEAT_MP_T_Yellow", [24.2, "cannon_120mm_long"]],
//	["14Rnd_120mm_HE_shells_Tracer_Yellow", [19, "cannon_120mm_long"]],
	["500Rnd_127x99_mag_Tracer_Yellow", [0.117, "HMG_127_APC"]],
	["140Rnd_30mm_MP_shells_Tracer_Yellow", [1.460, "autocannon_30mm_CTWS"]],
	["60Rnd_30mm_APFSDS_shells_Tracer_Yellow", [1.46, "autocannon_30mm_CTWS"]],

	["2Rnd_GAT_missiles", [15.8, "missiles_titan"]]
];

OO_TRACE_DECL(JBA_RoundsPerMagazine) =
{
	getNumber (configFile >> "CfgMagazines" >> (_this select 0) >> "count");
};

OO_TRACE_DECL(JBA_IsAmmoSource) =
{
	params ["_candidate", "_unit", "_transferFilter"];

	if (_candidate == _unit) exitWith { false };

	if (not alive _candidate) exitWith { false };

	if (isNil { _candidate getVariable "JBA_TransportCapacity" } && { _candidate isKindOf "Man" || (weapons _candidate) findIf { [_x] call JB_fnc_isOffensiveWeapon } == -1 }) exitWith { false };

	if (not ([_unit, _candidate] call _transferFilter)) exitWith { false };

	true;
};

OO_TRACE_DECL(JBA_AmmoSourceName) =
{
	params ["_source"];

	// An ammobox attached to a player reports the player's name
	if ([_source] call JBA_IsAmmoBox && { isPlayer attachedTo _source }) exitWith { name (attachedTo _source) };

	([typeOf _source, "CfgVehicles"] call JB_fnc_displayName)
};

OO_TRACE_DECL(JBA_SetToUnit) =
{
	params ["_unit"];

	if (JBA_ToUnit == _unit) exitWith {};

	if (not isNull JBA_ToUnit) then
	{
		[player, JBA_ToUnit] remoteExec ["JBA_S_MonitorChangesStop", 2];
	};

	JBA_ToUnit = _unit;
	if (not isNull JBA_ToUnit) then
	{
		[player, JBA_ToUnit] remoteExec ["JBA_S_MonitorChangesStart", 2];
	};
};

OO_TRACE_DECL(JBA_SetFromUnit) =
{
	params ["_unit"];

	if (JBA_FromUnit == _unit) exitWith {};

	if (not isNull JBA_FromUnit) then
	{
		[player, JBA_FromUnit] remoteExec ["JBA_S_MonitorChangesStop", 2];
	};

	JBA_FromUnit = _unit;
	if (not isNull JBA_FromUnit) then
	{
		[player, JBA_FromUnit] remoteExec ["JBA_S_MonitorChangesStart", 2];
	};
};

JBA_IsNearUnit =
{
	params ["_player", "_unit", "_distance"];

	([_player, _unit] call JB_fnc_distanceBetweenBoundingBoxes) < _distance
};

OO_TRACE_DECL(JBA_StoresMassOfficial) =
{
	params ["_unit"];

	if (isServer) exitWith
	{
		private _stores = _unit getVariable ["JBA_S_TransportStores", []];
		[_stores] call JBA_StoresMass;
	};

	private _result = [[_unit], "JBA_UnitStoresMass", 2] call JB_fnc_remoteCall;
	if (_result select 0 == JBRC_TIMEDOUT) exitWith { 0 };
	_result select 1;
};

// Hide player's automatic ammo box whenever it's empty
OO_TRACE_DECL(JBA_PlayerAmmoBoxStoresChanged) =
{
	params ["_ammoBox", "_stores"];

	private _shouldBeHidden = (count _stores == 0);
	if (not (_shouldBeHidden isEqualTo (isObjectHidden _ammoBox))) then { [_ammoBox, _shouldBeHidden] remoteExec ["hideObjectGlobal", 2] };
};

OO_TRACE_DECL(JBA_S_CreateAmmoBox) =
{
	params ["_ammoBox"];

	_ammoBox setVariable ["JBA_OnStoresChanged", JBA_PlayerAmmoBoxStoresChanged, true];

	[_ammoBox, AMMO_BOX_CAPACITY] call JB_fnc_ammoInit;
	[_ammoBox, 0.5, 0.3] call JB_fnc_damagePulseInitObject;

	_ammoBox setVariable ["JBA_AmmoBox", true, true];
};

OO_TRACE_DECL(JBA_CreateAmmoBox) =
{
	private _ammoBox = createVehicle ["Box_NATO_Wps_F", call JB_MDI_RandomSpawnPosition, [], 0, "can_collide"];
	_ammoBox hideObjectGlobal true;

	[_ammoBox] call JB_fnc_containerClear;
	[_ammoBox] call JB_fnc_containerLock;
	[_ammoBox, nil, { (_this select 0) getVariable ["JBA_LastKnownMass", AMMO_BOX_CAPACITY] }] call JB_fnc_carryObjectInitObject;

	[_ammoBox] remoteExec ["JBA_S_CreateAmmoBox", 2];

	_ammoBox
};

JBA_PlayerAmmoBox =
{
	private _index = (attachedObjects player) findIf { [_x] call JBA_IsAmmoBox };

	if (_index == -1) exitWith { objNull };

	(attachedObjects player) select _index
};

OO_TRACE_DECL(JBA_MonitorAmmoSources) =
{
	_this spawn
	{
		scriptName "spawnJBA_MonitorAmmoSources";

		params ["_unit"];

		//BUG: Need to test filtering by the other object involved in the transfer
		private _transfers = _unit getVariable ["JBA_DirectTransferFilter", DEFAULT_DIRECT_TRANSFER_FILTER];
		private _transferFilterRange = _transfers select 0;
		private _transferFilter = _transfers select 1;

		disableSerialization;
		private _display = findDisplay TRANSFER_DISPLAY;
		private _sourcesControl = _display displayCtrl TO_SOURCES;

		private _sources = [];
		lbClear _sourcesControl;

		while { not isNull (findDisplay TRANSFER_DISPLAY) && { [player, _unit, 2] call JBA_IsNearUnit } && { lifeState player in ["HEALTHY", "INJURED"] } } do
		{
			private _selectedIndex = lbCurSel _sourcesControl;
			private _selection = if (_selectedIndex == -1) then { objNull } else { (_sources select _selectedIndex) select 0 };

			[_selection] call JBA_SetToUnit;

			// Build a list of objects that are ammo sources within the unit's transfer range
			private _sourceObjects = (nearestObjects [_unit, ["All"], 20]) select { [_x, _unit, _transferFilter] call JBA_IsAmmoSource } select { [_x, _unit, _transferFilterRange] call JBA_IsNearUnit };

			// Collect sources, ordered by distance, resulting with an array of [source-object, source-name]
			private _newSources = _sourceObjects apply { [[_unit, _x] call JB_fnc_distanceBetweenBoundingBoxes, _x, [_x] call JBA_AmmoSourceName] };
			_newSources sort true;
			{ _x deleteAt 0 } forEach _newSources; // Get rid of the distance value

			// If the available sources has changed, reload the listbox and make sure the old selection is still valid
			if (not (_newSources isEqualTo _sources)) then
			{
				_sources = _newSources;

				_selectedIndex = -1;
				lbClear _sourcesControl;
				{
					_sourcesControl lbAdd (_x select 1);
					if (_x select 0 == _selection) then { _selectedIndex = _forEachIndex };
				} forEach _sources;

				// If the current selection is no longer available, select a default
				if (_selectedIndex == -1) then
				{
					_selection = objNull;
					if (count _sources > 0) then
					{
						// Select any ammo source attached to the player
						_selectedIndex = _sources findIf { [_x select 0, _unit, _transferFilter] call JBA_IsAmmoSource && { attachedTo (_x select 0) == player } };

						// Otherwise, get the closest source
						if (_selectedIndex == -1) then { _selectedIndex = 0 };

						_selection = (_sources select _selectedIndex) select 0;
					};
				};

				[_selection] call JBA_SetToUnit;

				_sourcesControl lbSetCurSel _selectedIndex;
			};

			[{ isNull (findDisplay TRANSFER_DISPLAY) }, 1] call JB_fnc_timeoutWaitUntil;
		};

		if (not isNull (findDisplay TRANSFER_DISPLAY)) then { (findDisplay TRANSFER_DISPLAY) closeDisplay IDC_OK };
	};

	0
};

JBA_ShowAmmoListCondition =
{
	if (not isNull (findDisplay TRANSFER_DISPLAY)) exitWith { false };

	// Player must be on foot
	if (vehicle player != player) exitWith { false };

	// Source must be either the player's side or civilian (no stealing from enemies)
	if (not (side cursorObject in [side player, civilian])) exitWith { false };

	// Source cannot be attached to a person (no stealing from people)
	if (not isNull attachedTo cursorObject && { attachedTo cursorObject isKindOf "Man" } ) exitWith { false };

	// Source must be capable either of transporting ammo or of using it
	// (the simpler "magazines" command is not used because it returns [] if all magazines are empty)
	if (isNil { cursorObject getVariable "JBA_TransportCapacity" } && { count (magazinesAllTurrets cursorObject) == 0 }) exitWith { false };

	(getCursorObjectParams select 2) < 2.0
};

OO_TRACE_DECL(JBA_ShowAmmoList) =
{
	params ["_unit"];

	(findDisplay 46) createDisplay "JBA_Transfer";
	waitUntil { not isNull (findDisplay TRANSFER_DISPLAY) };

	[_unit] call JBA_SetFromUnit;
	[objNull] call JBA_SetToUnit;

	((findDisplay TRANSFER_DISPLAY) displayCtrl FROM_AMMO_TITLE) ctrlSetText ([JBA_FromUnit] call JBA_AmmoSourceName);

	// If not carrying anything, create an empty ammo box and carry that
	if (isNull ([player] call JBA_PlayerAmmoSource)) then
	{
		private _ammoBox = [] call JBA_CreateAmmoBox;
		[_ammoBox] call JB_fnc_carryObjectPickUp;
		waitUntil { sleep 0.1; not isNull ([] call JBA_PlayerAmmoBox) };
	};

	[JBA_FromUnit] call JBA_MonitorAmmoSources;
};

JBA_S_SendStoresList =
{
	params ["_caller", "_unit"];

	private _stores = _unit getVariable ["JBA_S_TransportStores", nil];

	// If the unit has no transport stores, then its weapons are its stores
	if (isNil "_stores") then
	{
		private _magazines = magazinesAllTurrets _unit;

		_stores = [];
		private _storeIndex = -1;
		private _store = [];
		private _rounds = 0;
		private _magazineType = "";

		{
			_magazineType = _x select 0;
			_rounds = _x select 2;

			if (not (_magazineType in ["FakeWeapon", "FakeMagazine"]) && _rounds > 0) then
			{
				_storeIndex = [_stores, _magazineType] call JBA_GetStoreIndex;
				if (_storeIndex == -1) then
				{
					_stores pushBack [_magazineType, _rounds];
				}
				else
				{
					_store = _stores select _storeIndex;
					_store set [1, (_store select 1) + (_rounds)];
				};
			};
		} forEach _magazines;
	};

	[_unit, _stores] remoteExec ["JBA_C_ReceiveStoresList", _caller];
};

JBA_S_MonitorChangesStart =
{
	params ["_caller", "_unit"];

	JBA_S_CS_Monitor call JB_fnc_criticalSectionEnter;

	private _clients = _unit getVariable ["JBA_MonitoringClients", []];
	if (count _clients == 0) then
	{
		private _firedEventHandler = _unit addEventHandler ["Fired",
			{
				private _unit = _this select 0;
				private _magazineType = _this select 5;
				[objNull, _unit, _magazineType, -1] call JBA_NotifyStoreChanged;
			}];
		private _killedEventHandler = _unit addEventHandler ["Killed",
			{
				private _unit = _this select 0;
				[objNull, _unit] call JBA_S_DestroyStores;
			}];
		_unit setVariable ["JBA_MonitoringClients_EventHandlers", [_firedEventHandler, _killedEventHandler]];
	};
	_unit setVariable ["JBA_MonitoringClients", _clients + [_caller]];

	JBA_S_CS_Monitor call JB_fnc_criticalSectionLeave;

	[_caller, _unit] call JBA_S_SendStoresList;
};

JBA_S_MonitorChangesStop =
{
	params ["_caller", "_unit"];

	JBA_S_CS_Monitor call JB_fnc_criticalSectionEnter;

	private _clients = (_unit getVariable ["JBA_MonitoringClients", []]) - [_caller];
	if (count _clients == 0) then
	{
		private _eventHandlers = _unit getVariable ["JBA_MonitoringClients_EventHandlers", nil];
		if (!isNil "_eventHandlers") then
		{
			if (alive _unit) then
			{
				_unit removeEventHandler ["Fired", _eventHandlers select 0];
				_unit removeEventHandler ["Killed", _eventHandlers select 1];
			};
			_unit setVariable ["JBA_MonitoringClients_EventHandlers", nil];
		};
	};
	_unit setVariable ["JBA_MonitoringClients", _clients];

	JBA_S_CS_Monitor call JB_fnc_criticalSectionLeave;
};

OO_TRACE_DECL(JBA_KnownMagazineType) =
{
	params ["_magazineType"];

	([JBA_Magazines, _magazineType] call BIS_fnc_findInPairs) != -1;
};

OO_TRACE_DECL(JBA_WeightOfStore) =
{
	params ["_magazineType", "_rounds"];

	private _magazine = [JBA_Magazines, _magazineType] call BIS_fnc_getFromPairs;
	if (isNil "_magazine") then { diag_log format ["JB_fnc_ammoPreInit: Missing %1", _magazineType]; 0};

	(_magazine select 0) * _rounds;
};

OO_TRACE_DECL(JBA_StoresMass) =
{
	params ["_stores"];

	private _weight = 0;
	{
		_weight = _weight + ([_x select 0, _x select 1] call JBA_WeightOfStore);
	} forEach _stores;

	_weight;
};

OO_TRACE_DECL(JBA_LoadStoresDisplay) =
{
	params ["_display", "_unit", "_stores", "_listControl", "_progressControl"];
	
	lbClear (_display displayCtrl _listControl);
	{
		[_listControl, _x select 0, _x select 1] call JBA_AddAmmoLine;
	} forEach (_unit getVariable ["JBA_C_TransportStores", []]);

	private _percentFilled = 0;

	private _capacity = _unit getVariable ["JBA_TransportCapacity", nil];
	if (!isNil "_capacity") then
	{
		_percentFilled = ([_stores] call JBA_StoresMass) / _capacity;
		_percentFilled = _percentFilled min 1;
	};

	(_display displayCtrl _progressControl) progressSetPosition _percentFilled;
};

JBA_C_ReceiveStoresList =
{
	params ["_unit", "_stores"];

	disableSerialization;
	private _display = findDisplay TRANSFER_DISPLAY;
	if (isNull (findDisplay TRANSFER_DISPLAY)) then
	{
		if (_unit == player) then
		{
			_unit setVariable ["JBA_C_TransportStores", _stores];
		};
	}
	else
	{
		if (_unit == JBA_FromUnit) then
		{
			_unit setVariable ["JBA_C_TransportStores", _stores];
			[_display, _unit, _stores, FROM_AMMO_LIST, FROM_CAPACITY] call JBA_LoadStoresDisplay;
		};

		if (_unit == JBA_ToUnit) then
		{
			_unit setVariable ["JBA_C_TransportStores", _stores];
			[_display, _unit, _stores, TO_AMMO_LIST, TO_CAPACITY] call JBA_LoadStoresDisplay;
		};
	};

	[_unit, _stores] call (_unit getVariable ["JBA_OnStoresChanged", {}]);
};

OO_TRACE_DECL(JBA_AddAmmoLine) =
{
	params ["_control", "_magazineType", "_rounds"];

	private _magazineName = [_magazineType, "CfgMagazines"] call JB_fnc_displayName;
	if (_magazineName == "") then
	{
		private _weight = [JBA_Magazines, _magazineType] call BIS_fnc_getFromPairs;
		_magazineName = [_weight select 1, "CfgWeapons"] call JB_fnc_displayName;
	};
	private _roundsPerMagazine = [_magazineType] call JBA_RoundsPerMagazine;

	private _roundCountText = [_magazineType, _rounds, _roundsPerMagazine] call JBA_FormatRoundCount;

	((findDisplay TRANSFER_DISPLAY) displayCtrl _control) lnbAddRow [format ["%1", _roundsPerMagazine], _magazineName, _roundCountText];
};

OO_TRACE_DECL(JBA_FormatRoundCount) =
{
	params ["_magazineType", "_rounds", "_roundsPerMagazine"];

/*
	private _wholeMagazines = floor (_rounds / _roundsPerMagazine);
	private _looseRounds = _rounds - _wholeMagazines * _roundsPerMagazine;

	private _roundCountText = "";
	if (_looseRounds == 0) then
	{
		_roundCountText = format ["%1", _wholeMagazines];
	}
	else
	{
		_roundCountText = format ["%1 + %2", _wholeMagazines, _looseRounds];
	};

	_roundCountText
*/

	str _rounds
};

OO_TRACE_DECL(JBA_UpdateRoundCount) =
{
	params ["_control", "_index", "_text"];

	((findDisplay TRANSFER_DISPLAY) displayCtrl _control) lnbSetText [[_index, 2], _text];
};

JBA_IsAmmoBox =
{
	(_this select 0) getVariable ["JBA_AmmoBox", false]
};

OO_TRACE_DECL(JBA_DeleteEmptyAmmoBox) =
{
	params ["_ammoBox"];

	if (isNull _ammoBox) exitWith {};

	if (isObjectHidden _ammoBox) then
	{
		[_ammoBox] call JB_fnc_carryObjectDrop;
		deleteVehicle _ammoBox;
	};
};

OO_TRACE_DECL(JBA_TransferUnload) =
{
	params ["_display", "_exitCode"];

	if (not isNull JBA_FromUnit) then
	{
		if ([JBA_FromUnit] call JBA_IsAmmoBox) then
		{
			private _stores = JBA_FromUnit getVariable ["JBA_C_TransportStores", []];
			JBA_FromUnit setVariable ["JBA_LastKnownMass", [_stores] call JBA_StoresMass, true];
			[JBA_FromUnit] call JBA_DeleteEmptyAmmoBox;
		};

		JBA_FromUnit setVariable ["JBA_C_TransportStores", nil];
		[objNull] call JBA_SetFromUnit;
	};

	if (not isNull JBA_ToUnit) then
	{
		if ([JBA_ToUnit] call JBA_IsAmmoBox) then
		{
			private _stores = JBA_ToUnit getVariable ["JBA_C_TransportStores", []];
			JBA_ToUnit setVariable ["JBA_LastKnownMass", [_stores] call JBA_StoresMass, true];
			[JBA_ToUnit] call JBA_DeleteEmptyAmmoBox;
		};

		JBA_ToUnit setVariable ["JBA_C_TransportStores", nil];
		[objNull] call JBA_SetToUnit;
	};

	// The transfer may have not involved the player's ammo box and we want to delete it if it's empty
	[[] call JBA_PlayerAmmoBox] call JBA_DeleteEmptyAmmoBox;
};

OO_TRACE_DECL(JBA_TransferDoneAction) =
{
	params ["_display"];

	(findDisplay TRANSFER_DISPLAY) closeDisplay IDC_OK;
};

OO_TRACE_DECL(JBA_RequestTransfer) =
{
	params ["_control", "_fromUnit", "_toUnit"];

	if (isNull _fromUnit || isNull _toUnit) exitWith {};

	if (!JBA_WaitingForTransfer) then
	{
		private _fromIndex = lbCurSel ((findDisplay TRANSFER_DISPLAY) displayCtrl _control);
		if (_fromIndex >= 0) then
		{
			private _fromStores = _fromUnit getVariable ["JBA_C_TransportStores", []];

			private _fromStore = _fromStores select _fromIndex;
			private _magazineType = _fromStore select 0;
			private _availableRounds = _fromStore select 1;

			if ([_magazineType] call JBA_KnownMagazineType) then
			{
				private _roundsPerMagazine = [_magazineType] call JBA_RoundsPerMagazine;
				private _roundWeight = [_magazineType, 1] call JBA_WeightOfStore;

				private _rounds = if (_roundWeight > 5.0) then { 1 } else { _roundsPerMagazine min _availableRounds };

				private _toStores = _toUnit getVariable ["JBA_C_TransportStores", []];

				// Try to fill out an existing partial magazine
				private _toIndex = [_toStores, _magazineType] call JBA_GetStoreIndex;
				if (_toIndex >= 0) then
				{
					private _toStore = _toStores select _toIndex;
					private _availableSpace = _roundsPerMagazine - ((_toStore select 1) mod _roundsPerMagazine);
					if (_availableSpace > 0) then
					{
						_rounds = _rounds min _availableSpace;
					};
				};

				// Up to the weight capacity of the unit (if known)
				private _toCapacity = _toUnit getVariable "JBA_TransportCapacity";
				if (not isNil "_toCapacity") then
				{
					private _availableToCapacity = _toCapacity - ([_toStores] call JBA_StoresMass);
					_rounds = _rounds min floor (_availableToCapacity / _roundWeight);
				};

				JBA_WaitingForTransfer = true;
				[player, _fromUnit, _toUnit, _magazineType, _rounds] remoteExec ["JBA_S_TransferAmmo", 2];
			};
		};
	};
};

OO_TRACE_DECL(JBA_TransferFromKeyDown) =
{
	params ["_control", "_keyCode", "_shiftKey", "_controlKey", "_altKey"];

	private _override = false;

	switch (_keyCode) do
	{
		case 57: // space
		{
			if (not _shiftKey && not _controlKey && not _altKey) then
			{
				[FROM_AMMO_LIST, JBA_FromUnit, JBA_ToUnit] call JBA_RequestTransfer;
				_override = true;
			};
		};

		default
		{
		};
	};

	_override
};

OO_TRACE_DECL(JBA_TransferToKeyDown) =
{
	params ["_control", "_keyCode", "_shiftKey", "_controlKey", "_altKey"];

	private _override = false;

	switch (_keyCode) do
	{
		case 57: // space
		{
			if (not _shiftKey && not _controlKey && not _altKey) then
			{
				[TO_AMMO_LIST, JBA_ToUnit, JBA_FromUnit] call JBA_RequestTransfer;
				_override = true;
			};
		};

		default
		{
		};
	};

	_override
};

#define CHANGE_SUCCESSFUL 0
#define CHANGE_PENDING 1
#define UNKNOWN_MAGAZINE_TYPE -1
#define INSUFFICIENT_ROUNDS -2
#define INSUFFICIENT_CAPACITY -3

OO_TRACE_DECL(JBA_GetStoreIndex) =
{
	params ["_stores", "_magazineType"];

	private _storeIndex = -1;
	{
		if (_x select 0 == _magazineType) exitWith { _storeIndex = _forEachIndex };
	} forEach _stores;

	_storeIndex;
};

JBA_S_RemoveAmmoFromStoreVirtual =
{
	params ["_from", "_magazineType", "_rounds"];

	private _stores = _from getVariable ["JBA_S_TransportStores", []];
	private _storeIndex = [_stores, _magazineType] call JBA_GetStoreIndex;

	// If we don't know the magazineType, leave
	if (_storeIndex == -1) exitWith { UNKNOWN_MAGAZINE_TYPE };

	private _store = _stores select _storeIndex;

	// If there aren't enough rounds, leave
	if (_store select 1 < _rounds) exitWith { INSUFFICIENT_ROUNDS };

	if (_store select 1 == _rounds)	 then
	{
		_stores deleteAt _storeIndex;
	}
	else
	{
		_store set [1, (_store select 1) - _rounds];
	};

	_from setVariable ["JBA_S_TransportStores", _stores];

	CHANGE_SUCCESSFUL
};

OO_TRACE_DECL(JBA_AdjustTurretAmmo) =
{
	params ["_vehicle", "_turret", "_magazineType", "_adjustment"];

	private _magazines = magazinesAllTurrets _vehicle select { _x select 0 == _magazineType };

	private _numberRounds = 0;
	{ _numberRounds = _numberRounds + (_x select 2) } forEach _magazines;

	_numberRounds = (_numberRounds + _adjustment) max 0;

	private _fullMagazineRounds = [_magazineType] call JBA_RoundsPerMagazine;

	_vehicle removeMagazinesTurret [_magazineType, _turret];

	for "_i" from 1 to count _magazines do
	{
		private _roundsInMagazine = _numberRounds mod _fullMagazineRounds;
		if (_roundsInMagazine == 0 && _numberRounds > 0) then { _roundsInMagazine = _fullMagazineRounds };
		_numberRounds = _numberRounds - _roundsInMagazine;
		_vehicle addMagazineTurret [_magazineType, _turret, _roundsInMagazine];
	};
};

OO_TRACE_DECL(JBA_FindTurretWithRounds) =
{
	params ["_vehicle", "_magazineType", "_rounds"];

	private _turret = [];
	{
		if (_x select 0 == _magazineType && { _x select 2 >= _rounds } ) exitWith { _turret = _x select 1 };
	} forEach magazinesAllTurrets _from;

	_turret;
};

OO_TRACE_DECL(JBA_FindTurretWithoutRounds) =
{
	params ["_vehicle", "_magazineType", "_rounds"];

	private _turret = [];
	{
		if (_x select 0 == _magazineType && { _x select 2 < ([_magazineType] call JBA_RoundsPerMagazine) } ) exitWith { _turret = _x select 1 };
	} forEach magazinesAllTurrets _vehicle;

	_turret;
};

JBA_R_RemoveAmmoFromStoreWeapons =
{
	params ["_from", "_magazineType", "_rounds"];

	private _turret = [_from, _magazineType, _rounds] call JBA_FindTurretWithRounds;

	if (count _turret == 0) exitWith { INSUFFICIENT_CAPACITY };

	[_from, _turret, _magazineType, -_rounds] call JBA_AdjustTurretAmmo;

	CHANGE_SUCCESSFUL
};

JBA_S_RemoveAmmoFromStoreWeaponsResponse =
{
	params ["_from", "_result"];

	JBA_S_RemoveWeaponsResponse = _result;
};

JBA_S_RemoveAmmoFromStore =
{
	params ["_from", "_magazineType", "_rounds"];

	if (not isNil { _from getVariable "JBA_TransportCapacity" }) exitWith { [_from, _magazineType, _rounds] call JBA_S_RemoveAmmoFromStoreVirtual };

	private _turret = [_from, _magazineType, _rounds] call JBA_FindTurretWithRounds;

	if (count _turret == 0) exitWith { INSUFFICIENT_CAPACITY };

	private _turretOwner = _from;
	{
		if ((_x select 3) isEqualTo _turret && { not isNull (_x select 0) }) exitWith { _turretOwner = (_x select 0) };
	} forEach (fullCrew _from);

	private _result = [[_from, _magazineType, _rounds], "JBA_R_RemoveAmmoFromStoreWeapons", _turretOwner] call JB_fnc_remoteCall;
	if (_result select 0 == JBRC_TIMEDOUT) exitWith { INSUFFICIENT_CAPACITY };
	_result select 1;
};

JBA_S_AddAmmoToStoreVirtual =
{
	params ["_from", "_magazineType", "_rounds"];

	private _stores = _to getVariable ["JBA_S_TransportStores", []];
	private _capacity = _to getVariable ["JBA_TransportCapacity", 0];

	// Any store can take one of any item, but otherwise they are limited to their stated capacity
	if (count _stores != 0 && { ([_stores] call JBA_StoresMass) + ([_magazineType, _rounds] call JBA_WeightOfStore) > _capacity }) exitWith { INSUFFICIENT_CAPACITY };

	// Find the store to add to
	private _storeIndex = [_stores, _magazineType] call JBA_GetStoreIndex;

	if (_storeIndex == -1) then
	{
		private _store = [_magazineType, _rounds];
		_stores pushBack _store;
	}
	else
	{
		private _store = _stores select _storeIndex;
		_store set [1, (_store select 1) + _rounds];
	};

	_to setVariable ["JBA_S_TransportStores", _stores];

	CHANGE_SUCCESSFUL
};

OO_TRACE_DECL(JBA_MagazineAvailableSpace) =
{
	params ["_magazine"];

	([_magazine select 0] call JBA_RoundsPerMagazine) - (_magazine select 2);
};

JBA_R_AddAmmoToStoreWeapons =
{
	params ["_from", "_magazineType", "_rounds"];

	private _magazines = magazinesAllTurrets _from;

	private _turret = [];
	{
		if (_x select 0 == _magazineType && { ([_x] call JBA_MagazineAvailableSpace) >= _rounds } ) exitWith { _turret = _x select 1 };
	} forEach _magazines;

	if (count _turret == 0) exitWith { INSUFFICIENT_CAPACITY };

	[_from, _turret, _magazineType, _rounds] call JBA_AdjustTurretAmmo;

	CHANGE_SUCCESSFUL
};

JBA_S_AddAmmoToStoreWeaponsResponse =
{
	params ["_from", "_result"];

	JBA_S_AddWeaponsResponse = _result;
};

JBA_S_AddAmmoToStore =
{
	params ["_to", "_magazineType", "_rounds"];

	if (not isNil { _to getVariable "JBA_TransportCapacity" }) exitWith { [_to, _magazineType, _rounds] call JBA_S_AddAmmoToStoreVirtual };

	private _turret = [_to, _magazineType, _rounds] call JBA_FindTurretWithoutRounds;

	if (count _turret == 0) exitWith { INSUFFICIENT_CAPACITY };

	private _turretOwner = _to;
	{
		if ((_x select 3) isEqualTo _turret && { not isNull (_x select 0) }) exitWith { _turretOwner = (_x select 0) };
	} forEach (fullCrew _to);

	private _result = [[_to, _magazineType, _rounds], "JBA_R_AddAmmoToStoreWeapons", _turretOwner] call JB_fnc_remoteCall;
	if (_result select 0 == JBRC_TIMEDOUT) exitWith { INSUFFICIENT_CAPACITY };
	_result select 1;
};

JBA_S_TransferAmmo =
{
	params ["_caller", "_fromUnit", "_toUnit", "_magazineType", "_rounds"];

	private _roundsTransferred = 0;

	JBA_S_CS_Transfer call JB_fnc_criticalSectionEnter;

	if (([_fromUnit, _magazineType, _rounds] call JBA_S_RemoveAmmoFromStore) == CHANGE_SUCCESSFUL) then
	{
		if (([_toUnit, _magazineType, _rounds] call JBA_S_AddAmmoToStore) == CHANGE_SUCCESSFUL) then
		{
			_roundsTransferred = _rounds;
		}
		else
		{
			// Transfer failed.  Put the ammo back into the original store
			[_fromUnit, _magazineType, _rounds] call JBA_S_AddAmmoToStore;
		};
	};

	JBA_S_CS_Transfer call JB_fnc_criticalSectionLeave;

	[_caller, _fromUnit, _magazineType, -_roundsTransferred] call JBA_NotifyStoreChanged;
	[_caller, _toUnit, _magazineType, _roundsTransferred] call JBA_NotifyStoreChanged;
};

OO_TRACE_DECL(JBA_NotifyStoreChanged) =
{
	params ["_caller", "_unit", "_magazineType", "_rounds"];

	private _monitoringClients = _unit getVariable ["JBA_MonitoringClients", []];

	{
		if (_x == _unit) then { _unitNotified = true };
		if (alive _x) then
		{
			[_caller, _unit, _magazineType, _rounds] remoteExec ["JBA_C_StoreChanged", _x];
		}
		else
		{
			[_x, _unit] call JBA_S_MonitorChangesStop;
		}
	} forEach _monitoringClients;

	// If we have a character that isn't currently monitoring its store, notify it anyway
	if ((typeOf _unit) isKindOf "Man" && { !(_unit in _monitoringClients) }) then
	{
		[_caller, _unit, _magazineType, _rounds] remoteExec ["JBA_C_StoreChanged", _unit];
	};
};

JBA_C_StoreChanged =
{
	params ["_caller", "_unit", "_magazineType", "_rounds"];

	if (_caller == player) then
	{
		JBA_WaitingForTransfer = false;
	};

	disableSerialization;
	private _display = findDisplay TRANSFER_DISPLAY;

	private _control = -1;
	if (not isNull _display) then
	{
		_control = if (_unit == JBA_FromUnit) then { FROM_AMMO_LIST } else { TO_AMMO_LIST };
	};

	private _stores = _unit getVariable ["JBA_C_TransportStores", []];
	private _storeIndex = [_stores, _magazineType] call JBA_GetStoreIndex;

	if (_rounds < 0 && _storeIndex == -1) exitWith { diag_log "Attempt to remove ammunition not listed in unit stores." };

	// If the magazine type is unknown, then we are adding a new type of ammo to the store
	if (_storeIndex == -1) then
	{
		_stores pushBack [_magazineType, 0];
		_storeIndex = (count _stores) - 1;

		if (_control != -1) then
		{
			[_control, _magazineType, 0] call JBA_AddAmmoLine;
		};
	};

	// Add/remove the rounds to/from the store
	private _store = _stores select _storeIndex;
	private _roundCount = (_store select 1) + _rounds;

	if (_roundCount == 0) then
	{
		_stores deleteAt _storeIndex;
		_unit setVariable ["JBA_C_TransportStores", _stores];

		if (_control != -1) then
		{
			((findDisplay TRANSFER_DISPLAY) displayCtrl _control) lnbDeleteRow _storeIndex;
		};
	}
	else
	{
		_store set [1, _roundCount];
		_unit setVariable ["JBA_C_TransportStores", _stores];

		if (_control != -1) then
		{
			// Update the display with the new round count
			private _roundCountText = [_magazineType, _roundCount, [_magazineType] call JBA_RoundsPerMagazine] call JBA_FormatRoundCount;
			[_control, _storeIndex, _roundCountText] call JBA_UpdateRoundCount;
		};
	};

	if (not isNull _display) then
	{
		_control = if (_unit == JBA_FromUnit) then { FROM_CAPACITY } else { TO_CAPACITY };

		private _percentFilled = 0;

		private _capacity = _unit getVariable ["JBA_TransportCapacity", nil];
		if (!isNil "_capacity") then
		{
			_percentFilled = ([_stores] call JBA_StoresMass) / _capacity;
			_percentFilled = _percentFilled min 1;
		};

		(_display displayCtrl _control) progressSetPosition _percentFilled;
	};

	[_unit, _stores] call (_unit getVariable ["JBA_OnStoresChanged", {}]);
};

OO_TRACE_DECL(JBA_NotifyStoresList) =
{
	params ["_caller", "_unit"];

	private _monitoringClients = _unit getVariable ["JBA_MonitoringClients", []];

	private _stores = _unit getVariable ["JBA_S_TransportStores", []];
	{
		if (alive _x) then
		{
			[_unit, _stores] remoteExec ["JBA_C_ReceiveStoresList", _x];
		}
		else
		{
			[_x, _unit] call JBA_S_MonitorChangesStop;
		}
	} forEach _monitoringClients;

	if ((typeOf _unit) isKindOf "Man" && { !(_unit in _monitoringClients) }) then
	{
		[_unit, _stores] remoteExec ["JBA_C_ReceiveStoresList", _unit];
	};
};

OO_TRACE_DECL(JBA_S_DestroyStores) =
{
	params ["_caller", "_unit"];

	JBA_S_CS_Transfer call JB_fnc_criticalSectionEnter;

	_unit setVariable ["JBA_S_TransportStores", []];

	JBA_S_CS_Transfer call JB_fnc_criticalSectionLeave;

	[_caller, _unit] call JBA_NotifyStoresList;
};

OO_TRACE_DECL(JBA_S_DetonateStores) =
{
	params ["_unit", "_delay"];

	private _stores = _unit getVariable "JBA_S_TransportStores";
	private _magazines = _stores apply { [_x select 0, (_x select 1) / ([_x select 0] call JBA_RoundsPerMagazine)] };

	[objNull, _unit] call JBA_S_DestroyStores;

	private _explosives = [_magazines] call JB_fnc_detonateGetExplosivesEquivalent;

	if (count _explosives == 0) exitWith {};

	[_unit, _explosives, _delay] spawn
	{
		params ["_unit", "_explosives", "_delay"];

		sleep _delay;

		// Put the largest explosives at the center and bounding corners of the unit
		private _positions = (boundingBoxReal _unit + (boundingBoxReal _unit apply { _x set [0, -(_x select 0)]; _x })) apply { _unit modelToWorld _x };
		private _chains = [[[_explosives deleteAt 0], _unit modelToWorld [0,0,0]]];
		while { count _positions > 0 && count _explosives > 0 } do
		{
			_chains pushBack [[_explosives deleteAt 0], _positions deleteAt (floor random count _positions)];
		};

		// Pile on randomly onto each of the corners with whatever explosives we have left
		private _chain = [];
		while { count _explosives > 0 } do
		{
			_chain = selectRandom _chains;
			(_chain select 0) pushBack (_explosives deleteAt (floor random count _explosives));
		};

		// Set off each chain
		{ [_x select 0, _x select 1, count (_x select 0)] call JB_fnc_detonateExplosives } forEach _chains;
	};
};

OO_TRACE_DECL(JBA_PlayerIsTransportingAmmo) =
{
	params ["_player"];

	not isNull ([_player] call JBA_PlayerAmmoSource)
};

JBA_PlayerAmmoSource =
{
	params ["_player"];

	private _ammoBox = [_player] call JB_CO_CarriedObject;

	if (not isNull _ammoBox && { [_ammoBox] call JBA_IsAmmoBox }) exitWith { _ammoBox };

	private _trolley = [_player] call JBAT_PlayerTrolley;

	if (not isNull _trolley) exitWith { _trolley };

	objNull
};

if (isServer) then
{
	if (isNil "JBA_S_CS_Transfer") then
	{
		JBA_S_CS_Transfer = call JB_fnc_criticalSectionCreate;
		JBA_S_CS_Monitor = call JB_fnc_criticalSectionCreate;
	};
};