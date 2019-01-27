JBAP_AddActions =
{
	player addAction ["<t color='#FFFF99'>Transfer ammo</t>", { [cursorTarget] call JBA_ShowAmmoList }, nil, 10, false, true, "", "[] call JBA_ShowAmmoListCondition"];
};

[] call JBAP_AddActions;
player addEventHandler ["Respawn", JBAP_AddActions];

[] call JB_fnc_containerInitPlayer; // Turn on container locking because we're going to lock the ammo boxes