#include "\a3\editor_f\Data\Scripts\dikCodes.h"

params [["_fatigueEnabled", true, [true]]];

CLIENT_FatigueEnabled = _fatigueEnabled;

player addEventHandler ["Respawn", { player enableFatigue CLIENT_FatigueEnabled }];
player enableFatigue CLIENT_FatigueEnabled;

waituntil { not isNull (findDisplay 46) };

CLIENT_FatigueToggleHandler = (findDisplay 46) displayAddEventHandler ["KeyDown",
	{
		params ["_display", "_key", "_isShift", "_isCtrl", "_isAlt"];

		private _override = false;

		if (_key == DIK_SCROLL && _isShift && _isCtrl) then
		{
			CLIENT_FatigueEnabled = not CLIENT_FatigueEnabled;
			player enableFatigue CLIENT_FatigueEnabled;
			systemchat (if (CLIENT_FatigueEnabled) then { "Fatigue enabled" } else { "Fatigue disabled" });

			_override = true;
		};

		_override
	}];