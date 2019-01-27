if (not hasInterface) exitWith {};

JB_IS_InstallActions =
{
	JB_IS_LoadAction = player addAction ["", { call JB_IS_Load }, nil, 10, true, true, "", "[] call JB_IS_LoadCondition"];
	JB_IS_UnloadAction = player addAction ["", { call JB_IS_Unload }, nil, 10, false, true, "", "[] call JB_IS_UnloadCondition"];
};

[] call JB_IS_InstallActions;

player addEventHandler ["Respawn", { [] call JB_IS_InstallActions }];

