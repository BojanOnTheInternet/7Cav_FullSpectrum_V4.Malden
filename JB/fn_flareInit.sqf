private _firedMan =
{
	[_this select 6] spawn
	{
		params ["_shell"];

		if (not (typeOf _shell isKindOf "FlareCore")) exitWith {};

		private _startTime = diag_tickTime;

		waitUntil { vectorMagnitude velocity _shell < 5 || not alive _shell };

		if (not alive _shell) exitWith {};

		private _shellType = typeOf _shell;

		if (netID _shell == "0:0") then
		{
			private _proxy = "Box_NATO_Ammo_F" createVehicle [random -10000, random -10000, 1000 + random 10000];
			[_proxy, true] remoteExec ["hideObjectGlobal", 2];

			[_shell, _proxy] spawn
			{
				params ["_shell", "_proxy"];
				waitUntil { _proxy setPos getPos _shell; not alive _shell };
				deleteVehicle _proxy;
			};

			_shell = _proxy;
		};

		[[_shell, _shellType, diag_tickTime - _startTime], { _this call JBFL_FlareShell }] remoteExec ["spawn", 0];
	};
};

player addEventHandler ["FiredMan", _firedMan];