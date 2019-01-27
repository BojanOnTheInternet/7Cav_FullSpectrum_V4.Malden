#define THERMAL_OPTICS_MSG "Thermal optics restriction in place.  %1 removed."
#define SNIPER_OPTICS_MSG "Only sniper team members may use this item. %1 removed."
#define UAV_RESTRICTION_MSG "Only UAV operators may use this item.  %1 removed."
#define EOD_GEAR_MSG "Only EOD team members may use this item.  %1 removed."
#define ATC_GEAR_MSG "ATC may not use any gear.  %1 removed."
#define JTAC_MAGAZINES_MSG "JTAC may not load this magazine type.  %1 removed."
#define UNAVAILABLE_ITEMS_MSG "Item is not available.  %1 removed."

GR_Name_Matches_Pattern =
{
	params ["_name", "_pattern"];

	private _matchesPattern = false;

	private _wildcard = _pattern find "*";
	if (_wildcard == -1) then
	{
		_matchesPattern = (_name == _pattern);
	}
	else
	{
		if (count _name >= _wildcard) then
		{
			_matchesPattern = (_name select [0, _wildcard]) == (_pattern select [0, _wildcard]);
		}
	};

	_matchesPattern
};

GR_DropGear =
{
	params ["_type"];

	if (_type == "") exitWith {};

	private _holders = player nearobjects ["GroundWeaponHolder", 2];
	private _holder = if (count _holders > 0) then { _holders select 0 } else { createVehicle ["GroundWeaponHolder", getPos player, [], 0, "can_collide"] };

	switch (true) do
	{
		case (_type isKindOf ["ItemCore", configFile >> "CfgWeapons"]): { _holder addItemCargoGlobal [_type, 1] };
		case (_type isKindOf ["Default", configFile >> "CfgWeapons"]): { _holder addWeaponCargoGlobal [_type, 1] };
		case (_type isKindOf ["Default", configFile >> "CfgMagazines"]): { _holder addMagazineCargoGlobal [_type, 1] };
		case (_type isKindOf ["Bag_Base", configFile >> "CfgVehicles"]): { _holder addBackpackCargoGlobal [_type, 1] };
	};
};

GR_IsConfiguringGear =
{
	// Check to see if Arsenal or VAS is open
	not isNull (uiNamespace getVariable ["BIS_fnc_arsenal_cam", objNull]) || { not isNull findDisplay 2500 }
};

GR_WeaponsRestriction =
{
	params ["_restrictions", "_message"];

	private _p = "";
	private _violations = [];

	private _weapons = weapons player;

	{
		_p = _x;
		{
			if ([_x, _p] call GR_Name_Matches_Pattern) then
			{
				_violations pushBack (format [_message, [_x, "CfgWeapons"] call JB_fnc_displayName]);
				player removeWeapon _x;
				if (not ([] call GR_IsConfiguringGear)) then { [_x] call GR_DropGear };
			}
		} foreach _weapons;
	} foreach _restrictions;

	_violations
};

// [[weapon-type,true/false,"Explanation"], [weapon-type,true/false,"Explanation"], [], ..., ["Default", false, "Explanation"]]
// Explanation may include argument %1 as the player role and %2 as the weapon description

GR_WeaponsPermission =
{
	params ["_permissions"];

	private _violations = [];

	private _roleDescription = [roleDescription player] call SPM_Util_CleanedRoleDescription;

	{
		_filterResult = [_x, _permissions, "CfgWeapons"] call JB_fnc_passesTypeFilter;
		if (not (_filterResult select 0)) then
		{

			_violations pushBack (format [_filterResult select 1, _roleDescription, [_x, "CfgWeapons"] call JB_fnc_displayName]);
			player removeWeapon _x;
			if (not ([] call GR_IsConfiguringGear)) then { [_x] call GR_DropGear };
		}
	} forEach weapons player;

	_violations
};

