[player] call JBM_SetupActions;
player addEventHandler ["HandleDamage", JBM_HandleDamage];
player addEventHandler ["Respawn", JBM_Respawned];
player addEventHandler ["Killed", JBM_Killed];

addMissionEventHandler ["Draw3D", { JBM_FrameNumber = JBM_FrameNumber + 1 }];