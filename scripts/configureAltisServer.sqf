// Basic roadway out of SpecOps
private _section = objNull;
{
	_section = createSimpleObject ["a3\roads_f\roads_new\mainroad_W10_A0_764_R1500.p3d", _x];
	_section setDir 135.247;
} forEach
[
	[15135.2,17382.2,0],
	[15121.4,17396.4,0],
	[15107.5,17410.7,0],
	[15093.7,17425.0,0],
	[15079.8,17439.2,0],
	[15067.2,17452.1,0]
];

SERVER_Weather =
[
	[[0.30, 0.50, 0.75], 0, 0.0], // January
	[[0.30, 0.50, 0.75], 0, 0.1],
	[[0.20, 0.40, 0.75], 0, 0.1],
	[[0.20, 0.20, 0.65], 0, 0.1],
	[[0.20, 0.20, 0.65], 0, 0.2],
	[[0.00, 0.20, 0.55], 0, 0.2], // June
	[[0.00, 0.10, 0.55], 0, 0.2],
	[[0.00, 0.10, 0.35], 0, 0.2],
	[[0.10, 0.20, 0.55], 0, 0.5],
	[[0.20, 0.40, 0.65], 0, 0.8],
	[[0.30, 0.50, 0.75], 0, 0.5],
	[[0.40, 0.60, 0.75], 0, 0.2]  // December
];

// Replace all ruined buildings with new ones

if ((["RestoreDestroyedBuildings"] call JB_MP_GetParamValue) == 1) then
{
	[] spawn
	{
		private _type = "";
		private _replacementType = "";
		private _replacement = objNull;
		private _replacementCount = 0;
		private _removalCount = 0;

		{
			_type = typeOf _x;

			switch (true) do
			{
				case (_type find "dam_F" >= 0);
				case (_type find "ruins_F" >= 0):
				{
					_replacementType = ((_type splitString "_") - ["dam", "ruins", "d"]) joinString "_";
					if (not isClass (configFile >> "CfgVehicles" >> _replacementType)) then
					{
						_replacementType = _replacementType splitString "_";
						_replacementType = (_replacementType select [0,1]) + ["i"] + (_replacementType select [1, 1e3]);
						_replacementType = _replacementType joinString "_";
					};
				};
				case (_type find "Land_d_" >= 0);
				case (_type find "Land_u_" >= 0):
				{
					_replacementType = (_type select [0, 5]) + "i" + (_type select [6]);
				};
				case (_type == "Land_i_Garage_V2_F"):
				{
					_replacementType = "Land_i_Garage_V1_F";
				};
				default { _replacementType = "" };
			};

			if (_replacementType == "Land_i_Addon_01_V1_F") then { _replacementType = "Land_u_Addon_01_V1_F" };

			if (_replacementType != "" && _replacementType != _type) then
			{
				if (not isClass (configFile >> "CfgVehicles" >> _replacementType)) then { systemchat format ["%1 doesn't exist (replacement for %2)", _replacementType, _type] };

				hideObjectGlobal _x;
				_replacement = createVehicle [_replacementType, call JB_MDI_RandomSpawnPosition, [], 0, "can_collide"];
				_replacement setDir (getDir _x);
				_replacement setPos (getPos _x);
				_replacement setVectorUp (vectorUp _x);
				_replacement setVariable ["MAP_Show", false, true]; // Tell clients to not show this building on the map because the map already has a building.

				_replacementCount = _replacementCount + 1;
			};
		} forEach (nearestObjects [[worldSize / 2, worldSize / 2, 0], ["House_F", "Ruins_F"], worldSize / 2]);
	};
};
/*
[] spawn
{
	// Set all the Altis fuel pumps to use our system
	{
		{
			[_x] call JB_fnc_fuelInitPump;
		} forEach nearestObjects [_x, ["Land_fs_feed_f"], 2]
	} forEach  [[14173.2, 16541.8, -0.094],
				[15297.1, 17565.9, -0.283],
				[14221.4, 18302.5, -0.069],
				[15781.0, 17453.2, -0.285],
				[12028.4, 15830.0, -0.038],
				[12026.6, 15830.1, -0.034],
				[12024.7, 15830.0, -0.029],
				[16871.7, 15476.6,  0.010],
				[16875.2, 15469.4,  0.037],
				[11831.6, 14155.9, -0.034],
				[17417.2, 13936.7, -0.106],
				[16750.9, 12513.1, -0.052],
				[9025.78, 15729.4, -0.020],
				[9023.75, 15729.0, -0.027],
				[9021.82, 15728.7, -0.029],
				[8481.69, 18260.7, -0.026],
				[20784.8, 16665.9, -0.052],
				[20789.6, 16672.3, -0.021],
				[9205.75, 12112.2, -0.048],
				[6798.15, 15561.6, -0.044],
				[19961.3, 11454.6, -0.034],
				[19965.1, 11447.6, -0.048],
				[6198.83, 15081.4, -0.091],
				[5769.00, 20085.7, -0.015],
				[5023.26, 14429.6, -0.097],
				[5019.68, 14436.7, -0.011],
				[23379.4, 19799.0, -0.054],
				[3757.54, 13485.9, -0.010],
				[3757.14, 13477.9, -0.054],
				[4001.12, 12592.1, -0.096],
				[21230.4, 7116.56, -0.060],
				[25701.2, 21372.6, -0.077]];
};*/