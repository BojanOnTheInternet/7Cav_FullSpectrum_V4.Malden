// Distance medics will be able to see incapacitated soldiers and other medics in the 3D view
#define MEDIC_VISION_RANGE 500
// Distance technicians will be able to see damaged vehicles and other technicians in the 3D view
#define REPAIR_VISION_RANGE 500

HUD_Enabled = false;

HUD_Medic_DrawIcon =
{
	params ["_unit", "_color"];

	private _distance = round (player distance _unit);
	if (_distance < MEDIC_VISION_RANGE) then
	{
		_color set [3, 1.1 - _distance / MEDIC_VISION_RANGE];

		private _position = visiblePositionASL _unit;
		_position set [2, (_unit modelToWorld [0,0,0]) select 2];

		private _label = format["%1  %2m", name _unit, _distance];

		drawIcon3D [[_unit] call MAP_IconType_Individual, _color, _position, 0.75, 0.75, 0, _label, 0, 0.03];
	};
};

HUD_Medic_Draw =
{
	if (not HUD_Enabled) exitWith {};

	{
		if (_x != player) then
		{
			if (lifeState _x == "INCAPACITATED") then
			{
				[_x, [1.0, 0.0, 0.0, 1.0]] call HUD_Medic_DrawIcon;
			}
			else
			{
				if (_x getUnitTrait "medic") then
				{
					[_x, [1.0, 1.0, 1.0, 1.0]] call HUD_Medic_DrawIcon;
				}
			}
		};
	} foreach (allPlayers select { not (_x isKindOf "HeadlessClient_F") });
};

HUD_Medic_Initialize =
{
	addMissionEventHandler ["Draw3D", HUD_Medic_Draw];
};

HUD_Repair_DrawIcon =
{
	params ["_unit", "_color"];

	private _distance = round (player distance _unit);
	if (_distance < REPAIR_VISION_RANGE) then
	{
		_color set [3, 1.1 - _distance / REPAIR_VISION_RANGE];

		private _position = visiblePositionASL _unit;
		_position set [2, (_unit modelToWorld [0,0,0]) select 2];

		private _type = getText (configFile >> "CfgVehicles" >> typeOf _unit >> "displayName");
		private _label = format["%1  %2m", _type, _distance];

		drawIcon3D ["a3\ui_f\data\IGUI\Cfg\Cursors\iconRepairVehicle_ca.paa", _color, _position, 0.75, 0.75, 0, _label, 0, 0.03];
	};
};

HUD_Repair_Draw =
{
	if (not HUD_Enabled) exitWith {};

	{
		if (_x != player) then
		{
			if (_x isKindOf "B_soldier_repair_F") then
			{
				[_x, [1.0, 1.0, 1.0, 1.0]] call HUD_Repair_DrawIcon;
			};
		};
	} foreach (allPlayers select { not (_x isKindOf "HeadlessClient_F") });

	{
		switch (true) do
		{
			case (damage _x > 0.66):
			{
				[_x, [1.0, 0.0, 0.0, 1.0]] call HUD_Repair_DrawIcon;
			};
			case (damage _x > 0.33):
			{
				[_x, [1.0, 0.5, 0.0, 1.0]] call HUD_Repair_DrawIcon;
			};
			case (damage _x > 0.01):
			{
				[_x, [1.0, 1.0, 0.0, 1.0]] call HUD_Repair_DrawIcon;
			};
		};
	} forEach ((player nearEntities [["LandVehicle", "Ship", "Air"], REPAIR_VISION_RANGE]) select { side _x in [west, civilian] });
};

HUD_Repair_Initialize =
{
	addMissionEventHandler ["Draw3D", HUD_Repair_Draw];
};

HUDTESTCallback =
{
	params ["_descriptor"];

	_descriptor params ["_position", "_key", "_color", "_minDistance", "_maxDistance", "_sizeInMeters", "_font"];

	private _text = "AO Transport (en route)";

	private _entities = _position nearEntities [["Helicopter"], 5];
	if (count _entities > 0 && { count ((_entities select 0) getVariable ["JB_AT_Aircraft_Routes", []]) > 0 }) then { _text = "AO Transport (ready)" };

	[_position, _text, _color, _minDistance, _maxDistance, _sizeInMeters, _font]
};

