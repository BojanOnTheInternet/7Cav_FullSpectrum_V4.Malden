#include "\a3\editor_f\Data\Scripts\dikCodes.h"

#define FULL_THROW_TIME 2.0

waitUntil { not isNull (findDisplay 46) };

CustomThrowing_Progress =
{
	params ["_elapsedTime", "_progress", "_passthrough"];

	if (([JB_HA_STATE] call JB_fnc_holdActionGetValue) != "keyup") exitWith {};

	CustomThrowing_ThrowingScale = linearConversion [0.0, 1.0, _progress, 0.4, 1.0];

	private _throwable = currentThrowable player;
	if (count _throwable > 0) then { [player, _throwable select 1] call BIS_fnc_fire };
};

CustomThrowing_Throw =
{
	if (count currentThrowable player > 0 && count JB_HA_CurrentAction == 0) then
	{
		[actionKeys "throw", FULL_THROW_TIME, 0.1, CustomThrowing_Progress] call JB_fnc_holdActionStart;
		[JB_HA_LABEL, format ["throw %1", getText (configFile >> "CfgMagazines" >> (currentThrowable player) select 0 >> "displayNameShort")]] call JB_fnc_holdActionSetValue;
		[JB_HA_FOREGROUND_ICON, "\a3\ui_f\data\IGUI\Cfg\WeaponIcons\gl_ca.paa"] call JB_fnc_holdActionSetValue;
//		[JB_HA_FOREGROUND_ICON_SCALE, 3.4] call JB_fnc_holdActionSetValue;
	};

	true
};

CustomThrowing_Fired =
{
	if ((_this select 1) != "throw") exitWith {};

	private _object = _this select 6;
	private _velocity = (velocity _object) vectorMultiply CustomThrowing_ThrowingScale;
	_object setVelocity _velocity;
};

CustomThrowing_Enabled = false;
CustomThrowing_ThrowingScale = 0;

(findDisplay 46) displayAddEventHandler ["KeyDown",
	{
		params ["_display", "_key", "_isShift", "_isCtrl", "_isAlt"];

		private _override = false;

		if (_key == DIK_G && _isShift && _isCtrl) then // CTRL+SHIFT+G
		{
			if (CustomThrowing_Enabled) then
			{
				player removeEventHandler ["Fired", CustomThrowing_FiredHandler];
				[46, CustomThrowing_ThrowHandler] call JB_fnc_actionHandlerRemove;
				CustomThrowing_Enabled = false;
				systemchat "Mission-specific throwing system disabled";
			}
			else
			{
				CustomThrowing_ThrowHandler = [46, "Throw", CustomThrowing_Throw] call JB_fnc_actionHandlerAdd;
				CustomThrowing_FiredHandler = player addEventHandler ["Fired", CustomThrowing_Fired];
				CustomThrowing_Enabled = true;
				systemchat "Mission-specific throwing system enabled";
			};

			_override = true;
		};

		_override
	}];

player addEventHandler ["Respawn", { if (CustomThrowing_Enabled) then { CustomThrowing_FiredHandler = player addEventHandler ["Fired", CustomThrowing_Fired] }];