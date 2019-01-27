#define MAP_SCALE_NO_TEXT 0.18

MAP_IconColor =
{
	params ["_unit"];

	private _a = 0.5;

	if ((group _unit) == (group player)) then { _a = 1.0 };

	if (lifeState _unit == "INCAPACITATED") exitWith { [1.0, 0.4, 0, _a] };
	
	if (side _unit == east) exitWith { [0.5, 0, 0, _a] };
	if (side _unit == west) exitWith { [0, 0.3, 0.6, _a] };
	if (side _unit == independent) exitWith { [0, 0.5, 0, _a] };
	if (side _unit == civilian) exitWith { [0.4, 0, 0.5, _a] };

	[0.7, 0.6, 0, _a]
};

/*MAP_IconType_Individual =
{
	params ["_unit"];

	if (not isNull attachedTo _unit && { (typeOf _unit) find "Land_Pod_Heli_Transport_04_" == 0 }) exitWith { "" };

	getText (configFile >> "CfgVehicles" >> typeOf _unit >> "icon")
};

MAP_IconSize =
{
	params ["_control", "_unit"];

	if (_unit isKindOf "Man") exitWith { 23 };
	if (_unit isKindOf "Ship") exitWith { 26 * ((0.007 / ctrlMapScale _control) max 0.5) };

	(boundingBoxReal _unit select 1 select 1) * 2 * ((0.020 / ctrlMapScale _control) max 0.5)
};

MAP_UnitType =
{
	params ["_unit"];

	private _unitType = _unit getVariable "MAP_UnitType";

	if (not isNil "_unitType") exitWith { _unitType };

	if (isPlayer _unit && { (typeOf _unit) isKindOf "Man" }) then
	{
		_unitType = roleDescription _unit;

		private _paren = _unitType find "(";
		if (_paren >= 0) then
		{
			_unitType = _unitType select [0, _paren];
			_unitType = [_unitType, "end"] call JB_fnc_trimWhitespace;
		};
	}
	else
	{
		_unitType = getText (configFile >> "CfgVehicles" >> typeOf _unit >> "displayName");
	};

	_unit setVariable ["MAP_UnitType", _unitType];

	_unitType
};

MAP_IconText_Individual =
{
	params ["_control", "_unit"];

	if (ctrlMapScale _control > MAP_SCALE_NO_TEXT) exitWith { "" };

	if ((typeOf _unit) isKindOf "Man") exitWith
	{
		if (isPlayer _unit || { isPlayer leader _unit }) then
		{
			name _unit;
		}
		else
		{
			""
		};
	};

	if (side _unit != playerSide && { { isPlayer _x } count crew _unit == 0 }) exitWith { "" };
	if (not isNull attachedTo _unit && { (typeOf _unit) find "Land_Pod_Heli_Transport_04_" == 0 }) exitWith { "" };

	if (unitIsUAV _unit) exitWith
	{
		if (not isUavConnected _unit) then
		{
			""
		}
		else
		{
			name ((UAVControl _unit) select 0);
		};
	};

	private _crew = (crew _unit) select { isPlayer _x };
	private _representative = effectiveCommander _unit;

	if (_unit isKindOf "O_Heli_Transport_04_F") then
	{
		{
			if ((typeOf _x) find "Land_Pod_Heli_Transport_04_" == 0) exitWith
			{
				_crew append ((crew _x) select { isPlayer _x });
				if (isNull _representative) then { _representative = effectiveCommander _x };
			};
		} forEach attachedObjects _unit;
	};

	private _additionsText = if (count _crew == 1) then { "" } else { format [" + %1", (count _crew) - 1] };

	format ["%1%2", name _representative, _additionsText];
};

MAP_Format_Individual =
{
	params ["_control", "_unit"];
	
	_iconType = [_unit] call MAP_IconType_Individual;

	if (_iconType == "") exitWith { [] };

	_iconColor = [_unit] call MAP_IconColor;
	_iconPosition = getPosASL _unit;
	_iconSize = [_control, _unit] call MAP_IconSize;
	_iconDirection = getDir _unit;
	_text = [_control, _unit] call MAP_IconText_Individual;

	[_iconType, _iconColor, _iconPosition, _iconSize, _iconSize, _iconDirection, _text]
};

MAP_IconType_Group =
{
	params ["_unit"];

	if (not (_unit isKindOf "Man")) then { _unit = effectiveCommander _unit };

	if (isNull _unit) exitWith { "" };

	private _iconType = "";

	switch (_unit getVariable ["SPM_BranchOfService", ""]) do
	{
		case "infantry":
			{
				_iconType = "\a3\ui_f\data\map\markers\nato\b_inf";
				switch (true) do
				{
					case (vehicle _unit isKindOf "Car"): { _iconType = "\a3\ui_f\data\map\markers\nato\b_motor_inf" };
					case (vehicle _unit isKindOf "Tank"): { _iconType = "\a3\ui_f\data\map\markers\nato\b_mech_inf" };
				};
			};
		case "air":
			{
				_iconType = "\a3\ui_f\data\map\markers\nato\b_plane";
				switch (true) do
				{
					case (vehicle _unit isKindOf "Helicopter"): { _iconType = "\a3\ui_f\data\map\markers\nato\b_air" };
				};
			};
		case "special-forces": { _iconType = "\a3\ui_f\data\map\markers\nato\b_recon" };
		case "armor": { _iconType = "\a3\ui_f\data\map\markers\nato\b_armor" };
		case "combat-support":
			{
				_iconType = "\a3\ui_f\data\map\markers\nato\b_plane";
				switch (true) do
				{
					case (vehicle _unit isKindOf "Helicopter"): { _iconType = "\a3\ui_f\data\map\markers\nato\b_air" };
					case (vehicle _unit isKindOf "StaticMortar"): { _iconType = "\a3\ui_f\data\map\markers\nato\b_mortar" };
				};
			};
		case "support": { _iconType = "\a3\ui_f\data\map\markers\nato\b_support" };
		default { _iconType = "\a3\ui_f\data\map\markers\nato\b_unknown" }
	};

	_iconType
};

MAP_IconText_Group =
{
	params ["_control", "_unit"];

	if (ctrlMapScale _control > MAP_SCALE_NO_TEXT) exitWith { "" };

	groupId group _unit
};

MAP_Format_Group =
{
	params ["_control", "_unit"];

	if (not isFormationLeader _unit) exitWith { [] };
	
	_iconType = [_unit] call MAP_IconType_Group;

	if (_iconType == "") exitWith { [] };

	_iconColor = [_unit] call MAP_IconColor;
	_iconPosition = getPosASL _unit;
	_iconSize = 30;
	_iconDirection = 0;
	_text = if (side _unit getFriend side player < 0.6) then { "" } else { [_control, _unit] call MAP_IconText_Group };

	[_iconType, _iconColor, _iconPosition, _iconSize, _iconSize, _iconDirection, _text]
};

MAP_IconText_ATCAircraft =
{
	params ["_control", "_unit"];

	private _flightLevel = round (((getPosASL _unit) select 2) / 100);

	if (not isEngineOn _unit) exitWith { format ["FL%1", _flightLevel] };

	private _callSign = if (vehicleVarName _unit == "") then { "" } else { " " + (((vehicleVarName _unit) splitString "_") joinString " ") };
	private _iconText = [_control, _unit] call MAP_IconText_Individual;
	private _separator = if (_iconText == "") then { "" } else { ", " };
	
	format ["FL%1%2%3%4", _flightLevel, _callSign, _separator, _iconText]
};

MAP_Format_ATC =
{
	params ["_control", "_unit"];

	_iconType = [_unit] call MAP_IconType_Individual;

	if (_iconType == "") exitWith { [] };

	_iconColor = [_unit] call MAP_IconColor;
	_iconPosition = getPosASL _unit;
	_iconSize = [_control, _unit] call MAP_IconSize;
	_iconDirection = getDir _unit;
	_text = [_control, _unit] call MAP_IconText_ATCAircraft;

	[_iconType, _iconColor, _iconPosition, _iconSize, _iconSize, _iconDirection, _text]
};

MAP_DrawMap =
{
	params ["_control", "_targets", "_formatter"];

	private _shadow = 1;
	private _textSize = 0.05;
	private _textFont = "puristaMedium";
	private _textPlacement = "right";
	
	{
		_format = [_control, _x] call _formatter;
		if (count _format > 0) then
		{
			_control drawIcon (_format + [_shadow, _textSize, _textFont, _textPlacement])
		};
	} forEach _targets;
};*/

