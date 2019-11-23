#include "\a3\editor_f\Data\Scripts\dikCodes.h"

JB_CE_LIVE_UPDATE_INTERVAL = 0.5;

JB_CE_DISPLAY = 3400;

JB_CE_CONTROL_CONTAINERTITLE = 1005;
JB_CE_CONTROL_OK = 1201;
JB_CE_CONTROL_CANCEL = 1202;
JB_CE_CONTROL_ALLITEMS = 1203;
JB_CE_CONTROL_CONTAINERITEMS = 1204;
JB_CE_CONTROL_CONTAINERFILL = 1205;
JB_CE_CONTROL_CATEGORYBASE = 1301;

JB_CE_ITEM_DISPLAYNAME = 0;
JB_CE_ITEM_PICTURE = 1;
JB_CE_ITEM_CLASS = 2;
JB_CE_ITEM_COUNT = 3;
JB_CE_ITEM_MASS = 4;
JB_CE_ITEM_CARGOTYPE = 5; // addWeaponCargoGlobal, addMagazineCargoGlobal, addItemCargoGlobal, addBackpackCargoGlobal

JB_CE_CS = call JB_fnc_criticalSectionCreate;

JB_CE_GearAllDefine =
{
	if (not isNil "JB_CE_GearCategories") exitWith {};

	private _gear = [] call CLIENT_fnc_arsenalGear;
	private _weapons = _gear select 0;
	private _backpacks = _gear select 1;
	private _items = _gear select 2;
	private _glasses = _gear select 3;

	private _binoculars = _weapons select { getNumber (configFile >> "CfgWeapons" >> _x >> "useAsBinocular") == 1 };
	_weapons = _weapons - _binoculars;

	private _magazinesWeapons = [_weapons] call CLIENT_fnc_whitelistMagazines;
	_magazinesWeapons = _magazinesWeapons apply { [ getText (configFile >> "CfgMagazines" >> _x >> "displayName"), getText (configFile >> "CfgMagazines" >> _x >> "picture"), _x, 0, getNumber (configFile >> "CfgMagazines" >> _x >> "mass")]};
	_magazinesWeapons sort true;

	private _magazinesThrown = [["Throw"]] call CLIENT_fnc_whitelistMagazines;
	_magazinesThrown = _magazinesThrown apply { [ getText (configFile >> "CfgMagazines" >> _x >> "displayName"), getText (configFile >> "CfgMagazines" >> _x >> "picture"), _x, 0, getNumber (configFile >> "CfgMagazines" >> _x >> "mass")]};
	_magazinesThrown sort true;

	private _magazinesPut = [["Put"]] call CLIENT_fnc_whitelistMagazines;
	_magazinesPut = _magazinesPut apply { [ getText (configFile >> "CfgMagazines" >> _x >> "displayName"), getText (configFile >> "CfgMagazines" >> _x >> "picture"), _x, 0, getNumber (configFile >> "CfgMagazines" >> _x >> "mass")]};
	_magazinesPut sort true;

	private _rifles = _weapons select { _x isKindOf ["Rifle_Base_F", configFile >> "CfgWeapons"] };
	_rifles = _rifles apply { [ getText (configFile >> "CfgWeapons" >> _x >> "displayName"), getText (configFile >> "CfgWeapons" >> _x >> "picture"), _x, 0, getNumber (configFile >> "CfgWeapons" >> _x >> "WeaponSlotsInfo" >> "mass")]};
	_rifles sort true;

	private _pistols = _weapons select { _x isKindOf ["Pistol_Base_F", configFile >> "CfgWeapons"] };
	_pistols = _pistols apply { [ getText (configFile >> "CfgWeapons" >> _x >> "displayName"), getText (configFile >> "CfgWeapons" >> _x >> "picture"), _x, 0, getNumber (configFile >> "CfgWeapons" >> _x >> "WeaponSlotsInfo" >> "mass")]};
	_pistols sort true;

	private _launchers = _weapons select { _x isKindOf ["Launcher_Base_F", configFile >> "CfgWeapons"] };
	_launchers = _launchers apply { [ getText (configFile >> "CfgWeapons" >> _x >> "displayName"), getText (configFile >> "CfgWeapons" >> _x >> "picture"), _x, 0, getNumber (configFile >> "CfgWeapons" >> _x >> "WeaponSlotsInfo" >> "mass")]};
	_launchers sort true;

	_binoculars = _binoculars apply { [ getText (configFile >> "CfgWeapons" >> _x >> "displayName"), getText (configFile >> "CfgWeapons" >> _x >> "picture"), _x, 0, getNumber (configFile >> "CfgWeapons" >> _x >> "WeaponSlotsInfo" >> "mass")]};
	_binoculars sort true;

	_backpacks = _backpacks apply { [ getText (configFile >> "CfgVehicles" >> _x >> "displayName"), getText (configFile >> "CfgVehicles" >> _x >> "picture"), _x, 0, getNumber (configFile >> "CfgVehicles" >> _x >> "mass")]};
	_backpacks sort true;

	private _uniforms = _items select { _x isKindOf ["Uniform_Base", configFile >> "CfgWeapons"] };
	_items = _items - _uniforms;
	_uniforms = _uniforms apply { [ getText (configFile >> "CfgWeapons" >> _x >> "displayName"), getText (configFile >> "CfgWeapons" >> _x >> "picture"), _x, 0, getNumber (configFile >> "CfgWeapons" >> _x >> "ItemInfo" >> "mass")]};
	_uniforms sort true;

	private _vests = _items select { _x isKindOf ["Vest_Camo_Base", configFile >> "CfgWeapons"] || { _x isKindOf ["Vest_NoCamo_Base", configFile >> "CfgWeapons"] } };
	_items = _items - _vests;
	_vests = _vests apply { [ getText (configFile >> "CfgWeapons" >> _x >> "displayName"), getText (configFile >> "CfgWeapons" >> _x >> "picture"), _x, 0, getNumber (configFile >> "CfgWeapons" >> _x >> "ItemInfo" >> "mass")]};
	_vests sort true;

	private _headgear = _items select { _x isKindOf ["HelmetBase", configFile >> "CfgWeapons"] || { _x isKindOf ["H_HelmetB", configFile >> "CfgWeapons"] } };
	_items = _items - _headgear;
	_headgear = _headgear apply { [ getText (configFile >> "CfgWeapons" >> _x >> "displayName"), getText (configFile >> "CfgWeapons" >> _x >> "picture"), _x, 0, getNumber (configFile >> "CfgWeapons" >> _x >> "ItemInfo" >> "mass")]};
	_headgear sort true;

	private _accessories = _items select { _x find "acc_" == 0 };
	_items = _items - _accessories;
	_accessories = _accessories apply { [ getText (configFile >> "CfgWeapons" >> _x >> "displayName"), getText (configFile >> "CfgWeapons" >> _x >> "picture"), _x, 0, getNumber (configFile >> "CfgWeapons" >> _x >> "ItemInfo" >> "mass")]};
	_accessories sort true;

	private _optics = _items select { _x find "optic_" == 0 };
	_items = _items - _optics;
	_optics = _optics apply { [ getText (configFile >> "CfgWeapons" >> _x >> "displayName"), getText (configFile >> "CfgWeapons" >> _x >> "picture"), _x, 0, getNumber (configFile >> "CfgWeapons" >> _x >> "ItemInfo" >> "mass")]};
	_optics sort true;

	private _muzzles = _items select { _x find "muzzle_" == 0 };
	_items = _items - _muzzles;
	_muzzles = _muzzles apply { [ getText (configFile >> "CfgWeapons" >> _x >> "displayName"), getText (configFile >> "CfgWeapons" >> _x >> "picture"), _x, 0, getNumber (configFile >> "CfgWeapons" >> _x >> "ItemInfo" >> "mass")]};
	_muzzles sort true;

	private _bipods = _items select { _x find "bipod_" == 0 };
	_items = _items - _bipods;
	_bipods = _bipods apply { [ getText (configFile >> "CfgWeapons" >> _x >> "displayName"), getText (configFile >> "CfgWeapons" >> _x >> "picture"), _x, 0, getNumber (configFile >> "CfgWeapons" >> _x >> "ItemInfo" >> "mass")]};
	_bipods sort true;

	_items = _items apply { [ getText (configFile >> "CfgWeapons" >> _x >> "displayName"), getText (configFile >> "CfgWeapons" >> _x >> "picture"), _x, 0, getNumber (configFile >> "CfgWeapons" >> _x >> "ItemInfo" >> "mass")]};
	_items append _binoculars;
	_items sort true;

	JB_CE_GearCategories = [];
	JB_CE_GearCategories pushBack ["primaryWeapons", JB_CE_CONTROL_CATEGORYBASE + 0 * 2, _rifles];
	JB_CE_GearCategories pushBack ["handgunWeapons", JB_CE_CONTROL_CATEGORYBASE + 1 * 2, _pistols];
	JB_CE_GearCategories pushBack ["secondaryWeapons", JB_CE_CONTROL_CATEGORYBASE + 2 * 2, _launchers];
	JB_CE_GearCategories pushBack ["uniforms", JB_CE_CONTROL_CATEGORYBASE + 3 * 2, _uniforms];
	JB_CE_GearCategories pushBack ["backpacks", JB_CE_CONTROL_CATEGORYBASE + 4 * 2, _backpacks];
	JB_CE_GearCategories pushBack ["vests", JB_CE_CONTROL_CATEGORYBASE + 5 * 2, _vests];
	JB_CE_GearCategories pushBack ["headgear", JB_CE_CONTROL_CATEGORYBASE + 6 * 2, _headgear];

	JB_CE_GearCategories pushBack ["magazinesCurrent", JB_CE_CONTROL_CATEGORYBASE + 7 * 2, []];
	JB_CE_GearCategories pushBack ["magazinesWeapons", JB_CE_CONTROL_CATEGORYBASE + 8 * 2, _magazinesWeapons];
	JB_CE_GearCategories pushBack ["magazinesThrown", JB_CE_CONTROL_CATEGORYBASE + 9 * 2, _magazinesThrown];
	JB_CE_GearCategories pushBack ["magazinesPut", JB_CE_CONTROL_CATEGORYBASE + 10 * 2, _magazinesPut];
	JB_CE_GearCategories pushBack ["attachments", JB_CE_CONTROL_CATEGORYBASE + 11 * 2, _accessories + _optics + _muzzles + _bipods];
	JB_CE_GearCategories pushBack ["miscellaneous", JB_CE_CONTROL_CATEGORYBASE + 12 * 2, _items];

	// Container-style categories
	JB_CE_GearCategories pushBack ["weapons", -1, _rifles + _pistols + _launchers + _binoculars];
	JB_CE_GearCategories pushBack ["magazines", -1, _magazinesWeapons + _magazinesThrown + _magazinesPut];
	JB_CE_GearCategories pushBack ["items", -1, _uniforms + _vests + _headgear + _accessories + _optics + _muzzles + _bipods + (_items - _binoculars)];

	{ _x set [JB_CE_ITEM_CARGOTYPE, "weapon"] } forEach ((["weapons"] call JB_CE_GearAllGetCategory) select 2);
	{ _x set [JB_CE_ITEM_CARGOTYPE, "magazine"] } forEach ((["magazines"] call JB_CE_GearAllGetCategory) select 2);
	{ _x set [JB_CE_ITEM_CARGOTYPE, "item"] } forEach ((["items"] call JB_CE_GearAllGetCategory) select 2);
	{ _x set [JB_CE_ITEM_CARGOTYPE, "backpack"] } forEach ((["backpacks"] call JB_CE_GearAllGetCategory) select 2);
};

