JBFIP_InstallActions =
{
	player addAction ["<t color='#FFFF99'>Fuel vehicle</t>", { [player, cursorObject] call JBF_FuelVehicle }, nil, 10, true, true, "", "getCursorObjectParams select 2 <= 2 && { [cursorObject] call JBF_FuelVehicleCondition }"];
	player addAction ["<t color='#FFFF99'>Release fuel line</t>", { [player] call JBF_ReleaseAllFuelLines }, nil, 9, true, true, "", "[] call JBF_ReleaseAllFuelLinesCondition"];
	player addAction ["<t color='#FFFF99'>Stop fueling</t>", { [cursorObject] call JBF_StopFuelingVehicle }, nil, 10, true, true, "", "getCursorObjectParams select 2 <= 2 && { [cursorObject] call JBF_StopFuelingVehicleCondition }"];
};

[] call JBFIP_InstallActions;
player addEventHandler ["Respawn", { [] call JBFIP_InstallActions }];
