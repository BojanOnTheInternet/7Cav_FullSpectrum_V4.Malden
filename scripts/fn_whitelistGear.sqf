if (not isNil "CLIENT_WhitelistGear") exitWith { CLIENT_WhitelistGear };

private _backpackClasses = "getText (_x >> ""vehicleClass"") == ""Backpacks"" && getNumber (_x >> ""scope"") >= 2 && (getText (_x >> ""faction"") in [""Default"", ""BLU_F""])" configClasses (configFile >> "CfgVehicles");

private _backpackNames = [];
{
	if (isClass _x) then
	{
		_configName = configName _x;
		if (_configName find "B_AA_01_" == -1 && { _configName find "B_AT_01_" == -1 } && { _configName find "B_GMG_01_" == -1 } && { _configName find "Bergen" == -1 }) then
		{
			_backpackNames pushBack _configName;
		};
	};
} foreach _backpackClasses;

private _configName = "";

private _itemNames = [];
private _weaponNames = [];

private _weaponClasses = "getNumber (_x >> ""scope"") >= 2" configClasses (configFile >> "CfgWeapons");

{
	if (isClass _x) then
	{
		_configName = configName _x;

		switch (true) do
		{
			// bipods
			case (_configName find "bipod_" == 0):
			{
				_itemNames pushback _configName;
			};
		
			// NATO helmets
			case (_configName isKindOf ["H_HelmetB", configFile >> "CfgWeapons"]):
			{
				private _sides = getArray (_x >> "ItemInfo" >> "modelSides");
				if (1 in _sides) then // west
				{
					_itemNames pushBack _configName;
				};
			};

			// Miscellaneous headgear
			case (_configName isKindOf ["HelmetBase", configFile >> "CfgWeapons"]):
			{
				_itemNames pushBack _configName;
			};

			// Muzzles
			case (_configName find "muzzle_snds" == 0):
			{
				_itemNames pushBack _configName;
			};

			// Night vision goggles
			case (_configName find "NVGoggles" == 0):
			{
				_itemNames pushBack _configName;
			};

			// Optics
			case (_configName find "optic_" == 0):
			{
				_itemNames pushBack _configName;
			};

			// NATO uniforms
			case (_configName find "U_B_" == 0):
			{
				if (_configName != "U_B_Protagonist_VR") then
				{
					_itemNames pushBack _configName;
				};
			};

			// Civilian clothes
			case (_configName find "U_C_" == 0):
			{
				if (_configName != "U_C_Protagonist_VR") then
				{
					_itemNames pushBack _configName;
				};
			};

			// Vests
			case (_configName find "V_" == 0):
			{
				_itemNames pushBack _configName;
			};

			// Flashlight and laser pointer
			case (_configName find "acc_" == 0):
			{
				_itemNames pushBack _configName;
			};

			// Gear without underscores; map, radio, etc
			case (_configName find "_" == -1):
			{
				if (_configName != "Zasleh2" && { getText (_x >> "model") != "" }) then
				{
					if (count getArray (_x >> "magazines") == 0 && { getNumber (_x >> "useAsBinocular") == 0 }) then
					{
						_itemNames pushBack _configName;
					}
					else
					{
						_weaponNames pushBack _configName;
					};
				};
			};

			// UAV terminals (all are allowed because the non-NATO units are used as radio proxies)
			case (_configName isKindOf ["UavTerminal_base", configFile >> "CfgWeapons"]):
			{
				_itemNames pushBack _configName;
			};
		};
	};
} foreach _weaponClasses;

{
	if (isClass _x) then
	{
		_configName = configName _x;

		// arifles and srifles
		if (_configName find "arifle_" == 0 || { _configName find "srifle_" == 0 }) then
		{
			_weaponNames pushBack _configName;
		}
		else
		{
			// LMG, MMG, SMG
			if (_configName find "LMG_" == 0 || { _configName find "MMG_" == 0 } || { _configName find "SMG_" == 0 }) then
			{
				_weaponNames pushBack _configName;
			}
			else
			{
				// hgun
				if (_configName find "hgun_" == 0) then
				{
					_weaponNames pushBack _configName;
				}
				else
				{
					// RPG and MRAWS
					if (_configName find "launch_RPG" == 0 || { _configName find "MRAWS" >= 0 && _configName find "rail" == -1 }) then
					{
						_weaponNames pushBack _configName;
					};
				};
			};
		};
	};
} foreach _weaponClasses;

private _glassesNames = [];

_glassesClasses = "getNumber (_x >> ""scope"") >= 2" configClasses (configFile >> "CfgGlasses");

{
	if (isClass _x) then
	{
		_glassesNames pushBack (configName _x);
	};
} foreach _glassesClasses;

CLIENT_WhitelistGear = [_weaponNames, _backpackNames, _itemNames, _glassesNames];

CLIENT_WhitelistGear