JB_CE_GearControlUpdateItemCount =
{
	params ["_control", "_item", "_index"];

	private _count = if (_item select JB_CE_ITEM_COUNT == 0) then { "" } else { str (_item select JB_CE_ITEM_COUNT) };
	_control lnbSetText [[_index, 3], _count];
};

JB_CE_GearControlAddItem =
{
	params ["_control", "_item"];

	private _count = if (_item select JB_CE_ITEM_COUNT == 0) then { "" } else { str (_item select JB_CE_ITEM_COUNT) };
	_control lnbAddRow ["-", "", _item select JB_CE_ITEM_DISPLAYNAME, _count, "+", ""];
	_control lnbSetPicture [[((lnbSize _control) select 0) - 1, 1], _item select JB_CE_ITEM_PICTURE];
};

// Update the counts of the item wherever it is displayed
JB_CE_GearShowUpdateItem =
{
	params ["_item"];

	private _index = JB_CE_GearContainerItems findIf { _x select 2 == _item select JB_CE_ITEM_CLASS };
	if (_index != -1) then { [(findDisplay JB_CE_DISPLAY) displayCtrl JB_CE_CONTROL_CONTAINERITEMS, _item, _index] call JB_CE_GearControlUpdateItemCount };

	private _index = (JB_CE_GearAllCurrentCategory select 2) findIf { _x select 2 == _item select JB_CE_ITEM_CLASS };
	[(findDisplay JB_CE_DISPLAY) displayCtrl JB_CE_CONTROL_ALLITEMS, _item, _index] call JB_CE_GearControlUpdateItemCount;
};

