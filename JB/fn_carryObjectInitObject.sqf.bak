// The object that can be carried
// The code that takes a player and returns whether or not it can carry the object
// The code that takes the object and return a kg mass value for it
params ["_object", ["_playerFilter", {true}, [{}]], ["_massCalculator", { [_this select 0] call JB_fnc_containerMass }, [{}]]];

_object setVariable ["JB_CO_Object", [_playerFilter, _massCalculator], true]; //JIP
