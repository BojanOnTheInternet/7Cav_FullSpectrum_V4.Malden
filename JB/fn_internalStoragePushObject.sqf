params ["_container", "_object"];

private _objectType = if (_object isEqualType []) then { _object select 0 } else { typeOf _object };
if (not ([_container, _objectType] call JB_IS_ContainerCanStoreObjectType)) exitWith { };

if (hasInterface) exitWith
{
	[_container, _object] remoteExec ["JB_IS_S_PushObject", 2];
};

[_container, _object] call JB_IS_S_PushObject;