JB_CE_GearContainerAddItem =
{
	params ["_item"];

	[(findDisplay JB_CE_DISPLAY) displayCtrl JB_CE_CONTROL_CONTAINERITEMS, _item] call JB_CE_GearControlAddItem;
	JB_CE_GearContainerItems pushBack _item;
};

JB_CE_GearContainerRemoveItem =
{
	params ["_item"];

	private _index = JB_CE_GearContainerItems findIf { _x select 2 == _item select JB_CE_ITEM_CLASS };
	if (_index != -1) then
	{
		((findDisplay JB_CE_DISPLAY) displayCtrl JB_CE_CONTROL_CONTAINERITEMS) lnbDeleteRow _index;
		JB_CE_GearContainerItems deleteAt _index;
	};
};

JB_CE_GearShowUpdateFill =
{
	private _fill = (JB_CE_GearContainer select 1) / (JB_CE_GearContainer select 2);
	findDisplay JB_CE_DISPLAY displayCtrl JB_CE_CONTROL_CONTAINERFILL progressSetPosition _fill;
};

JB_CE_GearItemSetCount =
{
	params ["_item", "_newCount", "_displayOnly"];

	private _oldCount = _item select JB_CE_ITEM_COUNT;

	if (_oldCount == _newCount) exitWith {};

	private _oldMass = _oldCount * (_item select JB_CE_ITEM_MASS);
	private _newMass = _newCount * (_item select JB_CE_ITEM_MASS);

	if (_newMass - _oldMass + (JB_CE_GearContainer select 1) > JB_CE_GearContainer select 2) exitWith {};

	switch (true) do
	{
		case (_oldCount == 0):
		{
			[_item] call JB_CE_GearContainerAddItem;
		};
		case (_newCount == 0):
		{
			[_item] call JB_CE_GearContainerRemoveItem;
		};
	};

	_item set [JB_CE_ITEM_COUNT, _newCount];

	if (not _displayOnly) then
	{
		private _container = (JB_CE_GearContainer select 0);
		switch (_item select JB_CE_ITEM_CARGOTYPE) do
		{
			case "weapon":
			{
				private _cargo = getWeaponCargo _container;
				private _index = (_cargo select 0) find (_item select JB_CE_ITEM_CLASS);
				private _count = if (_index == -1) then { 0 } else { _cargo select 1 select _index };
				if (_newCount > _count) then
				{
					_container addWeaponCargoGlobal [_item select JB_CE_ITEM_CLASS, _newCount - _count];
				}
				else
				{
					clearWeaponCargoGlobal _container;
					private _items = ["weapons"] call JB_CE_GearAllGetCategoryItems;
					{ _container addWeaponCargoGlobal [_x select JB_CE_ITEM_CLASS, _x select JB_CE_ITEM_COUNT] } forEach _items;
				};
			};
			case "magazine":
			{
				private _cargo = getMagazineCargo _container;
				private _index = (_cargo select 0) find (_item select JB_CE_ITEM_CLASS);
				private _count = if (_index == -1) then { 0 } else { _cargo select 1 select _index };
				if (_newCount > _count) then
				{
					_container addMagazineCargoGlobal [_item select JB_CE_ITEM_CLASS, _newCount - _count];
				}
				else
				{
					clearMagazineCargoGlobal _container;
					private _items = ["magazines"] call JB_CE_GearAllGetCategoryItems;
					{ _container addMagazineCargoGlobal [_x select JB_CE_ITEM_CLASS, _x select JB_CE_ITEM_COUNT] } forEach _items;
				};
			};
			case "item":
			{
				private _cargo = getItemCargo _container;
				private _index = (_cargo select 0) find (_item select JB_CE_ITEM_CLASS);
				private _count = if (_index == -1) then { 0 } else { _cargo select 1 select _index };
				if (_newCount > _count) then
				{
					_container addItemCargoGlobal [_item select JB_CE_ITEM_CLASS, _newCount - _count];
				}
				else
				{
					clearItemCargoGlobal _container;
					private _items = ["items"] call JB_CE_GearAllGetCategoryItems;
					{ _container addItemCargoGlobal [_x select JB_CE_ITEM_CLASS, _x select JB_CE_ITEM_COUNT] } forEach _items;
				};
			};
			case "backpack":
			{
				private _cargo = getBackpackCargo _container;
				private _index = (_cargo select 0) find (_item select JB_CE_ITEM_CLASS);
				private _count = if (_index == -1) then { 0 } else { _cargo select 1 select _index };
				if (_newCount > _count) then
				{
					_container addBackpackCargoGlobal [_item select JB_CE_ITEM_CLASS, _newCount - _count];
				}
				else
				{
					clearBackpackCargoGlobal _container;
					private _items = ["backpacks"] call JB_CE_GearAllGetCategoryItems;
					{ _container addBackpackCargoGlobal [_x select JB_CE_ITEM_CLASS, _x select JB_CE_ITEM_COUNT] } forEach _items;
				};
			};
		};
	};

	private _totalMass = JB_CE_GearContainer select 1;
	JB_CE_GearContainer set [1, _totalMass - _oldMass + _newMass];

	[_item] call JB_CE_GearShowUpdateItem;

	[] call JB_CE_GearShowUpdateFill;
};

