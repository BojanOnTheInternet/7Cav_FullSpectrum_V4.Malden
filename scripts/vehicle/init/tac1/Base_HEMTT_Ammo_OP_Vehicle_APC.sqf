[
	_this select 0,
	{
		(_this select 0) setAmmoCargo 0;

		private _capacity = 9780;
		private _ammo = [];
		if (isNull (_this select 1)) then
		{
			_set =
			[
				["200Rnd_762x51_Belt_T_Red", 200],
				["200Rnd_127x99_mag_Tracer_Red", 200],
				["140Rnd_30mm_MP_shells_Tracer_Red", 140],
				["60Rnd_30mm_APFSDS_shells_Tracer_Red", 60],
				["SmokeLauncherMag", 4]
			];

			private _weight = [_set] call JBA_StoresMass;
			private _copies = floor (_capacity / _weight);
			_ammo = _set apply { [_x select 0, (_x select 1) * _copies] };
		};
		[_this select 0, _capacity, [2, AmmoFilter_TransferToAny], _ammo] call JB_fnc_ammoInit;

		[_this select 0, SERVER_Magazines_TitanToMAAWS, SERVER_Weapons_LauncherDowngrade] call JB_fnc_containerSubstitute;
	}
] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 60] call JB_fnc_respawnVehicleWhenKilled;
[_this select 0, 1500] call JB_fnc_respawnVehicleWhenAbandoned;