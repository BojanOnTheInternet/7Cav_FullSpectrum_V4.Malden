[_this select 0,
	{
		(_this select 0) allowDamage false;
		(_this select 0) setFuelCargo 0;
		[_this select 0, "black", []] call BIS_fnc_initVehicle;

		private _capacity = 3000;
		[(_this select 0), [[-1.5, 1.4, -0.323], [-1.5, 1.4, 0.190]], _capacity, 60] call JB_fnc_fuelInitSupply;

		[_this select 0, _capacity] spawn
		{
			params ["_pod", "_capacity"];

			scriptName "spawnBase_TaruPod_Fuel_Level";

			private _full = 0.39;
			private _empty = -0.40;

			private _marker = "Land_Notepad_F" createVehicle [0,0,0];
			_marker attachto [_this select 0, [-1.44,1.31,_empty]];
			_marker setdir 180;

			while { sleep 1; alive _pod } do
			{
				private _fuelRemaining = _pod getVariable ["JBF_FuelRemaining", 0];
				private _z = linearConversion [_capacity, 0, _fuelRemaining, _full, _empty];
				_marker attachTo [_pod, [-1.44,1.31,_z]];
			};

			deleteVehicle _marker;
		};

		(_this select 0) setVariable ["ASL_DONOTSLING", true];
	}
] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 120] call JB_fnc_respawnVehicleWhenKilled;
[_this select 0, 1500] call JB_fnc_respawnVehicleWhenAbandoned;