MAP_DrawnRectangles = [];
MAP_DrawnEllipses = [];

/*MAP_DrawMap_Shapes =
{
	params ["_control"];

	{
		if (count _x > 0) then { _control drawRectangle _x };
	} forEach MAP_DrawnRectangles;

	{
		if (count _x > 0) then { _control drawEllipse _x };
	} forEach MAP_DrawnEllipses;
};

MAP_DrawMap_Decals =
{
	params ["_control"];

	if (not isNil "CLIENT_Decals") then
	{
		private _size = 0;
		{
			_size = (_x select 2) * (0.02 / ctrlMapScale _control);
			_control drawIcon [_x select 3, [1,1,1,1], _x select 0, _size, _size, _x select 1, "", 0];
		} forEach CLIENT_Decals;
	};
};

MAP_DrawMap_General =
{
	params ["_control", "_senseRange", "_drawRange", "_unitType"];

	_unitType = ["individual", "group"] select _unitType;

	[_control] call MAP_DrawMap_Shapes;
	[_control] call MAP_DrawMap_Decals;

	private _targets = [];

	if (_senseRange > 0) then { _targets append (player nearTargets _senseRange select { _x select 2 != playerSide && { (_x select 4) isKindOf "AllVehicles" } } apply { _x select 4 }) };

	private _formatter = {};

	switch (_unitType) do
	{
		case "individual":
		{
			{
				{
					_targets pushBackUnique vehicle _x;
				} forEach units group _x;
			} forEach (allPlayers select { not (_x isKindOf "HeadlessClient_F") });

			{
				_targets pushBackUnique _x;
			} forEach allUnitsUAV;

			_formatter = MAP_Format_Individual;
		};

		case "group":
		{
			{
				{
					_targets pushBackUnique vehicle _x;
				} forEach units group _x;
			} forEach (allPlayers select { isFormationLeader _x });

			_formatter = MAP_Format_Group;
		};
	};

	// Restrict display of targets by distance, if specified
	if (_drawRange != -1) then { _targets = _targets select { player distance2D _x <= _drawRange } };

	[_control, _targets, _formatter] call MAP_DrawMap;
};
*/
MAP_CreateMissionObjectRectangles =
{
	params [["_typeFilter", ["all", true], [[]]]];

	private _texture = "#(rgb,8,8,3)color(0.5,0.5,0.5,1.0)";

	_addObjectRectangle =
	{
		params ["_object"];

		_boundingBox = boundingBoxReal _object;
		_corner1 = _boundingBox select 0;
		_corner2 = _boundingBox select 1;
		_width = (_corner2 select 0) - (_corner1 select 0);
		_length = (_corner2 select 1) - (_corner1 select 1);

		MAP_DrawnRectangles pushBack [getPos _object, _width / 2, _length / 2, getDir _object, [1,1,1,1], _texture];
	};

	{
		if ((_x getVariable ["MAP_Show", true]) && { [typeOf _x, _typeFilter] call JB_fnc_passesTypeFilter }) then
		{
			[_x] call _addObjectRectangle;
		};
	} forEach (allMissionObjects "");
};