GR_UAVRestriction =
{
	private _p = objNull;
	private _violations = [];

	private _gear = assignedItems player;

	{
		_p = _x;
		{
			if ([_x, _p] call GR_Name_Matches_Pattern) then
			{
				_violations pushBack (format [UAV_RESTRICTION_MSG, [_x, "CfgVehicles"] call JB_fnc_displayName]);
				player unassignItem _x;
				player removeItem _x;
				if (not ([] call GR_IsConfiguringGear)) then { [_x] call GR_DropGear };
			}
		} foreach _gear;
	} foreach GR_UAVOperatorRestrictions;

	_violations
};

GR_ThermalOpticsRestriction =
{
	private _p = objNull;
	private _violations = [];

	private _weaponOptics = primaryWeaponItems player;
	private _weapon = primaryWeapon player;
	private _headgear = headgear player;

	{
		_p = _x;

		{
			if ([_x, _p] call GR_Name_Matches_Pattern) then
			{
				_violations pushBack (format [THERMAL_OPTICS_MSG, [_x, "CfgWeapons"] call JB_fnc_displayName]);
				player removePrimaryWeaponItem  _x;
				if (not ([] call GR_IsConfiguringGear)) then { [_x] call GR_DropGear };
			}
		} foreach _weaponOptics;

		if ([_weapon, _p] call GR_Name_Matches_Pattern) then
		{
			_violations pushBack (format [THERMAL_OPTICS_MSG, [_x, "CfgWeapons"] call JB_fnc_displayName]);
			player removeWeapon _weapon;
			if (not ([] call GR_IsConfiguringGear)) then { [_weapon] call GR_DropGear };
		};

		if ([_headgear, _p] call GR_Name_Matches_Pattern) then
		{
			_violations pushBack (format [THERMAL_OPTICS_MSG, [_x, "CfgWeapons"] call JB_fnc_displayName]);
			removeHeadgear player;
			if (not ([] call GR_IsConfiguringGear)) then { [_headgear] call GR_DropGear };
		};

	} foreach GR_ThermalOpticsOperatorRestrictions;

	_violations
};

GR_SniperOpticsRestriction =
{
	private _p = objNull;
	private _violations = [];

	private _weaponOptics = primaryWeaponItems player;

	{
		_p = _x;
		{
			if ([_x, _p] call GR_Name_Matches_Pattern) then
			{
				_violations pushBack (format [SNIPER_OPTICS_MSG, [_x, "CfgWeapons"] call JB_fnc_displayName]);
				player removePrimaryWeaponItem  _x;
				if (not ([] call GR_IsConfiguringGear)) then { [_x] call GR_DropGear };
			}
		} foreach _weaponOptics;
	} foreach GR_SniperOpticsOperatorRestrictions;

	_violations
};

GR_EODGearRestriction =
{
	private _p = objNull;
	private _violations = [];

	private _backpackItems = backpackItems player;
	private _vestItems = vestItems player;
	private _uniformItems = uniformItems player;

	{
		_p = _x;
		{
			if ([_x, _p] call GR_Name_Matches_Pattern) then
			{
				_violations pushBack (format [EOD_GEAR_MSG, [_x, "CfgWeapons"] call JB_fnc_displayName]);
				player removeItemFromBackpack _x;
				if (not ([] call GR_IsConfiguringGear)) then { [_x] call GR_DropGear };
			}
		} foreach _backpackItems;
		{
			if ([_x, _p] call GR_Name_Matches_Pattern) then
			{
				_violations pushBack (format [EOD_GEAR_MSG, [_x, "CfgWeapons"] call JB_fnc_displayName]);
				player removeItemFromVest _x;
				if (not ([] call GR_IsConfiguringGear)) then { [_x] call GR_DropGear };
			}
		} foreach _vestItems;
		{
			if ([_x, _p] call GR_Name_Matches_Pattern) then
			{
				_violations pushBack (format [EOD_GEAR_MSG, [_x, "CfgWeapons"] call JB_fnc_displayName]);
				player removeItemFromUniform _x;
				if (not ([] call GR_IsConfiguringGear)) then { [_x] call GR_DropGear };
			}
		} foreach _uniformItems;
	} foreach GR_EODOperatorRestrictions;

	_violations
};

