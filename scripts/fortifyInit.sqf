/*
Author: Bojan

Initialize the ACEX Fortify plugin, sets the fortify items, budgets, and
ensures only Apollo units are able to build, even if somebody else gets a fortify
tool.

We will also require that players be near the FOB
truck (init any vic with scripts/vehicles/init/Base_FOB.sqf).
*/

_items = [
  ["Land_HBarrier_1_F", 2],
  ["Land_HBarrier_5_F", 10],
  ["Land_HBarrierWall4_F", 10],
  ["Land_HBarrierWall_corner_F", 10],
  ["Land_HBarrierTower_F", 50],
  ["Land_BagFence_Long_F", 5],
  ["Land_BarGate_F", 50],
  ["Land_BagBunker_Small_F", 25],
  ["Land_BagBunker_Large_F", 50],
  ["Land_PortableLight_double_F", 5],
  ["PortableHelipadLight_01_red_F", 1]
];
[west, 300, _items] call acex_fortify_fnc_registerObjects;

// in scripts/vehicles/init/Base_FOB.sqf we set the vehicle location + radius condition

// Here we add checks to really ensure only Apollo units are building,
// and they aren't building in the green zone
[{
  params ["_unit", "_side", "_object"];
  _apollo_units = ["rhsusf_army_ocp_jfo"];
  _return = true;

  // Check if Apollo
  if(!(typeOf _unit in _apollo_units)) then {
    _return = false;
    ["You must be an Apollo unit to fortify.", 3] call JB_fnc_showBlackScreenMessage;
  };

  // Check if in base
  if(_unit inArea headquarters) then {
    _return = false;
    ["You may not fortify on base.", 3] call JB_fnc_showBlackScreenMessage;
  };
  _return;
}] call acex_fortify_fnc_addDeployHandler;