MAP_InitializeGeneral =
{
	[] spawn
	{
		[[["Land_NavigLight", false], ["Land_LandMark_F", false], ["HouseBase", true], ["HBarrier_base_F", true], ["Land_Razorwire_F", true], ["All", false]]] call MAP_CreateMissionObjectRectangles;
	};

	[{ [_this select 0, ["MapSenseEnemyRange"] call Params_GetParamValue, -1, ["MapType"] call Params_GetParamValue] call MAP_DrawMap_General }, { [_this select 0, 0, 300, ["MapType"] call Params_GetParamValue] call MAP_DrawMap_General }] call JBMAP_InitializeOverlay;
};

MAP_DrawMap_ATC =
{
	params ["_control"];

	[_control] call MAP_DrawMap_Shapes;
	[_control] call MAP_DrawMap_Decals;

	private _aircraft = allUnits select { _x == driver vehicle _x && { vehicle _x isKindOf "Air" } } apply { vehicle _x };

	private _targets = _aircraft select { side driver _x == playerSide };
	_targets append (_aircraft select { side driver _x != playerSide && { ((getPosATL _x) select 2) / 10.0 > (_x distance2D MAP_ATCRadarPosition) / 1000.0 } });
	_targets append (allPlayers select { _x == driver vehicle _x && { vehicle _x isKindOf "Air" } && { not (_x isKindOf "HeadlessClient_F") } } apply { vehicle _x });
	_targets append (allUnitsUAV select { _x isKindOf "Air" });

	[_control, _targets, MAP_Format_ATCAircraft] call MAP_DrawMap; // Draw the known aircraft

	[_control, [vehicle player], MAP_Format_Individual] call MAP_DrawMap; // Draw the player
};

MAP_InitializeATC =
{
	MAP_ATCRadarPosition = getPos Headquarters;

	[] spawn
	{
		[[["Land_NavigLight", false], ["Land_LandMark_F", false], ["HouseBase", true], ["HBarrier_base_F", true], ["Land_Razorwire_F", true], ["All", false]]] call MAP_CreateMissionObjectRectangles;
	};

	[{ [_this select 0] call MAP_DrawMap_ATC }, { [_this select 0, 0, 300, "individual"] call MAP_DrawMap_General }] call JBMAP_InitializeOverlay;
}