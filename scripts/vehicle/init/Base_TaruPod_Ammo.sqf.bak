[_this select 0,
	{
		params ["_newPod", "_oldPod"];

		_newPod allowDamage false;
		(_newPod) setAmmoCargo 0;
		[_newPod, "black", []] call BIS_fnc_initVehicle;

		private _capacity = 4500;
		private _ammo = [];
		if (isNull _oldPod) then // Not a respawn
		{
			private _weight = [SERVER_Ammo_Vehicle] call JBA_StoresMass;
			private _copies = floor (_capacity / _weight);
			_ammo = SERVER_Ammo_Vehicle apply { [_x select 0, (_x select 1) * _copies] };
		};
		[_newPod, _capacity, [2, AmmoFilter_TransferToAny], _ammo] call JB_fnc_ammoInit;

		(_newPod) setVariable ["ASL_DONOTSLING", true, true];

		[_this select 0, 8.0] call JB_fnc_internalStorageInitContainer;
	}
] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 120] call JB_fnc_respawnVehicleWhenKilled;
[_this select 0, 1500] call JB_fnc_respawnVehicleWhenAbandoned;