HUD_Names =
[
	["Microphone", ["\a3\ui_f\data\GUI\Rsc\RscDisplayArsenal\voice_ca.paa", 32]],
	["Radio", ["\a3\ui_f\data\GUI\Cfg\CommunicationMenu\call_ca.paa", 32]],
	["Weapon", ["\a3\ui_f\data\IGUI\cfg\Actions\Obsolete\ui_action_gear_ca.paa", 32]],
	["VehicleRepair", ["\a3\ui_f\data\IGUI\cfg\Cursors\iconRepairVehicle_ca.paa", 32]],
	["VehicleFuel", ["\a3\ui_f\data\IGUI\cfg\Cursors\iconRefuelAt_ca.paa", 32]],
	["Base", ["\a3\ui_f\data\IGUI\cfg\IslandMap\iconSensor_ca.paa", 32]],
	["Move", ["\a3\ui_f\data\igui\cfg\simpleTasks\types\move_ca.paa", 32]],
	["Move1", ["\a3\ui_f\data\igui\cfg\simpleTasks\types\move1_ca.paa", 32]],
	["Move2", ["\a3\ui_f\data\igui\cfg\simpleTasks\types\move2_ca.paa", 32]],
	["Move3", ["\a3\ui_f\data\igui\cfg\simpleTasks\types\move3_ca.paa", 32]],
	["Move4", ["\a3\ui_f\data\igui\cfg\simpleTasks\types\move4_ca.paa", 32]],
	["Move5", ["\a3\ui_f\data\igui\cfg\simpleTasks\types\move4_ca.paa", 32]],
	["HUDTESTCallback", [HUDTESTCallback, [], 90210]]
];

// UserTexture_1x2_F
// UserTexture10m_F
// UserTexture1m_F

// Icon descriptor:
// [position, string-or-array, current-color, min-distance, max-distance, size-in-meters, font]
// Array form is either [icon, size] or [code, ...].  The code will be called and is expected to return a non-code icon descriptor.

#define FADE_DURATION 0.5

HUD_DrawIcon =
{
	params ["_descriptor"];

	if (typeName (_descriptor select 1) == "ARRAY" && { typeName (_descriptor select 1 select 0) == "CODE" }) then
	{
		_descriptor = [_descriptor] call (_descriptor select 1 select 0);
	};

	private _position = _descriptor select 0;

	private _distance = player distance _position;
	private _color = _descriptor select 2;
	private _alpha = _color select 3;

	if (_distance >= _descriptor select 3 && { _distance <= _descriptor select 4 }) then
	{
		_alpha = (_alpha + (1 / diag_fps) / FADE_DURATION) min 1.0;
		_color set [3, _alpha];
		_descriptor set [2, _color];
	}
	else
	{
		if (_alpha > 0.0) then
		{
			_alpha = (_alpha - (1 / diag_fps) / FADE_DURATION) max 0.0;
			_color set [3, _alpha];
			_descriptor set [2, _color];
		};
	};

	if (_alpha > 0.0) then
	{
		private _v1 = worldToScreen _position;
		if (count _v1 > 0) then
		{
			_v1 set [2, 0];

			private _right = vectorNormalized ((getCameraViewDirection player) vectorCrossProduct [0,0,1]);

			private _v2 = worldToScreen (_position vectorAdd (_right vectorMultiply (_descriptor select 5)));
			if (count _v2 > 0) then
			{
				_v2 set [2, 0];

				private _size = vectorMagnitude (_v1 vectorDiff _v2);
				if ((_descriptor select 1) isEqualType "") then
				{
					drawIcon3D ["", _color, _position, 0.0, 0.0, 0, _descriptor select 1, 1, _size, _descriptor select 6];
				}
				else
				{
					_size = (_size * (getResolution select 3) / safeZoneH) / (_descriptor select 1 select 1);
					drawIcon3D [_descriptor select 1 select 0, _color, _position, _size, _size, 0];
				};
			};
		};
	};
};

