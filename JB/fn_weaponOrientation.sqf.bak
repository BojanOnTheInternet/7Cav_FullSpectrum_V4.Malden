params ["_unit"];

if (currentWeapon player != secondaryWeapon player) exitWith { [[0,0,0], [0,1,0], [1,0,0], [0,0,1]] };

private _torsoUp = vectorNormalized ((_unit selectionPosition "neck") vectorDiff (_unit selectionPosition "pelvis"));
private _torsoForward = [0,1,0];
private _torsoRight = vectorNormalized (_torsoForward vectorCrossProduct _torsoUp);

private _weaponForward = (_unit weaponDirection currentWeapon _unit);
private _weaponRight = vectorNormalized [-(_weaponForward select 1), _weaponForward select 0, 0];
private _weaponUp = _weaponForward vectorCrossProduct _weaponRight;

private _weaponPosition = (_unit selectionPosition "neck") vectorAdd (_torsoRight vectorMultiply 0.165) vectorAdd (_torsoUp vectorMultiply -0.05);

[_unit modelToWorld _weaponPosition, _weaponForward, _weaponRight, _weaponUp];