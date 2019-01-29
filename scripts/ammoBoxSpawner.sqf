/*
Description: Adds ACE interaction options to an object, allowing players to spawn empty ammo boxes on a given marker.
Usage: In editor, add the following to the object's init:

null = [this, "MARKER_NAME", [["Small box", "Box_NATO_Ammo_F"], ["Big box", "Box_NATO_Wps_F"]]] execVM "scripts\ammoBoxSpawner.sqf";

Replace MARKER_NAME with the name of a marker the boxes will spawn around. You can change the boxes available by editing
the array following the marker definition. The array has the structure of:

[["Display Name1", "Class Name1"], ["Display Name2", "Class Name2"], etc,etc,etc]
*/

if (!isServer) exitWith {};
// Get the object the spawn options will belong to
_this params ["_object", "_marker", "_items"];

_spawn_box = {
  params ["_target", "_player", "_params"];
  _params params ["_class", "_marker"];

  // Spawn a box on the marker
  _crate = _class createVehicle (getMarkerPos _marker);

  // Empty the crate
  clearweaponcargoGlobal _crate;
  clearmagazinecargoGlobal _crate;
  clearitemcargoGlobal _crate;
  clearbackpackcargoGlobal _crate;
};

// Main interaction group
_action = ["BoxParent", "Spawn empty ammo box", "", {true}, {true}] call ace_interact_menu_fnc_createAction;
[_object, 0, ["ACE_MainActions"], _action] call ace_interact_menu_fnc_addActionToObject;

// Interaction option for each type of box
{
  _action = [_x select 1, _x select 0, "", _spawn_box, {true}, {}, [_x select 1, _marker]] call ace_interact_menu_fnc_createAction;
  [_object, 0, ["ACE_MainActions", "BoxParent"], _action] call ace_interact_menu_fnc_addActionToObject;
} forEach _items;