HUD_GetMarkerIcons =
{
	params ["_prefix", "_icons"]; // Prefix must be of format "string_string_", e.g. "HUD_Greeting1_Pilot_Hello"

	private _pieces = [];
	private _descriptor = [];
	private _key = "";
	private _color = [];
	private _minDistance = 0;
	private _maxDistance = 0;
	private _sizeInMeters = 0;
	private _named = [];

	// Marker format "<prefix><name>_<label/icon>_<min-distance>_<max-distance>_<size-in-meters>_<font-family>"
	private _newIcons = allMapMarkers select { _x find "HUD_" == 0 } apply
		{
			_pieces = _x splitString "_";

			if (count _pieces < 3) then
			{
				[]
			}
			else
			{
				_pieces params ["_unused", "_name", "_prefixes", "_key", ["_minDistance", "10", [""]], ["_maxDistance", "100", [""]], ["_sizeInMeters", "2", [""]], ["_font", "PuristaLight", [""]]];

				_prefixes = _prefixes splitString ",";
				if (not (_prefix in _prefixes)) then
				{
					[]
				}
				else
				{
					_named = [HUD_Names, _key] call BIS_fnc_getFromPairs;
					if (not isNil "_named") then { _key = +_named };

					_color = getArray (configFile >> "CfgMarkerColors" >> getMarkerColor _x >> "color");
					_color = _color apply { if (_x isEqualType 0) then { _x } else { call compile _x } };

					_minDistance = parseNumber _minDistance;
					_maxDistance = parseNumber _maxDistance;
					_sizeInMeters = parseNumber _sizeInMeters;

					[(getMarkerPos _x) vectorAdd [0, 0, _sizeInMeters / 2], _key, _color, _minDistance, _maxDistance, _sizeInMeters, _font]
				};
			};
		};

	_icons append (_newIcons select { count _x > 0 });
};

HUD_Pilot_Draw =
{
	if (not HUD_Enabled) exitWith {};

	{
		[_x] call HUD_DrawIcon;
	} forEach HUD_Pilot_Icons;
};

HUD_Pilot_Initialize =
{
	HUD_Pilot_Icons = [];
	["Pilot", HUD_Pilot_Icons] call HUD_GetMarkerIcons;

	addMissionEventHandler ["Draw3D", HUD_Pilot_Draw];
};

HUD_Infantry_Draw =
{
	if (not HUD_Enabled) exitWith {};

	{
		[_x] call HUD_DrawIcon;
	} forEach HUD_Infantry_Icons;
};

HUD_Infantry_Initialize =
{
	HUD_Infantry_Icons = [];
	["Infantry", HUD_Infantry_Icons] call HUD_GetMarkerIcons;

	addMissionEventHandler ["Draw3D", HUD_Infantry_Draw];

//	[] call HUD_VehicleEntry_Initialize;
};

HUD_SpecOps_Draw =
{
	if (not HUD_Enabled) exitWith {};

	{
		[_x] call HUD_DrawIcon;
	} forEach HUD_SpecOps_Icons;
};

HUD_SpecOps_Initialize =
{
	HUD_SpecOps_Icons = [];
	["SpecOps", HUD_SpecOps_Icons] call HUD_GetMarkerIcons;

	addMissionEventHandler ["Draw3D", HUD_SpecOps_Draw];

//	[] call HUD_VehicleEntry_Initialize;
};

HUD_Armor_Draw =
{
	if (not HUD_Enabled) exitWith {};

	{
		[_x] call HUD_DrawIcon;
	} forEach HUD_Armor_Icons;
};

HUD_Armor_Initialize =
{
	HUD_Armor_Icons = [];
	["Armor", HUD_Armor_Icons] call HUD_GetMarkerIcons;

	addMissionEventHandler ["Draw3D", HUD_Armor_Draw];
};

