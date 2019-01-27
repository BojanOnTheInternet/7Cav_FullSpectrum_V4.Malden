[_this select 0,
  {
    _radius = 100;
    missionNamespace setVariable ["acex_fortify_locations", [[_this select 0,_radius,_radius,0,false]]];
  }
] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 120] call JB_fnc_respawnVehicleWhenKilled;
