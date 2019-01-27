params ["_object1", "_object2"];

private _object1ToObject2 = ([_object2 worldToModel getPos _object1, boundingBoxReal _object2] call JB_fnc_distanceToBoundingBox);
private _object2ToObject1 = ([_object1 worldToModel getPos _object2, boundingBoxReal _object1] call JB_fnc_distanceToBoundingBox);

(_object1ToObject2 + _object2ToObject1) - (_object1 distance _object2)