HUD_VehicleEntry_Stations = ["driver", "codriver", "gunner", "cargo", "turret"];

HUD_VehicleEntry_Draw =
{
	if (not HUD_Enabled) exitWith {};

	private _vehicle = objNull;
	private _savePosition = [];
	{
		_vehicle = _x select 0;
		{
			_savePosition = _x select 0;
			_x set [0, _vehicle modelToWorld _savePosition];
			[_x] call HUD_DrawIcon;
			_x set [0, _savePosition];
		} forEach (_x select 1)
	} forEach HUD_VehicleEntry_Icons;
};

HUD_VehicleEntry_Initialize =
{
	HUD_VehicleEntry_Icons = [];

	addMissionEventHandler ["Draw3D", HUD_VehicleEntry_Draw];

	[] spawn
	{
		private _newVehicles = [];
		private _vehicle = objNull;
		private _icons = [];
		private _station = "";
		private _texture = "";
		private _position = [];

		while { true } do
		{
			sleep 1;

			if (vehicle player != player) then
			{
				HUD_VehicleEntry_Icons = [];
			}
			else
			{
				_newVehicles = player nearEntities [["LandVehicle", "Ship", "Air"], 30];

				// Remove old vehicles that are out of range
				for "_i" from count HUD_VehicleEntry_Icons - 1 to 0 step -1 do
				{
					if (not ((HUD_VehicleEntry_Icons select _i select 0) in _newVehicles)) then { HUD_VehicleEntry_Icons deleteAt _i };
				};

				// Add new vehicles that are in range
				for "_i" from count _newVehicles - 1 to 0 step -1 do
				{
					_vehicle = _newVehicles select _i;

					if (count (HUD_VehicleEntry_Icons select { _x select 0 == _vehicle }) == 0) then
					{	
						_icons = [];

						{
							_station = _x select 0;
							if (_station isEqualType []) then
							{
								_station = _station select 0;
							};

							_station = toLower _station;
							switch (_station) do
							{
								case "driver":
								{
									_texture = if (_vehicle isKindOf "Air") then { ["a3\ui_f\data\IGUI\Cfg\Actions\getinpilot_ca.paa", 64] } else { ["a3\ui_f\data\IGUI\Cfg\Actions\getindriver_ca.paa", 64] };
								};
								case "commander":
								{
									_texture = ["a3\ui_f\data\IGUI\Cfg\Actions\getincommander_ca.paa", 64];
								};
								case "copilot";
								case "loadmaster";
								case "gunner":
								{
									_texture = ["a3\ui_f\data\IGUI\Cfg\Actions\getingunner_ca.paa", 64];
								};
								default
								{
									if ((_x select 0) isEqualType []) then
									{
										_texture = ["a3\ui_f\data\IGUI\Cfg\Actions\getingunner_ca.paa", 64];
									}
									else
									{
										_texture = ["a3\ui_f\data\IGUI\Cfg\Actions\getincargo_ca.paa", 64];
									};
								};
							};

							_position = ((_x select 1 select 0 select 0) vectorAdd (_x select 1 select 0 select 1)) vectorMultiply 0.5;
							_position = _position vectorAdd [0, 0, 1.6];

							_icons pushBack [_position, _texture, [0.8,0.8,0.8,0], 0, 5, 0.5, ""];
						} forEach ([_vehicle, HUD_VehicleEntry_Stations, false] call JB_fnc_getInPoints);

						HUD_VehicleEntry_Icons pushBack [_vehicle, _icons];
					};
				};
			};
		};
	};
};

[] spawn
{
	waitUntil { sleep 1; not isNull (findDisplay 46) };

	(findDisplay 46) displayAddEventHandler ["KeyDown",
		{
			params ["_control", "_key", "_isShift", "_isControl", "_isAlt"];

			private _override = false;

			switch (_key) do
			{
				case 0x16: // U
				{
					if (_isShift && _isControl) then
					{
						_override = true;

						HUD_Enabled = not HUD_Enabled;
					};
				};
			};

			_override;
		}];
};