JB_CE_GearItemIncrementCount =
{
	params ["_item", "_increment"];

	private _count = _item select JB_CE_ITEM_COUNT;
	_count = (_count + _increment) max 0;

	[_item, _count, false] call JB_CE_GearItemSetCount;
};

JB_CE_GearAllGetCategoryItems =
{
	params ["_categoryID"];

	([_categoryID] call JB_CE_GearAllGetCategory) select 2
};

JB_CE_GearAllGetCategoryIndex =
{
	params ["_categoryName"];

	JB_CE_GearCategories findIf { _x select 0 == _categoryName }
};

JB_CE_GearAllGetCategory =
{
	params ["_categoryID"];

	if (_categoryID isEqualType 0) exitWith { JB_CE_GearCategories select _categoryID };

	JB_CE_GearCategories select ([_categoryID] call JB_CE_GearAllGetCategoryIndex);
};

JB_CE_GearShowGear =
{
	params ["_control", "_items"];

	lnbClear _control;
	{
		[_control, _x] call JB_CE_GearControlAddItem;
	} forEach _items;
};

JB_CE_GearShowAll =
{
	params ["_category"];

	if ((_category select 0) != JB_CE_GearAllCurrentCategory select 0) then
	{
		private _picture = findDisplay JB_CE_DISPLAY displayCtrl (JB_CE_GearAllCurrentCategory select 1);
		_picture ctrlSetFade 0.5;
		_picture ctrlCommit 0.2;

		JB_CE_GearAllCurrentCategory = _category;

		private _picture = findDisplay JB_CE_DISPLAY displayCtrl (JB_CE_GearAllCurrentCategory select 1);
		_picture ctrlSetFade 0.0;
		_picture ctrlCommit 0.2;
	};

	if (JB_CE_GearAllCurrentCategory select 0 == "magazinesCurrent") then
	{
		private _weapons = weapons player;

		_weapons append ((["primaryWeapons"] call JB_CE_GearAllGetCategoryItems) select { _x select 3 > 0 } apply { _x select 2 });
		_weapons append ((["handgunWeapons"] call JB_CE_GearAllGetCategoryItems) select { _x select 3 > 0 } apply { _x select 2 });
		_weapons append ((["secondaryWeapons"] call JB_CE_GearAllGetCategoryItems) select { _x select 3 > 0 } apply { _x select 2 });

		private _magazines = [];
		{
			_magazines append getArray (configFile >> "CfgWeapons" >> _x >> "magazines");
		} forEach _weapons;

		private _items = [];
		{
			if ((_x select 2) in _magazines) then { _items pushBack _x };
		} forEach (["magazinesWeapons"] call JB_CE_GearAllGetCategoryItems);

		private _category = ["magazinesCurrent"] call JB_CE_GearAllGetCategory;
		_category set [2, _items];
	};

	[findDisplay JB_CE_DISPLAY displayCtrl JB_CE_CONTROL_ALLITEMS, JB_CE_GearAllCurrentCategory select 2] call JB_CE_GearShowGear
};

