params ["_name", "_objectType", ["_cost", 1, [0]], ["_load", {}, [{}]], ["_loadPassthrough", []], ["_store", {}, [{}]], ["_storePassthrough", []]];

[_name, _objectType, _cost, _load, _loadPassthrough, _store, _storePassthrough] call JB_PO_CreateType
