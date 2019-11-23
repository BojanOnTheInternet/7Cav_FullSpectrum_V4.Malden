JBAP_AddActions =
{
	player addAction ["<t color='#FFFF99'>Transfer ammo</t>", { [cursorObject] call JBA_ShowAmmoList }, nil, 0, false, true, "", "getCursorObjectParams select 2 <= 2 && { [cursorObject] call JBA_ShowAmmoListCondition }"];
};

[] call JBAP_AddActions;
player addEventHandler ["Respawn", JBAP_AddActions];

[] call JB_fnc_containerInitPlayer; // Turn on container locking because we're going to lock the ammo boxes
