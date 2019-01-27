/*
Name: SimpleSplint
Author: Bojan

Plays an animation and shows the ACE progress bar
*/
params ["_hitPoint", "_player", "_target"];

// Play animation, on success call fixLimb
_player playMove "AinvPknlMstpSlayWrflDnon_medicOther";
private _splint_time = missionNamespace getVariable ["simple_splint_time",20];

[_splint_time, [_hitPoint, _player, _target], simple_splint_fnc_fixLimb, {_player switchMove "AmovPknlMstpSrasWrflDnon"}, "Applying SAM Splint"] call ace_common_fnc_progressBar;
