#include "\a3\editor_f\Data\Scripts\dikCodes.h"

waitUntil { not isNull (findDisplay 46) };

JB_EP_Fitted = false;

JB_EP_ToggleEarplugs =
{
	if (JB_EP_Fitted) then
	{
		JB_EP_Fitted = false;
		["earplugs", 1.0, 2.0] call JB_fnc_hearingSetLevel;
		titleText ["Earplugs removed", "plain down", 0.2];
	}
	else
	{
		JB_EP_Fitted = true;
		["earplugs", 0.2, 2.0] call JB_fnc_hearingSetLevel;
		titleText ["Earplugs inserted", "plain down", 0.2];
	};
};

JB_EP_ToggleEarplugsCondition =
{
	private _actions = player getVariable "JB_EP_Actions";
	player setUserActionText [_actions select 0, if (JB_EP_Fitted) then { "Remove earplugs" } else { "Insert earplugs" }];

	true
};

JB_EP_AddActions =
{
	private _action = player addAction ["", { [] call JB_EP_ToggleEarplugs }, nil, 0, false, true, "", '[] call JB_EP_ToggleEarplugsCondition'];
	player setVariable ["JB_EP_Actions", [_action]];
};

(findDisplay 46) displayAddEventHandler ["KeyDown",
	{
		params ["_display", "_key", "_isShift", "_isCtrl", "_isAlt"];

		private _override = false;

		if (_key == DIK_PAUSE) then // Pause/Break
		{
			call JB_EP_ToggleEarplugs;
			_override = true;
		};

		_override
	}];

call JB_EP_AddActions;
player addEventHandler ["Respawn", { call JB_EP_AddActions }];