JB_CE_GearShowContainer =
{
	params ["_control", "_category"];

	[_control, JB_CE_GearContainerItems] call JB_CE_GearShowGear
};

// Set the counts of the items in JB_CE_GetAll from the container's items
JB_CE_GearAllLoad =
{
	params ["_container"];

	private _index = 0;

	private _loadItems =
	{
		params ["_items", "_classes", "_counts"];

		for "_i" from 0 to count _classes - 1 do
		{
			_index = _items findIf { _x select 2 == _classes select _i };
			if (_index >= 0 && { _counts select _i != _items select _index select 3 }) then { [_items select _index, _counts select _i, true] call JB_CE_GearItemSetCount };
		};
	};

	private _weapons = (["weapons"] call JB_CE_GearAllGetCategoryItems);
	private _cargo = getWeaponCargo _container;
	[_weapons, _cargo select 0, _cargo select 1] call _loadItems;

	private _magazines = (["magazines"] call JB_CE_GearAllGetCategoryItems);
	private _cargo = getMagazineCargo _container;
	[_magazines, _cargo select 0, _cargo select 1] call _loadItems;

	private _items = (["items"] call JB_CE_GearAllGetCategoryItems);
	private _cargo = getItemCargo _container;
	[_items, _cargo select 0, _cargo select 1] call _loadItems;

	private _backpacks = ["backpacks"] call JB_CE_GearAllGetCategoryItems;
	private _cargo = getBackpackCargo _container;
	[_backpacks, _cargo select 0, _cargo select 1] call _loadItems;

	[] call JB_CE_GearShowUpdateFill;
};

