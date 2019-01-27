/*
Name: SimpleSplint
Author: Bojan

Given a hitPoint like HitArms or HitHands, sets the hitPoint to 0.
*/
params ["_args"];
_args params ["_hitPoint", "_player", "_target"];

// Fix legs
[_target, _hitPoint,0,false] call ace_medical_fnc_setHitPointDamage;

// Remove item if enabled
private _consume_splint = missionNamespace getVariable ["simple_splint_consume_item",true];

if (_consume_splint) then {
  private _splint_item = missionNamespace getVariable ["simple_splint_consume_item_class", "ACE_personalAidKit"];
  [_player, _target, _splint_item] call ace_medical_fnc_useItem;
};

// Write to medical log
[_target, "activity", "%1 applied splint to %2", [[_player, false, true] call ace_common_fnc_getName, [_target, false, true] call ace_common_fnc_getName]] call ace_medical_fnc_addToLog;
[_target, "activity_view", "%1 applied splint to %2", [[_player, false, true] call ace_common_fnc_getName, [_target, false, true] call ace_common_fnc_getName]] call ace_medical_fnc_addToLog;

_player switchMove "AmovPknlMstpSrasWrflDnon";
