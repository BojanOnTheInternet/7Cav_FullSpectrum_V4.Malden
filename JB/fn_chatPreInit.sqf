// Thanks to Conroy from Armaholic for the basic technique

#include "\a3\editor_f\Data\Scripts\dikCodes.h"

JB_CHAT_KeyDownHandler =
{
	params ["_control", "_keyCode", "_control", "_shift", "_alt"];

	if (_keyCode in [DIK_RETURN, DIK_NUMPADENTER]) then
	{
		JB_CHAT_Message = [ctrlText (findDisplay 63 displayCtrl 101), ctrlText (findDisplay 24 displayCtrl 101)];
	};

	false;
};

JB_CHAT_MonitorChat =
{
	_this spawn
	{
		scriptName "JB_CHAT_MonitorChat";

		while { not isNil "JB_CHAT_Handlers" } do
		{
			JB_CHAT_Message = [];

			waitUntil { not isNull (findDisplay 24 displayCtrl 101) };

			(findDisplay 24) displayAddEventHandler ["KeyDown", JB_CHAT_KeyDownHandler];

			waitUntil { isNull (findDisplay 24 displayCtrl 101) };

			if (count JB_CHAT_Message > 0) then
			{
				{
					JB_CHAT_Message call _x;
				} forEach JB_CHAT_Handlers;
			};

			sleep 0.1;
		};
	};
};