GR_JTACRestriction =
{
	private _p = objNull;
	private _violations = [];

	{
		if (_x in magazines player) then
		{
			_violations pushBack (format [JTAC_MAGAZINES_MSG, [_x, "CfgMagazines"] call JB_fnc_displayName]);
			player removeMagazines _x;
			if (not ([] call GR_IsConfiguringGear)) then { [_x] call GR_DropGear };
		};
	} foreach GR_JTACMagazineRestrictions;

	//TODO: To take out a loaded round involves using magazinesAmmoFull to identify a loaded round, then record the primary weapon's weaponAccessories,
	// then give the player a replacement weapon with the accessories and the loaded magazines apart from the offending loaded round.

	_violations
};

GR_ATCRestriction =
{
	private _violations = [];

	private _backpack = backpack player;
	if (_backpack != "") then
	{
		_violations pushBack (format [ATC_GEAR_MSG, [_backpack, "CfgVehicles"] call JB_fnc_displayName]);
		removeBackpack player;
		if (not ([] call GR_IsConfiguringGear)) then { [_backpack] call GR_DropGear };
	};

	private _vest = vest player;
	if (_vest != "") then
	{
		_violations pushBack (format [ATC_GEAR_MSG, [_vest, "CfgWeapons"] call JB_fnc_displayName]);
		removeVest player;
		if (not ([] call GR_IsConfiguringGear)) then { [_vest] call GR_DropGear };
	};

	if (primaryWeapon player != "" || secondaryWeapon player != "" || handgunWeapon player != "") then
	{
		_violations pushBack (format [ATC_GEAR_MSG, "All weapons"]);
		if (not ([] call GR_IsConfiguringGear)) then { [primaryWeapon player] call GR_DropGear; [secondaryWeapon player] call GR_DropGear; [handgunWeapon player] call GR_DropGear };
		removeAllWeapons player;
	};

	{
		if (_x != "") then
		{
			_violations pushBack (format [ATC_GEAR_MSG, [_x, "CfgWeapons"] call JB_fnc_displayName]);
			player removeHandgunItem _x;
			if (not ([] call GR_IsConfiguringGear)) then { [_x] call GR_DropGear };
		};
	} forEach handgunItems player;

	if (count uniformItems player > 0) then
	{
		_violations pushBack (format [ATC_GEAR_MSG, "Pocket items"]);
		{
			player removeItemFromUniform _x;
			if (not ([] call GR_IsConfiguringGear)) then { [_x] call GR_DropGear };
		} forEach uniformItems player;
	};

	_violations
};