JB_CE_GearKeyDown =
{
	params ["_control", "_key", "_shift", "_ctrl", "_alt", "_gear"];

	private _index = lnbCurSelRow _control;
	if (_index == -1) exitWith { false };

	private _item = _gear select _index;

	private _override = false;

	private _increment = 0;

	switch (_key) do
	{
		case DIK_INSERT: { _increment = if (_shift) then { 10 } else { 1 } };
		case DIK_DELETE: { _increment = if (_shift) then { -10 } else { -1 } };
	};

	if (_increment != 0) then
	{
		JB_CE_CS call JB_fnc_criticalSectionEnter;

			[_item, _increment] call JB_CE_GearItemIncrementCount;

		JB_CE_CS call JB_fnc_criticalSectionLeave;

		_override = true;
	};

	_override
};

JB_CE_GearMouseButtonUp =
{
	params ["_control", "_button", "_xPos", "_yPos", "_shift", "_ctrl", "_alt", "_gear", "_count"];

	switch (_button) do
	{
		case 0:
		{
			private _index = lnbCurSelRow _control;

			if (_index == -1) exitWith {};

			private _area = ctrlPosition _control;
			private _xColumn = (_xPos - (_area select 0)) / (_area select 2);
			private _columns = lnbGetColumnsPosition _control;
			private _iColumn = (_columns findIf { _x > _xColumn });

			if (_iColumn == -1) exitWith {};

			private _increment = [0, -_count, 0, 0, 0, _count] select _iColumn;
			if (_shift) then { _increment = _increment * 10 };

			private _item = _gear select _index;
			if (_increment != 0) then
			{
				JB_CE_CS call JB_fnc_criticalSectionEnter;

					[_item, _increment] call JB_CE_GearItemIncrementCount;

				JB_CE_CS call JB_fnc_criticalSectionLeave;
			};
		};

		case 1:
		{
			// Right click to move items back and forth between the two sides

			private _sizeEx = 0.03;
			private _row = (_yPos - ((ctrlPosition _control) select 1)) / _sizeEx;
			_row = floor _row;

			// Now we have the row and we can... hmmm... do nothing.  We don't know how the list has been scrolled.  _row is
			// only the number of the nth row in the display, not in the full list.
		};
	};
};

