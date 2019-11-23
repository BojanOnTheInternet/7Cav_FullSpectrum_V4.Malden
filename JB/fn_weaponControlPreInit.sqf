// JB_WC_Turrets [turret-spec, ...]
// turret-spec [turret-path, turret-name, [weapon-spec, ...]]
// weapon-spec [weapon-type, weapon-name]

JB_WC_ChangeWeapon =
{
	params ["_vehicle", "_turretIndex", "_weaponIndex", "_enable"];

	private _turret = (_vehicle getVariable ["JB_WC_Turrets", []]) select _turretIndex;

	if (_enable) then
	{
		_vehicle addWeaponTurret [_turret select 2 select _weaponIndex select 0, _turret select 0];
	}
	else
	{
		_vehicle removeWeaponTurret [_turret select 2 select _weaponIndex select 0, _turret select 0];
	};
};

JB_WC_ShowMenuCondition =
{
	params ["_vehicle"];

	if (vehicle player != _vehicle) exitWith { false };

	if (not (lifeState player in ["HEALTHY", "INJURED"])) exitWith { false };

	private _condition = _vehicle getVariable ["JB_WC_Condition", { (_this select 0) == effectiveCommander (_this select 1) }];

	[player, _vehicle] call _condition
};

JB_WC_EnableWeapon =
{
	private _message = _this call JB_fnc_weaponControlEnableWeapon;
	if (_message != "") then { titleText [_message, "plain down", 0.3] };
};

JB_WC_ShowMenu =
{
	params ["_vehicle"];

	JB_WC_Menu = [["Weapon control", true]];

	private _key = 1;
	private _turret = [];
	private _weapons = [];
	private _weaponEnabled = false;
	private _action = "";
	{
		_turret = _x;
		_turretPath = _turret select 0;

		_weapons = _vehicle weaponsTurret (_turret select 0);
		{
			_weaponEnabled = (_x select 0) in _weapons;
			_action = if (_weaponEnabled) then { "Disable " } else { "Enable "};

			_key = _key + 1;

			//BUG: Use of the single quote version "' s" will freak out the parser
			JB_WC_Menu pushBack [_action + (_turret select 1) + '''s ' + (_x select 1), [_key], "", -5, [["expression", format ["[vehicle player, %1, ""%2"", %3] call JB_WC_EnableWeapon", _turretPath, _x select 0, not _weaponEnabled]]], "1", "1"];
		} forEach (_x select 2);
	} forEach (_vehicle getVariable ["JB_WC_Turrets", []]);

	showCommandingMenu "";
	showCommandingMenu "#USER:JB_WC_Menu";
};

JB_WC_C_InitializeVehicle =
{
	params ["_vehicle"];

	_vehicle addAction ["Weapon control", { [vehicle player] call JB_WC_ShowMenu }, [], 0, false, true, "", "[_target] call JB_WC_ShowMenuCondition"];
};

if (not isServer && hasInterface) exitWith {};

JB_WC_Turrets =
{
	params ["_configPath", "_turretPath"];

	private _turrets = [];
	{
		_turrets pushBack [_x, _turretPath + [_forEachIndex]];
		_turrets append ([_x, _turretPath + [_forEachIndex]] call JB_WC_Turrets);
	} forEach ("true" configClasses (_configPath >> "Turrets"));

	_turrets
};

JB_WC_InitializeVehicle =
{
	params ["_vehicle", "_condition", "_controlDefensiveWeapons"];

	private _turrets = [configFile >> "CfgVehicles" >> typeOf _vehicle, []] call JB_WC_Turrets;
	_turrets = _turrets apply { [_x select 1, getText (_x select 0 >> "gunnerName")] };
	_turrets pushBack [[-1], if (_vehicle isKindOf "Air") then { "Pilot" } else { "Driver" }];
	_turrets = _turrets apply { [_x select 0, _x select 1, (_vehicle weaponsTurret (_x select 0)) select { _controlDefensiveWeapons || { [_x] call JB_fnc_isOffensiveWeapon } }] };
	_turrets = _turrets select { count (_x select 2) > 0 };

	{
		_x set [2, (_x select 2) apply { [_x, getText (configFile >> "CfgWeapons" >> _x >> "displayName")] }];
	} forEach _turrets;

	_vehicle setVariable ["JB_WC_Turrets", _turrets, true]; //JIP

	if (not isNil "_condition") then { _vehicle setVariable ["JB_WC_Condition", _condition, true] }; //JIP

	[_vehicle] remoteExec ["JB_WC_C_InitializeVehicle", 0, true]; //JIP
};

JB_WC_SendToTurret =
{
	params ["_vehicle", "_turretPath", "_arguments", "_function"];
	
	[_arguments, _function] remoteExec ["call", _vehicle turretOwner _turretPath];
};