GR_ProhibitedItemsRestriction =
{
	if (isNil "GR_WhitelistItems") then { GR_WhitelistItems = [] call compile preprocessFile "scripts\whitelistGear.sqf" };

	private _whitelistWeapons = GR_WhitelistItems select 0;
	private _whitelistBackpacks = GR_WhitelistItems select 1;
	private _whitelistItems = GR_WhitelistItems select 2;

	private _violations = [];

	{
		if (_x != "" && not (_x in _whitelistWeapons)) then
		{
			_violations pushBack (format [UNAVAILABLE_ITEMS_MSG, [_x, "CfgWeapons"] call JB_fnc_displayName]);
			player removeWeapon _x;
			if (not ([] call GR_IsConfiguringGear)) then { [_x] call GR_DropGear };
		}
	} foreach [primaryWeapon player, secondaryWeapon player, handgunWeapon player];

	private _backpack = backpack player;
	if (_backpack != "" && not (_backpack in _whitelistBackpacks)) then
	{
		_violations pushBack (format [UNAVAILABLE_ITEMS_MSG, [_backpack, "CfgVehicles"] call JB_fnc_displayName]);
		removeBackpack player;
		if (not ([] call GR_IsConfiguringGear)) then { [_backpack] call GR_DropGear };
	};

	private _headgear = headgear player;
	if (_headgear != "" && not (_headgear in _whitelistItems)) then
	{
		_violations pushBack (format [UNAVAILABLE_ITEMS_MSG, [_headgear, "CfgWeapons"] call JB_fnc_displayName]);
		removeHeadgear player;
		if (not ([] call GR_IsConfiguringGear)) then { [_headgear] call GR_DropGear };
	};

	private _vest = vest player;
	if (_vest != "" && not (_vest in _whitelistItems)) then
	{
		_violations pushBack (format [UNAVAILABLE_ITEMS_MSG, [_vest, "CfgWeapons"] call JB_fnc_displayName]);
		removeVest player;
		if (not ([] call GR_IsConfiguringGear)) then { [_vest] call GR_DropGear };
	};

	private _uniform = uniform player;
	if (_uniform != "" && not (_uniform in _whitelistItems)) then
	{
		_violations pushBack (format [UNAVAILABLE_ITEMS_MSG, [_uniform, "CfgWeapons"] call JB_fnc_displayName]);
		removeUniform player;
		if (not ([] call GR_IsConfiguringGear)) then { [_uniform] call GR_DropGear };
	};

	{
		if (not (_x in _whitelistItems) && { not (_x in _whitelistWeapons) } && { not isClass (configFile >> "CfgMagazines" >> _x) }) then
		{
			_violations pushBack (format [UNAVAILABLE_ITEMS_MSG, [_x] call JB_fnc_displayName]);
			player removeItemFromBackpack _x;
			if (not ([] call GR_IsConfiguringGear)) then { [_x] call GR_DropGear };
		};
	} foreach backpackItems player;

	{
		if (not (_x in _whitelistItems) && { not (_x in _whitelistWeapons) } && { not isClass (configFile >> "CfgMagazines" >> _x) }) then
		{
			_violations pushBack (format [UNAVAILABLE_ITEMS_MSG, [_x] call JB_fnc_displayName]);
			player removeItemFromVest _x;
			if (not ([] call GR_IsConfiguringGear)) then { [_x] call GR_DropGear };
		}
	} foreach vestItems player;

	{
		if (not (_x in _whitelistItems) && { not (_x in _whitelistWeapons) } && { not isClass (configFile >> "CfgMagazines" >> _x) }) then
		{
			_violations pushBack (format [UNAVAILABLE_ITEMS_MSG, [_x] call JB_fnc_displayName]);
			player removeItemFromUniform _x;
			if (not ([] call GR_IsConfiguringGear)) then { [_x] call GR_DropGear };
		}
	} foreach uniformItems player;

	{
		if (not (_x in _whitelistItems) && { not (_x in _whitelistWeapons) } && { not isClass (configFile >> "CfgMagazines" >> _x) }) then
		{
			_violations pushBack (format [UNAVAILABLE_ITEMS_MSG, [_x] call JB_fnc_displayName]);
			player unassignItem _x;
			player removeItem _x;
			if (not ([] call GR_IsConfiguringGear)) then { [_x] call GR_DropGear };
		}
	} foreach assignedItems player;

	_violations
};

params ["_restrictions"];

private _violations = [];
private _checkCounter = 60;

private _player = player;

while { alive _player } do
{
	{
		_violations = _violations + ([] call _x);
	} foreach (_restrictions + [{ [] call GR_ProhibitedItemsRestriction }]);

	if (count _violations > 0) then
	{
		private _message = _violations joinString "\n";

		titleText [_message, "BLACK"];
		sleep (1 + (count _violations));
		titleFadeOut 1;

		_violations = [];
		_checkCounter = 30; // 30 seconds of active checking of gear if the player has violated a restriction
	};

	// If arsenal or VAS is open, check gear every second
	if ([] call GR_IsConfiguringGear) then { _checkCounter = _checkCounter max 1 };

	if (_checkCounter == 0) then
	{
		sleep 10;
	}
	else
	{
		sleep 1;
		_checkCounter = _checkCounter - 1;
	};
};
