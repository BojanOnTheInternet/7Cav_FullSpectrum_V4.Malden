if (not hasInterface) exitWith {};

JB_IS_InstallActions =
{
	JB_IS_LoadAction = player addAction ["", { [cursorObject] call JB_IS_Load }, nil, 5, true, true, "", "getCursorObjectParams select 2 <= 2 && { [cursorObject] call JB_IS_LoadCondition }"];
	JB_IS_UnloadAction = player addAction ["", { [cursorObject] call JB_IS_Unload }, nil, 5, false, true, "", "getCursorObjectParams select 2 <= 2 && { [cursorObject] call JB_IS_UnloadCondition }"];
};

[] call JB_IS_InstallActions;

player addEventHandler ["Respawn", { [] call JB_IS_InstallActions }];