JB_CE_GearShowFadeCategories =
{
	{
		private _id = _x select 1;

		if (_id >= 0) then
		{
			private _picture = findDisplay JB_CE_DISPLAY displayCtrl _id;
			_picture ctrlSetFade 0.5;
			_picture ctrlCommit 0.0;
		};
	} forEach JB_CE_GearCategories;
};

JB_CE_ClearInventory =
{
	private _displayOnly = true;

	[JB_CE_GearContainer select 0] call JB_fnc_containerClear;
	_displayOnly = false;

	for "_i" from count JB_CE_GearContainerItems - 1 to 0 step -1 do
	{
		[JB_CE_GearContainerItems select _i, 0, _displayOnly] call JB_CE_GearItemSetCount;
	};

	[] call JB_CE_GearShowUpdateFill;
};

JB_CE_Unload =
{
	params ["_display", "_exitCode"];

	{ _x set [JB_CE_ITEM_COUNT, 0] } forEach JB_CE_GearContainerItems;

	call CLIENT_EnableActionMenu;
};

JB_CE_EditInventory =
{
	params ["_container", "_condition"];

	[] call JB_CE_GearAllDefine;

	JB_CE_GearContainer = [_container, 0, getNumber (configFile >> "CfgVehicles" >> typeOf _container >> "maximumLoad")];
	JB_CE_GearContainerItems = [];
	JB_CE_GearAllCurrentCategory = ["", 0, []];

	disableSerialization;
	private _display = (findDisplay 46) createDisplay "JB_CE_Dialog";

	waitUntil { not isNull (findDisplay JB_CE_DISPLAY) };

	call CLIENT_DisableActionMenu;

	[] call JB_CE_GearShowFadeCategories;
	[["primaryWeapons"] call JB_CE_GearAllGetCategory] call JB_CE_GearShowAll;

	_display displayCtrl JB_CE_CONTROL_CONTAINERTITLE ctrlSetText format ["Inventory of %1", (getText (configFile >> "CfgVehicles" >> typeOf _container >> "displayName"))];

	ctrlDelete (_display displayCtrl JB_CE_CONTROL_OK);
	(_display displayCtrl JB_CE_CONTROL_CANCEL) ctrlSetText "DONE";

	[_container, _condition] spawn
	{
		params ["_container", "_condition"];

		while { not isNull findDisplay JB_CE_DISPLAY && { alive _container } && { not ([_container] call JB_fnc_containerIsLocked) } && { [_container] call _condition } } do
		{
			JB_CE_CS call JB_fnc_criticalSectionEnter;

				[JB_CE_GearContainer select 0] call JB_CE_GearAllLoad;

			JB_CE_CS call JB_fnc_criticalSectionLeave;

			sleep JB_CE_LIVE_UPDATE_INTERVAL;
		};

		if (not isNull findDisplay JB_CE_DISPLAY) then { findDisplay JB_CE_DISPLAY closeDisplay 2 };
	};

	_display displayCtrl JB_CE_CONTROL_CONTAINERITEMS lnbSetCurSelRow 0;
	_display displayCtrl JB_CE_CONTROL_ALLITEMS lnbSetCurSelRow 0;

	ctrlSetFocus (_display displayCtrl JB_CE_CONTROL_ALLITEMS);
};