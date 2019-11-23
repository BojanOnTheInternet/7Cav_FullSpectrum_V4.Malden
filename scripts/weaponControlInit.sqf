waituntil {!isnull (finddisplay 46)};

(findDisplay 46) displayAddEventHandler ["KeyDown",
	{
		params ["_display", "_key", "_isShift", "_isCtrl", "_isAlt"];

		private _handled = false;

		if (vehicle player != player) then
		{
			private _index = -1;
			switch (true) do
			{
				case (inputAction "SwitchPrimary" > 0): { _index = 0 };
				case (inputAction "SwitchHandgun" > 0): { _index = 1 };
				case (inputAction "SwitchSecondary" > 0): { _index = 2 };
				case (inputAction "SwitchWeaponGrp1" > 0): { _index = 3 };
				case (inputAction "SwitchWeaponGrp2" > 0): { _index = 4 };
				case (inputAction "SwitchWeaponGrp3" > 0): { _index = 5 };
				case (inputAction "SwitchWeaponGrp4" > 0): { _index = 6 };
			};

			if (_index >= 0) then
			{
				private _weapons = [vehicle player] call JB_fnc_weaponControlGetWeapons;
				if (_index < count _weapons) then
				{
					private _message = [vehicle player, _weapons select _index select 0, _weapons select _index select 1, not (_weapons select _index select 2)] call JB_fnc_weaponControlEnableWeapon;
					if (_message != "") then { titleText [_message, "plain down", 0.3] };
					_handled = true;
				};
			};
		};

		_handled;
	}];
